package com.motion.catalogjoin.ops;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Topics;
import com.motion.catalogjoin.clients.Client;
import com.motion.catalogjoin.ingest.Sources;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.concurrent.Future;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.header.Header;
import org.apache.kafka.common.header.Headers;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.streams.StreamsConfig;

/**
 * {@code catalog-join dlt-replay}: replays dead letters once their cause is fixed. Progress is kept
 * in a consumer group, so each dead letter is handled once; {@code --from-beginning} reconsiders all.
 *
 * <ul>
 *   <li>Source dead letters ({@code catalog.join.dlt}) are re-produced to the topic and partition
 *       they came from. One is skipped when the same key has a newer record on that partition
 *       (replaying it would overwrite newer data), or when it has no key to check; {@code --force}
 *       replays those too. A record that still cannot be decoded is dead-lettered again.
 *   <li>Client dead letters ({@code --client NAME}) are rejected batches. Their keys are
 *       republished, so the client receives each key's current value, not the stale batch.
 * </ul>
 */
public final class DltReplay {

  /** What to do with one source dead letter. */
  enum Decision { REPLAY, SUPERSEDED, NO_KEY, NO_ORIGIN }

  private DltReplay() {}

  public static int run(CatalogConfig config, String clientName, boolean force, boolean fromBeginning, boolean dryRun)
      throws Exception {
    String app = config.streamsProperties().getProperty(StreamsConfig.APPLICATION_ID_CONFIG);
    if (clientName != null) {
      Client client = config.clients().get(clientName);
      if (client == null) {
        System.err.println("No client '" + clientName + "'; configured clients: " + config.clients().keySet());
        return 2;
      }
      return clients(config, client, app + "-dlt-replay-" + clientName, fromBeginning, dryRun);
    }
    return sources(config, app + "-dlt-replay", force, fromBeginning, dryRun);
  }

  // --- source dead letters -------------------------------------------------------------------------

  private static int sources(CatalogConfig config, String group, boolean force, boolean fromBeginning, boolean dryRun)
      throws Exception {
    try (KafkaConsumer<byte[], byte[]> dlt = consumer(config, group)) {
      Pending pending = read(dlt, config.deadLetterTopic(), fromBeginning);
      List<ConsumerRecord<byte[], byte[]>> letters = pending.records();
      Map<TopicPartition, Map<ByteBuffer, Long>> latest = latestOffsets(config, letters);
      Map<Decision, Integer> counts = new TreeMap<>();
      List<Future<?>> sent = new ArrayList<>();
      Map<String, Object> producerProps = new HashMap<>(Topics.adminClient(config));
      producerProps.put(ProducerConfig.ACKS_CONFIG, "all");
      producerProps.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
      try (KafkaProducer<byte[], byte[]> producer = new KafkaProducer<>(producerProps, new ByteArraySerializer(), new ByteArraySerializer())) {
        for (ConsumerRecord<byte[], byte[]> letter : letters) {
          Origin origin = Origin.of(letter.headers());
          Decision decision = decide(letter.key(), origin, origin == null ? null : latest.get(origin.partition()), force);
          counts.merge(decision, 1, Integer::sum);
          if (decision != Decision.REPLAY) {
            System.out.printf("  skip %s offset %d (%s)%n", origin == null ? "?" : origin.partition(), origin == null ? -1 : origin.offset(), decision);
          } else if (!dryRun) {
            sent.add(producer.send(new ProducerRecord<>(origin.partition().topic(), origin.partition().partition(),
                letter.key(), letter.value(), originalHeaders(letter.headers()))));
          }
        }
        producer.flush();
        for (Future<?> future : sent) {
          future.get();
        }
      }
      System.out.printf("%s %d source dead letter(s): %s%n", dryRun ? "Would handle" : "Handled", letters.size(), counts);
      if (!dryRun) {
        dlt.commitSync(pending.next());
      }
      return 0;
    }
  }

