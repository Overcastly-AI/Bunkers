package com.motion.catalogjoin.sim;

import com.fasterxml.jackson.databind.JsonNode;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.SourceTable;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.atomic.AtomicReference;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;
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
import org.apache.kafka.common.errors.TopicExistsException;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringDeserializer;

/**
 * Load simulation against a real Kafka cluster.
 *
 * <pre>
 * java -cp catalog-join.jar com.motion.catalogjoin.sim.SimMain app-config [--topic-prefix P]
 * java -cp catalog-join.jar com.motion.catalogjoin.sim.SimMain generate --bootstrap B --items N [options]
 * java -cp catalog-join.jar com.motion.catalogjoin.sim.SimMain verify   --bootstrap B --items N [options]
 * </pre>
 *
 * The generate and verify runs must use the same --seed, --items, --locations and
 * --prices-per-item. Run {@code SimMain help} for every option.
 */
public final class SimMain {

  private static final String HELP = """
      Commands:
        app-config   Print the catalog-join settings that match the simulator (attribute ids, topics).
        generate     Produce the initial load (round 0) and churn rounds to the source topics.
        verify       Wait until the app has caught up, then check published documents against the model.

      Common options:
        --bootstrap HOST:PORT     Kafka bootstrap servers (generate, verify)
        --client-config FILE      Extra client properties (security, etc.) for producer/consumer/admin
        --topic-prefix P          Prefix for every simulated topic, e.g. "sim." (default: none)
        --items N                 Number of items (default 10000). ~30 source records per item at round 0.
        --seed S                  Model seed (default 42)
        --locations N             Number of locations (default 600)
        --prices-per-item N       Price-cache rows per priced item (default 2)

      generate:
        --from-round R            First round to emit (default 0 = initial load)
        --rounds R                Last round to emit (default 3)
        --formats SPEC            Message format mix, e.g. flat=70,envelope=20,avro=10 (default)
        --pad-share F             Share of rows whose key columns carry CHAR padding (default 0.1)
        --rate N                  Max messages per second (default 0 = unlimited)
        --create-topics           Create source, output and dead-letter topics if missing
        --partitions N            Partitions for created topics (default 6)
        --replication N           Replication factor for created topics (default 1)

      verify:
        --rounds R                Round the data was generated up to (default 3)
        --app-id ID               The app's application.id (default catalog-join)
        --sample-every N          Check every Nth item (default 1 = all; use 100 for 1% at large scale)
        --settle-timeout-s N      Max seconds to wait for the app to catch up (default 3600)
      """;

  private SimMain() {}

  public static void main(String[] argv) throws Exception {
    if (argv.length == 0 || argv[0].equals("help") || argv[0].equals("--help")) {
      System.out.println(HELP);
      return;
    }
    Args args = new Args(argv);
    int exit = switch (argv[0]) {
      case "app-config" -> appConfig(args);
      case "generate" -> generate(args);
      case "verify" -> verify(args);
      default -> {
        System.err.println("Unknown command " + argv[0] + "\n" + HELP);
        yield 2;
      }
    };
    System.exit(exit);
  }

  // --- app-config ----------------------------------------------------------------------------------

  private static int appConfig(Args args) {
    String prefix = args.get("topic-prefix", "");
    StringBuilder out = new StringBuilder("# catalog-join settings for the load simulation\n");
    SimModel.CONFIGURED_ATTRIBUTES.forEach((name, id) -> out.append("catalog.step.attribute.").append(name).append('=').append(id).append('\n'));
    if (!prefix.isEmpty()) {
      for (SourceTable table : SourceTable.values()) {
        out.append("catalog.topic.").append(table.slug()).append('=').append(prefix).append(table.defaultTopic()).append('\n');
      }
    }
    out.append("catalog.output.item=").append(prefix).append("catalog.item\n");
    out.append("catalog.output.item-location=").append(prefix).append("catalog.item-location\n");
    out.append("catalog.output.item-price=").append(prefix).append("catalog.item-price\n");
    out.append("catalog.output.dead-letter=").append(prefix).append("catalog.join.dlt\n");
    System.out.print(out);
    return 0;
  }

  // --- generate ------------------------------------------------------------------------------------

