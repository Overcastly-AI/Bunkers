package com.motion.catalogjoin.sim;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.Topics;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.OffsetSpec;
import org.apache.kafka.clients.admin.TopicDescription;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.streams.StreamsConfig;

/**
 * Load simulation against a real cluster: {@code catalog-join sim-generate} and {@code catalog-join
 * sim-verify}, both driven by the same configuration (topics, attribute ids and {@code sim.*}), so
 * the generator, the app and the verifier cannot disagree.
 */
public final class Simulation {

  private static final long REPORT_EVERY_NANOS = 5_000_000_000L;
  private static final int SETTLE_POLL_MS = 5000;
  private static final int SETTLE_STABLE_CHECKS = 3;

  private Simulation() {}

  // --- generate ------------------------------------------------------------------------------------

  public static int generate(CatalogConfig config, boolean createTopics) throws Exception {
    CatalogConfig.Sim sim = config.sim();
    if (createTopics) {
      Topics.createSources(config, sim.sourcePartitions(), sim.sourceReplication());
      Topics.createOutputs(config);
    }
    Map<String, Object> props = new HashMap<>(Topics.adminClient(config));
    props.put(ProducerConfig.ACKS_CONFIG, "all");
    props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
    props.put(ProducerConfig.LINGER_MS_CONFIG, "20");
    props.put(ProducerConfig.BATCH_SIZE_CONFIG, "524288");
    props.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "lz4");