  /** Replay unless a newer record for the same key exists (or the key is unknown), unless forced. */
  static Decision decide(byte[] key, Origin origin, Map<ByteBuffer, Long> latestByKey, boolean force) {
    if (origin == null) {
      return Decision.NO_ORIGIN;
    }
    if (force) {
      return Decision.REPLAY;
    }
    if (key == null) {
      return Decision.NO_KEY;
    }
    Long newest = latestByKey == null ? null : latestByKey.get(ByteBuffer.wrap(key));
    return newest != null && newest > origin.offset() ? Decision.SUPERSEDED : Decision.REPLAY;
  }

  /** Where a dead letter came from, from the headers the app adds. */
  record Origin(TopicPartition partition, long offset) {
    static Origin of(Headers headers) {
      String topic = text(headers, Sources.HEADER_TOPIC);
      String partition = text(headers, Sources.HEADER_PARTITION);
      String offset = text(headers, Sources.HEADER_OFFSET);
      if (topic == null || partition == null || offset == null) {
        return null;
      }
      return new Origin(new TopicPartition(topic, Integer.parseInt(partition)), Long.parseLong(offset));
    }
  }

  /**
   * For each source partition with dead letters: the last offset of each of their keys, scanning
   * from the earliest dead letter to the current end.
   */
  private static Map<TopicPartition, Map<ByteBuffer, Long>> latestOffsets(CatalogConfig config,
      List<ConsumerRecord<byte[], byte[]>> letters) {
    Map<TopicPartition, Long> from = new HashMap<>();
    Map<TopicPartition, Set<ByteBuffer>> keys = new HashMap<>();
    for (ConsumerRecord<byte[], byte[]> letter : letters) {
      Origin origin = Origin.of(letter.headers());
      if (origin != null && letter.key() != null) {
        from.merge(origin.partition(), origin.offset() + 1, Math::min);
        keys.computeIfAbsent(origin.partition(), p -> new java.util.HashSet<>()).add(ByteBuffer.wrap(letter.key()));
      }
    }
    Map<TopicPartition, Map<ByteBuffer, Long>> latest = new HashMap<>();
    if (from.isEmpty()) {
      return latest;
    }
    Map<String, Object> props = new HashMap<>(Topics.adminClient(config));
    props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
    props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, "5000");
    try (KafkaConsumer<byte[], byte[]> source = new KafkaConsumer<>(props, new ByteArrayDeserializer(), new ByteArrayDeserializer())) {
      source.assign(from.keySet());
      Map<TopicPartition, Long> end = source.endOffsets(from.keySet());
      from.forEach(source::seek);
      Set<TopicPartition> remaining = new java.util.HashSet<>(from.keySet());
      remaining.removeIf(p -> source.position(p) >= end.get(p));
      while (!remaining.isEmpty()) {
        for (ConsumerRecord<byte[], byte[]> record : source.poll(Duration.ofSeconds(1))) {
          TopicPartition partition = new TopicPartition(record.topic(), record.partition());
          if (record.key() != null && keys.get(partition).contains(ByteBuffer.wrap(record.key()))) {
            latest.computeIfAbsent(partition, p -> new HashMap<>()).merge(ByteBuffer.wrap(record.key()), record.offset(), Math::max);
          }
        }
        remaining.removeIf(p -> source.position(p) >= end.get(p));
      }
    }
    return latest;
  }

  private static Iterable<Header> originalHeaders(Headers headers) {
    List<Header> kept = new ArrayList<>();
    headers.forEach(h -> {
      if (!h.key().startsWith("catalog.")) {
        kept.add(h);
      }
    });
    return kept;
  }

  // --- client dead letters -------------------------------------------------------------------------

  private static int clients(CatalogConfig config, Client client, String group, boolean fromBeginning, boolean dryRun)
      throws Exception {
    try (KafkaConsumer<byte[], byte[]> dlt = consumer(config, group)) {
      Pending pending = read(dlt, client.deadLetterTopic(), fromBeginning);
      Set<String> keys = new LinkedHashSet<>();
      for (ConsumerRecord<byte[], byte[]> batch : pending.records()) {
        keys.addAll(batchKeys(new String(batch.value(), StandardCharsets.UTF_8)));
      }
      System.out.printf("%s %d rejected batch(es) for %s: %,d key(s) to republish with their current values%n",
          dryRun ? "Would replay" : "Replaying", pending.records().size(), client.name(), keys.size());
      if (!dryRun) {
        if (!keys.isEmpty()) {
          Republish.send(config, new Republish.Request(client.source(), Set.of("client-" + client.name())), keys);
        }
        dlt.commitSync(pending.next());
      }
      return 0;
    }
  }

  /** Canonical keys of a delivered batch body ({@code [{"key": {...}, "value": ...}, ...]}). */
  @SuppressWarnings("unchecked")
  static List<String> batchKeys(String body) {
    List<String> keys = new ArrayList<>();
    try {
      for (Object item : Json.MAPPER.readValue(body, List.class)) {
        if (item instanceof Map<?, ?> entry && entry.get("key") instanceof Map<?, ?> key) {
          keys.add(Keys.of((Map<String, Object>) key, new java.util.TreeSet<>((Set<String>) key.keySet())));
        }
      }
    } catch (java.io.IOException e) {
      throw new IllegalArgumentException("Not a delivered batch: " + body, e);
    }
    return keys;
  }

  // --- reading a dead-letter topic up to its current end -------------------------------------------

  private record Pending(List<ConsumerRecord<byte[], byte[]>> records, Map<TopicPartition, OffsetAndMetadata> next) {}

  private static KafkaConsumer<byte[], byte[]> consumer(CatalogConfig config, String group) {
    Map<String, Object> props = new HashMap<>(Topics.adminClient(config));
    props.put(ConsumerConfig.GROUP_ID_CONFIG, group);
    props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
    props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
    return new KafkaConsumer<>(props, new ByteArrayDeserializer(), new ByteArrayDeserializer());
  }

  /** Every record from the group's position (or the beginning) to the end as of now. */
  private static Pending read(KafkaConsumer<byte[], byte[]> consumer, String topic, boolean fromBeginning) {
    List<TopicPartition> partitions = consumer.partitionsFor(topic).stream()
        .map(p -> new TopicPartition(topic, p.partition())).toList();
    consumer.assign(partitions);
    Map<TopicPartition, Long> end = consumer.endOffsets(partitions);
    Map<TopicPartition, OffsetAndMetadata> committed = consumer.committed(new java.util.HashSet<>(partitions));
    for (TopicPartition partition : partitions) {
      OffsetAndMetadata position = committed.get(partition);
      if (fromBeginning || position == null) {
        consumer.seekToBeginning(List.of(partition));
      } else {
        consumer.seek(partition, position.offset());
      }
    }
    List<ConsumerRecord<byte[], byte[]>> records = new ArrayList<>();
    Set<TopicPartition> remaining = new java.util.HashSet<>(partitions);
    remaining.removeIf(p -> consumer.position(p) >= end.get(p));
    while (!remaining.isEmpty()) {
      for (ConsumerRecord<byte[], byte[]> record : consumer.poll(Duration.ofSeconds(1))) {
        if (record.offset() < end.get(new TopicPartition(record.topic(), record.partition()))) {
          records.add(record);
        }
      }
      remaining.removeIf(p -> consumer.position(p) >= end.get(p));
    }
    Map<TopicPartition, OffsetAndMetadata> next = new HashMap<>();
    end.forEach((partition, offset) -> next.put(partition, new OffsetAndMetadata(offset)));
    return new Pending(records, next);
  }

  private static String text(Headers headers, String key) {
    Header header = headers.lastHeader(key);
    return header == null ? null : new String(header.value(), StandardCharsets.UTF_8);
  }
}
