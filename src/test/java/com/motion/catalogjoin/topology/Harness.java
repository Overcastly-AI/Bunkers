package com.motion.catalogjoin.topology;

import com.fasterxml.jackson.databind.JsonNode;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.testing.TopologyDriver;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.apache.kafka.streams.test.TestRecord;

/** Topology tests: pipe rows by table, read published documents by key. */
final class Harness implements AutoCloseable {

  final TopologyDriver driver;

  Harness() {
    this(Map.of());
  }

  Harness(Map<String, String> overrides) {
    this.driver = new TopologyDriver(TopologyDriver.config(overrides, TopologyDriver.TEST_CONFIG), key -> true);
  }

  /** STEP_ATTRIBUTE_ID configured for an output attribute name. */
  String attribute(String name) {
    return driver.config.stepAttributes().get(name);
  }

  /** Pipe a flat JSON row; the key object is built from the table's key columns. */
  void upsert(SourceTable table, Map<String, Object> row) {
    raw(table, Json.write(keyOf(table, row)), Json.write(row));
  }

  /** Pipe a tombstone for the given key columns. */
  void delete(SourceTable table, Map<String, Object> key) {
    raw(table, Json.write(keyOf(table, key)), null);
  }

  private Map<String, Object> keyOf(SourceTable table, Map<String, Object> row) {
    Map<String, Object> key = new LinkedHashMap<>();
    driver.config.keyColumns(table).forEach(column -> key.put(column, row.get(column)));
    return key;
  }

  void raw(SourceTable table, byte[] key, byte[] value) {
    driver.pipe(driver.config.topic(table), key, value);
  }

  void raw(SourceTable table, String key, String value) {
    raw(table, key == null ? null : key.getBytes(StandardCharsets.UTF_8), value == null ? null : value.getBytes(StandardCharsets.UTF_8));
  }

  JsonNode item(String itemNo) {
    return driver.document(driver.config.itemTopic(), Keys.of("ITEM_NO", itemNo));
  }

  JsonNode itemLocation(String itemNo, String miLoc) {
    return driver.document(driver.config.itemLocationTopic(), Keys.of("ITEM_NO", itemNo, "MI_LOC", miLoc));
  }

  List<TestRecord<String, byte[]>> newRecords(String topic) {
    return driver.newRecords(topic);
  }

  static Map<String, Object> row(Object... keyValues) {
    Map<String, Object> row = new LinkedHashMap<>();
    for (int i = 0; i < keyValues.length; i += 2) {
      row.put((String) keyValues[i], keyValues[i + 1]);
    }
    return row;
  }

  @Override
  public void close() {
    driver.close();
  }
}
