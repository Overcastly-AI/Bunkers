package com.motion.catalogjoin.topology;

import com.fasterxml.jackson.databind.JsonNode;
import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.SourceTable;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.TestInputTopic;
import org.apache.kafka.streams.TestOutputTopic;
import org.apache.kafka.streams.TopologyTestDriver;
import org.apache.kafka.streams.test.TestRecord;

/** Drives the real topology with raw CDC messages and tracks the latest published documents. */
final class Harness implements AutoCloseable {

  static final String ITEM_NUMBER_ATTR = "A-ITEM";
  static final String WEIGHT_ATTR = "A-WEIGHT";
  static final String DESC_ATTR = "A-DESC";

  final CatalogConfig config;
  final TopologyTestDriver driver;
  private final Map<SourceTable, TestInputTopic<byte[], byte[]>> inputs = new EnumMap<>(SourceTable.class);
  private final Map<String, Output> outputs = new LinkedHashMap<>();

  Harness() {
    this(new Properties());
  }

  Harness(Properties overrides) {
    Properties props = new Properties();
    props.setProperty(StreamsConfig.APPLICATION_ID_CONFIG, "catalog-join-test");
    props.setProperty(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "unused:9092");
    props.setProperty(StreamsConfig.STATESTORE_CACHE_MAX_BYTES_CONFIG, "0");
    props.setProperty("catalog.step.attribute.ITEM_NUMBER", ITEM_NUMBER_ATTR);
    props.setProperty("catalog.step.attribute.SHIPPING_WEIGHT", WEIGHT_ATTR);
    props.setProperty("catalog.step.attribute.SHORT_DESC", DESC_ATTR);
    props.putAll(overrides);
    this.config = CatalogConfig.from(props);
    Properties streamsProps = config.streamsProperties();
    streamsProps.put(StreamsConfig.STATE_DIR_CONFIG, System.getProperty("java.io.tmpdir") + "/catalog-join-test-" + System.nanoTime());
    this.driver = new TopologyTestDriver(CatalogTopology.build(config), streamsProps);
    for (SourceTable table : SourceTable.values()) {
      inputs.put(table, driver.createInputTopic(config.topic(table), new ByteArraySerializer(), new ByteArraySerializer()));
    }
    for (String topic : List.of(config.itemTopic(), config.itemLocationTopic(), config.itemPriceTopic())) {
      outputs.put(topic, new Output(driver.createOutputTopic(topic, new StringDeserializer(), new ByteArrayDeserializer())));
    }
  }

  /** Pipe a flat JSON row; the key object is built from the table's key columns. */
  void upsert(SourceTable table, Map<String, Object> row) {
    Map<String, Object> key = new LinkedHashMap<>();
    for (String column : table.keyColumns()) {
      key.put(column, row.get(column));
    }
    raw(table, Json.write(key), Json.write(row));
  }

  /** Pipe a tombstone for the given key columns. */
  void delete(SourceTable table, Map<String, Object> key) {
    raw(table, Json.write(key), null);
  }

  void raw(SourceTable table, byte[] key, byte[] value) {
    inputs.get(table).pipeInput(key, value);
  }

  void raw(SourceTable table, String key, String value) {
    raw(table, key == null ? null : bytes(key), value == null ? null : bytes(value));
  }

  JsonNode item(String itemNo) {
    return latest(config.itemTopic()).get("{\"ITEM_NO\":\"" + itemNo + "\"}");
  }

  JsonNode itemLocation(String itemNo, String miLoc) {
    return latest(config.itemLocationTopic()).get("{\"ITEM_NO\":\"" + itemNo + "\",\"MI_LOC\":\"" + miLoc + "\"}");
  }

  Map<String, JsonNode> latest(String topic) {
    return outputs.get(topic).drain().latest;
  }

  /** Every record published to the topic since the last call (null value = tombstone). */
  List<TestRecord<String, byte[]>> newRecords(String topic) {
    Output output = outputs.get(topic).drain();
    List<TestRecord<String, byte[]>> fresh = new ArrayList<>(output.unread);
    output.unread.clear();
    return fresh;
  }

  List<TestRecord<byte[], byte[]>> deadLetters() {
    return driver
        .createOutputTopic(config.deadLetterTopic(), new ByteArrayDeserializer(), new ByteArrayDeserializer())
        .readRecordsToList();
  }

  static Map<String, Object> row(Object... keyValues) {
    Map<String, Object> row = new LinkedHashMap<>();
    for (int i = 0; i < keyValues.length; i += 2) {
      row.put((String) keyValues[i], keyValues[i + 1]);
    }
    return row;
  }

  static byte[] bytes(String text) {
    return text.getBytes(java.nio.charset.StandardCharsets.UTF_8);
  }

  static JsonNode parse(byte[] json) {
    try {
      return Json.MAPPER.readTree(json);
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }

  @Override
  public void close() {
    driver.close();
  }

  private static final class Output {
    final TestOutputTopic<String, byte[]> topic;
    final Map<String, JsonNode> latest = new LinkedHashMap<>();
    final List<TestRecord<String, byte[]>> unread = new ArrayList<>();

    Output(TestOutputTopic<String, byte[]> topic) {
      this.topic = topic;
    }

    Output drain() {
      for (TestRecord<String, byte[]> record : topic.readRecordsToList()) {
        unread.add(record);
        if (record.value() == null) {
          latest.remove(record.key());
        } else {
          latest.put(record.key(), parse(record.value()));
        }
      }
      return this;
    }
  }
}