  private static int generate(Args args) throws Exception {
    SimModel model = model(args);
    long seed = args.getLong("seed", 42);
    String prefix = args.get("topic-prefix", "");
    Properties client = client(args);
    if (args.flag("create-topics")) {
      createTopics(client, prefix, args.getInt("partitions", 6), (short) args.getInt("replication", 1));
    }
    Encoder encoder = new Encoder(seed, prefix, Encoder.parseWeights(args.get("formats", "flat=70,envelope=20,avro=10")),
        args.getDouble("pad-share", 0.1));

    Properties producerProps = new Properties();
    producerProps.putAll(client);
    producerProps.putIfAbsent(ProducerConfig.ACKS_CONFIG, "all");
    producerProps.putIfAbsent(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
    producerProps.putIfAbsent(ProducerConfig.LINGER_MS_CONFIG, "20");
    producerProps.putIfAbsent(ProducerConfig.BATCH_SIZE_CONFIG, "524288");
    producerProps.putIfAbsent(ProducerConfig.COMPRESSION_TYPE_CONFIG, "lz4");
    producerProps.putIfAbsent(ProducerConfig.BUFFER_MEMORY_CONFIG, "268435456");

    int from = args.getInt("from-round", 0);
    int to = args.getInt("rounds", 3);
    long rate = args.getLong("rate", 0);
    AtomicReference<Exception> failure = new AtomicReference<>();
    long start = System.nanoTime();
    long[] sent = {0};
    long[] lastReport = {start};

    try (KafkaProducer<byte[], byte[]> producer = new KafkaProducer<>(producerProps, new ByteArraySerializer(), new ByteArraySerializer())) {
      Generator.Sink sink = new Generator.Sink() {
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
          if (rate > 0) {
            long due = start + (long) (sent[0] * 1e9 / rate);
            if (due > now) {
              sleepNanos(due - now);
            }
          }
          if (now - lastReport[0] > 5_000_000_000L) {
            lastReport[0] = now;
            double seconds = (now - start) / 1e9;
            System.out.printf("  %,d messages, %,.0f msg/s%n", sent[0], sent[0] / seconds);
          }
        }

        @Override
        public void flush() {
          producer.flush();
        }
      };
      Generator generator = new Generator(model, encoder, sink, seed);
      System.out.printf("Generating rounds %d..%d for %,d items%n", from, to, model.items());
      generator.run(from, to, round -> System.out.printf("round %d done: %,d messages so far%n", round, sent[0]));
      producer.flush();
      if (failure.get() != null) {
        throw failure.get();
      }
      double seconds = (System.nanoTime() - start) / 1e9;
      System.out.printf("Produced %,d messages in %.1fs (%,.0f msg/s)%n", sent[0], seconds, sent[0] / seconds);
      generator.counts().forEach((table, count) -> System.out.printf("  %-28s %,d%n", table, count[0]));
    }
    return 0;
  }

  private static void createTopics(Properties client, String prefix, int partitions, short replication) throws Exception {
    List<NewTopic> topics = new ArrayList<>();
    Map<String, String> compact = Map.of("cleanup.policy", "compact");
    for (SourceTable table : SourceTable.values()) {
      topics.add(new NewTopic(prefix + table.defaultTopic(), partitions, replication).configs(compact));
    }
    for (String output : List.of("catalog.item", "catalog.item-location", "catalog.item-price")) {
      topics.add(new NewTopic(prefix + output, partitions, replication)
          .configs(Map.of("cleanup.policy", "compact", "max.message.bytes", "4194304")));
    }
    topics.add(new NewTopic(prefix + "catalog.join.dlt", partitions, replication));
    try (Admin admin = Admin.create(client)) {
      for (NewTopic topic : topics) {
        try {
          admin.createTopics(List.of(topic)).all().get();
          System.out.println("created " + topic.name());
        } catch (ExecutionException e) {
          if (!(e.getCause() instanceof TopicExistsException)) {
            throw e;
          }
        }
      }
    }
  }

  // --- verify --------------------------------------------------------------------------------------

  private static int verify(Args args) throws Exception {
    SimModel model = model(args);
    String prefix = args.get("topic-prefix", "");
    Properties client = client(args);
    Verifier verifier = new Verifier(model, args.getInt("rounds", 3), args.getInt("sample-every", 1));

    List<String> sources = new ArrayList<>();
    for (SourceTable table : SourceTable.values()) {
      sources.add(prefix + table.defaultTopic());
    }
    List<String> outputs = List.of(prefix + "catalog.item", prefix + "catalog.item-location", prefix + "catalog.item-price");
    awaitSettled(client, args.get("app-id", "catalog-join"), sources, outputs, args.getInt("settle-timeout-s", 3600));

    long start = System.nanoTime();
    Verifier.Published published = new Verifier.Published(
        read(client, outputs.get(0), verifier), read(client, outputs.get(1), verifier), read(client, outputs.get(2), verifier));
    System.out.printf("Read sampled output in %.1fs%n", (System.nanoTime() - start) / 1e9);
    Verifier.Report report = verifier.verify(published);
    System.out.print(report.describe());
    return report.passed() ? 0 : 1;
  }

