package com.motion.catalogjoin.testing;

import com.fasterxml.jackson.databind.JsonNode;
import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.sim.Outputs;
import com.motion.catalogjoin.topology.CatalogTopology;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.function.Predicate;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.TestInputTopic;
import org.apache.kafka.streams.TestOutputTopic;
import org.apache.kafka.streams.TopologyTestDriver;
import org.apache.kafka.streams.test.TestRecord;

/** The real topology in a TopologyTestDriver, with the published documents tracked per key. */
public final class TopologyDriver implements AutoCloseable {

  public static final Path TEST_CONFIG = Path.of("src/test/resources/test.properties");
  public static final Path SIM_CONFIG = Path.of("deploy/sim/catalog-join.properties");

  public final CatalogConfig config;
  private final TopologyTestDriver driver;
  private final Map<String, TestInputTopic<byte[], byte[]>> inputs = new HashMap<>();
  private final Map<String, TestOutputTopic<String, byte[]>> outputs = new LinkedHashMap<>();
  private final Map<String, List<TestRecord<String, byte[]>>> unread = new HashMap<>();
  private final Outputs latest;

  /** Configuration: jar defaults, then {@code files}, then {@code overrides}. */
  public static CatalogConfig config(Map<String, String> overrides, Path... files) {
    return CatalogConfig.load(List.of(files), overrides);
  }

  public TopologyDriver(CatalogConfig config, Predicate<String> keep) {
    this.config = config;
    this.latest = new Outputs(keep);
    Properties props = config.streamsProperties();
    props.put(StreamsConfig.STATE_DIR_CONFIG, tempDir().toString());
    this.driver = new TopologyTestDriver(CatalogTopology.build(config), props);
    for (SourceTable table : SourceTable.values()) {
      inputs.put(config.topic(table), driver.createInputTopic(config.topic(table), new ByteArraySerializer(), new ByteArraySerializer()));
    }
    List<String> published = new ArrayList<>(config.outputTopics());
    config.clients().values().forEach(client -> published.add(client.topic()));
    for (String topic : published) {
      outputs.put(topic, driver.createOutputTopic(topic, new StringDeserializer(), new ByteArrayDeserializer()));
    }
  }

  public void pipe(String topic, byte[] key, byte[] value) {
    inputs.get(topic).pipeInput(key, value);
  }

  /** Lets time pass so caches flush and punctuations run. */
  public void advance() {
    driver.advanceWallClockTime(Duration.ofMinutes(1));
  }

  /** Latest published document per (kept) key, as a consumer of the compacted topic sees it. */
  public Outputs outputs() {
    drain();
    return latest;
  }

  public JsonNode document(String topic, String key) {
    Map<String, Object> doc = outputs().latest(topic).get(key);
    return doc == null ? null : Json.MAPPER.valueToTree(doc);
  }

  /** Records published to {@code topic} since the last call (null value = tombstone). */
  public List<TestRecord<String, byte[]>> newRecords(String topic) {
    drain();
    List<TestRecord<String, byte[]>> fresh = new ArrayList<>(unread.getOrDefault(topic, List.of()));
    unread.remove(topic);
    return fresh;
  }

  public List<TestRecord<byte[], byte[]>> deadLetters() {
    return driver.createOutputTopic(config.deadLetterTopic(), new ByteArrayDeserializer(), new ByteArrayDeserializer())
        .readRecordsToList();
  }

  private void drain() {
    outputs.forEach((topic, output) -> {
      for (TestRecord<String, byte[]> record : output.readRecordsToList()) {
        unread.computeIfAbsent(topic, t -> new ArrayList<>()).add(record);
        latest.accept(topic, record.key(), record.value());
      }
    });
  }

  @Override
  public void close() {
    driver.close();
  }

  private static Path tempDir() {
    try {
      return Files.createTempDirectory("catalog-join-test");
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }
}