    AtomicReference<Exception> failure = new AtomicReference<>();
    long start = System.nanoTime();
    long[] sent = {0};
    long[] lastReport = {start};
    try (KafkaProducer<byte[], byte[]> producer = new KafkaProducer<>(props, new ByteArraySerializer(), new ByteArraySerializer())) {
      Generator generator = new Generator(config, new Generator.Sink() {
        @Override
        public void send(Encoder.Message m) {
          if (failure.get() != null) {
            throw new IllegalStateException("Produce failed", failure.get());
          }
          producer.send(new ProducerRecord<>(m.topic(), m.key(), m.value()), (meta, e) -> {
            if (e != null) {
              failure.compareAndSet(null, e);
            }
          });
          sent[0]++;
          long now = System.nanoTime();
          if (sim.rate() > 0) {
            long due = start + (long) (sent[0] * 1e9 / sim.rate());
            if (due > now) {
              sleepNanos(due - now);
            }
          }
          if (now - lastReport[0] > REPORT_EVERY_NANOS) {
            lastReport[0] = now;
            System.out.printf("  %,d messages, %,.0f msg/s%n", sent[0], sent[0] / ((now - start) / 1e9));
          }
        }

        @Override
        public void flush() {
          producer.flush();
        }
      });
      System.out.printf("Generating rounds %d..%d for %,d items%n", sim.fromRound(), sim.rounds(), sim.items());
      generator.run(sim.fromRound(), sim.rounds(), round -> System.out.printf("round %d done: %,d messages%n", round, sent[0]));
      if (failure.get() != null) {
        throw failure.get();
      }
      double seconds = (System.nanoTime() - start) / 1e9;
      System.out.printf("Produced %,d messages in %.1fs (%,.0f msg/s)%n", sent[0], seconds, sent[0] / seconds);
      generator.counts().forEach((table, count) -> System.out.printf("  %-28s %,d%n", table, count[0]));
    }
    return 0;
  }

  // --- verify --------------------------------------------------------------------------------------

  public static int verify(CatalogConfig config) throws Exception {
    Verifier verifier = new Verifier(config);
    List<String> sources = new ArrayList<>();
    for (SourceTable table : SourceTable.values()) {
      sources.add(config.topic(table));
    }
    String groupId = config.streamsProperties().getProperty(StreamsConfig.APPLICATION_ID_CONFIG);
    awaitSettled(config, groupId, sources, config.outputTopics(), config.sim().settleTimeoutSeconds());

    long start = System.nanoTime();
    Outputs published = new Outputs(verifier::isSampled);
    for (String topic : config.outputTopics()) {
      read(config, topic, published);
    }
    System.out.printf("Read sampled output in %.1fs%n", (System.nanoTime() - start) / 1e9);
    Verifier.Report report = verifier.verify(published);
    System.out.print(report.describe());
    return report.passed() ? 0 : 1;
  }

  /**
   * Waits until the app's consumer group has consumed everything (lag on every partition it reads,
   * source and internal, at most 1 for transaction markers) and the output topics stopped growing,
   * for several checks in a row.
   */
  private static void awaitSettled(CatalogConfig config, String groupId, List<String> sources, List<String> outputs,
      int timeoutSeconds) throws Exception {
    long start = System.nanoTime();
    long deadline = start + timeoutSeconds * 1_000_000_000L;
    try (Admin admin = Admin.create(Topics.adminClient(config))) {
      Set<TopicPartition> sourcePartitions = partitions(admin, sources);
      Set<TopicPartition> outputPartitions = partitions(admin, outputs);
      long previousLag = -1, previousOutput = -1, previousConsumed = -1;
      int stable = 0;
      while (System.nanoTime() < deadline) {
        Map<TopicPartition, OffsetAndMetadata> committed = admin.listConsumerGroupOffsets(groupId).partitionsToOffsetAndMetadata().get();
        Set<TopicPartition> tracked = new HashSet<>(sourcePartitions);
        tracked.addAll(committed.keySet());
        Map<TopicPartition, Long> ends = endOffsets(admin, tracked);
        long lag = 0, consumed = 0;
        for (TopicPartition tp : tracked) {
          OffsetAndMetadata c = committed.get(tp);
          long position = c == null ? 0 : c.offset();
          lag += Math.max(0, ends.getOrDefault(tp, 0L) - position);
          consumed += position;
        }
        long output = endOffsets(admin, outputPartitions).values().stream().mapToLong(Long::longValue).sum();
        boolean caughtUp = !committed.isEmpty() && lag <= tracked.size();
        stable = caughtUp && lag == previousLag && output == previousOutput ? stable + 1 : 0;
        double elapsed = (System.nanoTime() - start) / 1e9;
        System.out.printf("  t=%5.0fs lag=%,d consumed=%,d (+%,d) output records=%,d%s%n", elapsed, lag, consumed,
            previousConsumed < 0 ? 0 : consumed - previousConsumed, output, caughtUp ? " caught up" : "");
        if (stable >= SETTLE_STABLE_CHECKS) {
          System.out.printf("Settled after %.0fs%n", elapsed);
          return;
        }
        previousLag = lag;
        previousOutput = output;
        previousConsumed = consumed;
        Thread.sleep(SETTLE_POLL_MS);
      }
      throw new IllegalStateException("App did not catch up within " + timeoutSeconds + "s");
    }
  }

  private static Set<TopicPartition> partitions(Admin admin, Collection<String> topics) throws Exception {
    Set<TopicPartition> out = new HashSet<>();
    for (TopicDescription description : admin.describeTopics(topics).allTopicNames().get().values()) {
      description.partitions().forEach(p -> out.add(new TopicPartition(description.name(), p.partition())));
    }
    return out;
  }

  private static Map<TopicPartition, Long> endOffsets(Admin admin, Set<TopicPartition> partitions) throws Exception {
    Map<TopicPartition, OffsetSpec> request = new HashMap<>();
    partitions.forEach(tp -> request.put(tp, OffsetSpec.latest()));
    Map<TopicPartition, Long> out = new HashMap<>();
    admin.listOffsets(request).all().get().forEach((tp, info) -> out.put(tp, info.offset()));
    return out;
  }

  /** Reads a compacted topic from the beginning into {@code published}. */
  private static void read(CatalogConfig config, String topic, Outputs published) {
    Map<String, Object> props = new HashMap<>(Topics.adminClient(config));
    props.put(ConsumerConfig.ISOLATION_LEVEL_CONFIG, "read_committed");
    props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, "5000");
    props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
    try (KafkaConsumer<String, byte[]> consumer = new KafkaConsumer<>(props, new StringDeserializer(), new ByteArrayDeserializer())) {
      List<TopicPartition> partitions = new ArrayList<>();
      consumer.partitionsFor(topic).forEach(p -> partitions.add(new TopicPartition(topic, p.partition())));
      consumer.assign(partitions);
      consumer.seekToBeginning(partitions);
      Map<TopicPartition, Long> ends = consumer.endOffsets(partitions);
      long records = 0;
      while (partitions.stream().anyMatch(tp -> consumer.position(tp) < ends.get(tp))) {
        for (ConsumerRecord<String, byte[]> record : consumer.poll(Duration.ofSeconds(1))) {
          records++;
          published.accept(topic, record.key(), record.value());
        }
      }
      System.out.printf("  %s: %,d records read, %,d sampled keys%n", topic, records, published.latest(topic).size());
    }
  }

  private static void sleepNanos(long nanos) {
    try {
      Thread.sleep(nanos / 1_000_000, (int) (nanos % 1_000_000));
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }
}