  /**
   * Waits until the app's consumer group has consumed everything (lag on every partition it reads,
   * source and internal, at most 1 for transaction markers) and the output topics stopped growing,
   * for three checks in a row.
   */
  private static void awaitSettled(Properties client, String groupId, List<String> sources, List<String> outputs, int timeoutSeconds)
      throws Exception {
    long deadline = System.nanoTime() + timeoutSeconds * 1_000_000_000L;
    long start = System.nanoTime();
    try (Admin admin = Admin.create(client)) {
      Set<TopicPartition> sourcePartitions = partitions(admin, sources);
      Set<TopicPartition> outputPartitions = partitions(admin, outputs);
      long previousLag = -1, previousOutput = -1, previousConsumed = -1;
      int stable = 0;
      while (System.nanoTime() < deadline) {
        Map<TopicPartition, OffsetAndMetadata> committed =
            admin.listConsumerGroupOffsets(groupId).partitionsToOffsetAndMetadata().get();
        Set<TopicPartition> tracked = new HashSet<>(sourcePartitions);
        tracked.addAll(committed.keySet());
        Map<TopicPartition, Long> ends = endOffsets(admin, tracked);
        Map<TopicPartition, Long> outputEnds = endOffsets(admin, outputPartitions);
        long lag = 0, consumed = 0;
        for (TopicPartition tp : tracked) {
          OffsetAndMetadata c = committed.get(tp);
          long position = c == null ? 0 : c.offset();
          lag += Math.max(0, ends.getOrDefault(tp, 0L) - position);
          consumed += position;
        }
        long output = outputEnds.values().stream().mapToLong(Long::longValue).sum();
        boolean caughtUp = !committed.isEmpty() && lag <= tracked.size();
        stable = caughtUp && lag == previousLag && output == previousOutput ? stable + 1 : 0;
        double elapsed = (System.nanoTime() - start) / 1e9;
        System.out.printf("  t=%5.0fs lag=%,d consumed=%,d (+%,d) output records=%,d%s%n", elapsed, lag, consumed,
            previousConsumed < 0 ? 0 : consumed - previousConsumed, output, caughtUp ? " caught up" : "");
        if (stable >= 3) {
          System.out.printf("Settled after %.0fs%n", elapsed);
          return;
        }
        previousLag = lag;
        previousOutput = output;
        previousConsumed = consumed;
        Thread.sleep(5000);
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

  /** Reads a compacted topic from the beginning, keeping the latest value of sampled keys. */
  private static Map<String, JsonNode> read(Properties client, String topic, Verifier verifier) throws Exception {
    Properties props = new Properties();
    props.putAll(client);
    props.put(ConsumerConfig.ISOLATION_LEVEL_CONFIG, "read_committed");
    props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, "5000");
    props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
    Map<String, JsonNode> latest = new HashMap<>();
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
          if (!verifier.isSampled(record.key())) {
            continue;
          }
          if (record.value() == null) {
            latest.remove(record.key());
          } else {
            latest.put(record.key(), Json.MAPPER.readTree(record.value()));
          }
        }
      }
      System.out.printf("  %s: %,d records read, %,d sampled keys%n", topic, records, latest.size());
    }
    return latest;
  }

  // --- helpers -------------------------------------------------------------------------------------

  private static SimModel model(Args args) {
    return new SimModel(args.getLong("seed", 42), args.getInt("items", 10_000), args.getInt("locations", 600),
        args.getInt("prices-per-item", 2));
  }

  private static Properties client(Args args) throws IOException {
    Properties props = new Properties();
    String file = args.get("client-config", null);
    if (file != null) {
      try (InputStream in = Files.newInputStream(Path.of(file))) {
        props.load(in);
      }
    }
    String bootstrap = args.get("bootstrap", null);
    if (bootstrap != null) {
      props.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrap);
    }
    if (!props.containsKey(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG)) {
      throw new IllegalArgumentException("--bootstrap (or bootstrap.servers in --client-config) is required");
    }
    return props;
  }

  private static void sleepNanos(long nanos) {
    try {
      Thread.sleep(nanos / 1_000_000, (int) (nanos % 1_000_000));
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }

  private static final class Args {
    private final Map<String, String> values = new HashMap<>();

    Args(String[] argv) {
      for (int i = 1; i < argv.length; i++) {
        String arg = argv[i];
        if (!arg.startsWith("--")) {
          throw new IllegalArgumentException("Unexpected argument " + arg);
        }
        String name = arg.substring(2);
        int eq = name.indexOf('=');
        if (eq >= 0) {
          values.put(name.substring(0, eq), name.substring(eq + 1));
        } else if (i + 1 < argv.length && !argv[i + 1].startsWith("--")) {
          values.put(name, argv[++i]);
        } else {
          values.put(name, "true");
        }
      }
    }

    String get(String name, String fallback) {
      return values.getOrDefault(name, fallback);
    }

    boolean flag(String name) {
      return Boolean.parseBoolean(values.getOrDefault(name, "false"));
    }

    int getInt(String name, int fallback) {
      return values.containsKey(name) ? Integer.parseInt(values.get(name)) : fallback;
    }

    long getLong(String name, long fallback) {
      return values.containsKey(name) ? Long.parseLong(values.get(name)) : fallback;
    }

    double getDouble(String name, double fallback) {
      return values.containsKey(name) ? Double.parseDouble(values.get(name)) : fallback;
    }
  }
}
