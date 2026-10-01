package com.motion.catalogjoin.topology;

import static com.motion.catalogjoin.SourceTable.ITEM_BALANCE;
import static com.motion.catalogjoin.SourceTable.ITEM_COST;
import static com.motion.catalogjoin.SourceTable.ITEM_PROFILE;
import static com.motion.catalogjoin.SourceTable.ITEM_RESTRICT_RULE;
import static com.motion.catalogjoin.SourceTable.LOCAL_COST;
import static com.motion.catalogjoin.SourceTable.LOCATION_PROFILE;
import static com.motion.catalogjoin.SourceTable.MFR_NAME;
import static com.motion.catalogjoin.SourceTable.MFR_PROFILE;
import static com.motion.catalogjoin.SourceTable.NON_COS_ITEM_BALANCE;
import static com.motion.catalogjoin.SourceTable.STEP_CLASSIFICATION;
import static com.motion.catalogjoin.SourceTable.STEP_PRODUCT;
import static com.motion.catalogjoin.SourceTable.STEP_PRODUCT_CLASSIFICATION;
import static com.motion.catalogjoin.SourceTable.STEP_PRODUCT_VALUES;
import static com.motion.catalogjoin.SourceTable.STEP_UNIT;
import static com.motion.catalogjoin.topology.Harness.row;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.ingest.CdcEnvelope;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.BinaryEncoder;
import org.apache.avro.io.EncoderFactory;
import org.apache.kafka.streams.test.TestRecord;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class JoinLifecycleTest {

  private final Harness h = new Harness();
  private final String itemAttr = h.attribute("ITEM_NUMBER");
  private final String weightAttr = h.attribute("SHIPPING_WEIGHT");
  private final String descAttr = h.attribute("SHORT_DESC");

  @AfterEach
  void close() { h.close(); }

  private String itemTopic() { return h.driver.config.itemTopic(); }
  private String itemLocationTopic() { return h.driver.config.itemLocationTopic(); }

  private void item(String itemNo, String mfr, String productGroup) {
    h.upsert(ITEM_PROFILE, row("ITEM_NO", itemNo, "MFR_CTL_NO", mfr, "PRODUCT_GROUP_NO", productGroup, "DESCR", "Bearing " + itemNo));
  }
  private void stepValue(String product, String attribute, String unit, String value) {
    h.upsert(STEP_PRODUCT_VALUES, row("STEP_PRODUCT_ID", product, "STEP_ATTRIBUTE_ID", attribute, "STEP_UNIT_ID", unit, "VALUE", value));
  }
  private void deleteStepValue(String product, String attribute, String unit, String value) {
    h.delete(STEP_PRODUCT_VALUES, row("STEP_PRODUCT_ID", product, "STEP_ATTRIBUTE_ID", attribute, "STEP_UNIT_ID", unit, "VALUE", value));
  }
  private static List<String> texts(JsonNode array, String field) {
    List<String> out = new ArrayList<>();
    array.forEach(node -> out.add(node.path(field).asText()));
    return out;
  }
  private static JsonNode parse(byte[] json) {
    try { return Json.MAPPER.readTree(json); } catch (IOException e) { throw new UncheckedIOException(e); }
  }
  private static byte[] avro(String op, Map<String, Object> before, Map<String, Object> after, boolean confluent) {
    GenericRecord envelope = new GenericData.Record(CdcEnvelope.SCHEMA);
    envelope.put(CdcEnvelope.OP, op);
    envelope.put(CdcEnvelope.BEFORE, before);
    envelope.put(CdcEnvelope.AFTER, after);
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      if (confluent) out.write(ByteBuffer.allocate(5).put((byte) 0).putInt(42).array());
      BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(out, null);
      new GenericDatumWriter<GenericRecord>(CdcEnvelope.SCHEMA).write(envelope, encoder);
      encoder.flush();
      return out.toByteArray();
    } catch (IOException e) { throw new UncheckedIOException(e); }
  }
  private byte[] keyOf(SourceTable table, Map<String, Object> row) {
    Map<String, Object> key = new LinkedHashMap<>();
    for (String column : h.driver.config.keyColumns(table)) key.put(column, row.get(column));
    return Json.write(key);
  }
  private static byte[] utf8(String text) { return text.getBytes(StandardCharsets.UTF_8); }

  // --- manufacturer chain ---

  @Test
  void deletingAndReaddingMfrProfileClearsAndRestoresTheManufacturer() {
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N1", "MFR_NAME", "SKF"));
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1", "SELLABLE", "Y"));
    item("100", "AB", "G1");
    assertThat(h.item("100").path("manufacturer").path("name").path("MFR_NAME").asText()).isEqualTo("SKF");
    h.delete(MFR_PROFILE, row("MFR_CTL_NO", "AB"));
    assertThat(h.item("100").path("manufacturer").isNull()).isTrue();
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1", "SELLABLE", "N"));
    JsonNode m = h.item("100").path("manufacturer");
    assertThat(m.path("profile").path("SELLABLE").asText()).isEqualTo("N");
    assertThat(m.path("name").path("MFR_NAME").asText()).isEqualTo("SKF");
  }

  @Test
  void deletingAndReaddingMfrNameClearsAndRestoresTheName() {
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N1", "MFR_NAME", "SKF"));
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1"));
    item("100", "AB", "G1");
    item("101", "AB", "G1");
    h.delete(MFR_NAME, row("MFR_NAME_ID", "N1"));
    assertThat(h.item("100").path("manufacturer").path("profile").path("MFR_CTL_NO").asText()).isEqualTo("AB");
    assertThat(h.item("100").path("manufacturer").path("name").isNull()).isTrue();
    assertThat(h.item("101").path("manufacturer").path("name").isNull()).isTrue();
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N1", "MFR_NAME", "SKF again"));
    assertThat(h.item("100").path("manufacturer").path("name").path("MFR_NAME").asText()).isEqualTo("SKF again");
    assertThat(h.item("101").path("manufacturer").path("name").path("MFR_NAME").asText()).isEqualTo("SKF again");
  }

  @Test
  void mfrProfileRepointedAtAnotherNameAndThenAtNone() {
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N1", "MFR_NAME", "SKF"));
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N2", "MFR_NAME", "Timken"));
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1"));
    item("100", "AB", "G1");
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N2"));
    assertThat(h.item("100").path("manufacturer").path("name").path("MFR_NAME").asText()).isEqualTo("Timken");
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N1", "MFR_NAME", "SKF changed"));
    assertThat(h.item("100").path("manufacturer").path("name").path("MFR_NAME").asText()).isEqualTo("Timken");
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", " "));
    assertThat(h.item("100").path("manufacturer").path("profile").path("MFR_CTL_NO").asText()).isEqualTo("AB");
    assertThat(h.item("100").path("manufacturer").path("name").isNull()).isTrue();
    h.delete(MFR_PROFILE, row("MFR_CTL_NO", "AB"));
    assertThat(h.item("100").path("manufacturer").isNull()).isTrue();
  }

  @Test
  void itemWhoseManufacturerBecomesBlankLosesManufacturerAndManufacturerRules() {
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1"));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R2", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", " "));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R3", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", "G1"));
    item("100", "AB", "G1");
    assertThat(texts(h.item("100").path("restrictions").path("manufacturer"), "CTL_NO")).containsExactly("R2");
    assertThat(texts(h.item("100").path("restrictions").path("manufacturerProductGroup"), "CTL_NO")).containsExactly("R3");
    item("100", " ", "G1");
    JsonNode doc = h.item("100");
    assertThat(doc.path("manufacturer").isNull()).isTrue();
    assertThat(doc.path("restrictions").path("manufacturer")).isEmpty();
    assertThat(doc.path("restrictions").path("manufacturerProductGroup")).isEmpty();
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N9"));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R2", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", " ", "X", "1"));
    assertThat(h.item("100").path("manufacturer").isNull()).isTrue();
    assertThat(h.item("100").path("restrictions").path("manufacturer")).isEmpty();
  }

  // --- restriction rules ---

  @Test
  void ruleDeletesReaddsAndForeignKeyChangesOfEveryKind() {
    item("100", "AB", "G1");
    item("200", "CD", "G2");
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R1", "ITEM_NO", "100", "MFR_CTL_NO", " ", "PROD_GROUP_NO", " "));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R2", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", " "));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R3", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", "G1"));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R1", "ITEM_NO", "200", "MFR_CTL_NO", " ", "PROD_GROUP_NO", " "));
    assertThat(h.item("100").path("restrictions").path("item")).isEmpty();
    assertThat(texts(h.item("200").path("restrictions").path("item"), "CTL_NO")).containsExactly("R1");
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R2", "ITEM_NO", " ", "MFR_CTL_NO", "CD", "PROD_GROUP_NO", " "));
    assertThat(h.item("100").path("restrictions").path("manufacturer")).isEmpty();
    assertThat(texts(h.item("200").path("restrictions").path("manufacturer"), "CTL_NO")).containsExactly("R2");
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R2", "ITEM_NO", " ", "MFR_CTL_NO", "CD", "PROD_GROUP_NO", "G2"));
    assertThat(h.item("200").path("restrictions").path("manufacturer")).isEmpty();
    assertThat(texts(h.item("200").path("restrictions").path("manufacturerProductGroup"), "CTL_NO")).containsExactly("R2");
    h.delete(ITEM_RESTRICT_RULE, row("CTL_NO", "R3"));
    assertThat(h.item("100").path("restrictions").path("manufacturerProductGroup")).isEmpty();
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R3", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", "G1"));
    assertThat(texts(h.item("100").path("restrictions").path("manufacturerProductGroup"), "CTL_NO")).containsExactly("R3");
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R4", "ITEM_NO", "200", "MFR_CTL_NO", " ", "PROD_GROUP_NO", " "));
    assertThat(texts(h.item("200").path("restrictions").path("item"), "CTL_NO")).containsExactly("R1", "R4");
    h.delete(ITEM_RESTRICT_RULE, row("CTL_NO", "R1"));
    assertThat(texts(h.item("200").path("restrictions").path("item"), "CTL_NO")).containsExactly("R4");
  }

  // --- DC stock, costs, item-location ---

  @Test
  void deletingAndReaddingLocationProfileUpdatesDcStockAndItemLocation() {
    item("100", "AB", "G1");
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC1", "STOREROOM_NO", "1", "QTY_ON_HAND", 5));
    assertThat(h.item("100").path("dcStock")).hasSize(1);
    assertThat(h.itemLocation("100", "DC1").path("location").path("MI_LOC").asText()).isEqualTo("DC1");
    h.delete(LOCATION_PROFILE, row("MI_LOC", "DC1"));
    assertThat(h.item("100").path("dcStock")).isEmpty();
    assertThat(h.itemLocation("100", "DC1").path("location").isNull()).isTrue();
    assertThat(h.itemLocation("100", "DC1").path("balances")).hasSize(1);
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O", "NAME", "back"));
    assertThat(h.item("100").path("dcStock")).hasSize(1);
    assertThat(h.item("100").path("dcStock").get(0).path("location").path("NAME").asText()).isEqualTo("back");
    assertThat(h.itemLocation("100", "DC1").path("location").path("NAME").asText()).isEqualTo("back");
  }

  @Test
  void dcStockFollowsBalanceDeletesAndQuantityChanges() {
    item("100", "AB", "G1");
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC2", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC1", "STOREROOM_NO", "1", "QTY_ON_HAND", 5));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC2", "STOREROOM_NO", "1", "QTY_ON_HAND", 6));
    assertThat(h.item("100").path("dcStock")).hasSize(2);
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC1", "STOREROOM_NO", "1", "QTY_ON_HAND", 50));
    assertThat(h.item("100").path("dcStock").get(0).path("balance").path("QTY_ON_HAND").asInt()).isEqualTo(50);
    h.delete(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC1", "STOREROOM_NO", "1"));
    assertThat(h.item("100").path("dcStock")).hasSize(1);
    assertThat(h.item("100").path("dcStock").get(0).path("balance").path("MI_LOC").asText()).isEqualTo("DC2");
    h.delete(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC2", "STOREROOM_NO", "1"));
    assertThat(h.item("100").path("dcStock")).isEmpty();
  }

  @Test
  void deletingAndReaddingItemCost() {
    item("100", "AB", "G1");
    h.upsert(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "01", "COST", 1.5));
    h.upsert(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "02", "COST", 2.5));
    assertThat(texts(h.item("100").path("costs"), "CORP_MI_LOC")).containsExactly("01", "02");
    h.delete(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "01"));
    assertThat(texts(h.item("100").path("costs"), "CORP_MI_LOC")).containsExactly("02");
    h.delete(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "02"));
    assertThat(h.item("100").path("costs")).isEmpty();
    h.upsert(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "01", "COST", 3.5));
    assertThat(h.item("100").path("costs").get(0).path("COST").decimalValue()).isEqualByComparingTo("3.5");
  }

  @Test
  void locationArrivingAfterBalancesCompletesDcStockAndItemLocation() {
    item("100", "AB", "G1");
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC1", "STOREROOM_NO", "1", "QTY_ON_HAND", 5));
    assertThat(h.item("100").path("dcStock")).isEmpty();
    assertThat(h.itemLocation("100", "DC1").path("location").isNull()).isTrue();
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1 ", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    assertThat(h.item("100").path("dcStock")).hasSize(1);
    assertThat(h.itemLocation("100", "DC1").path("location").path("LOCATION_TYPE").asText()).isEqualTo("W");
  }

  @Test
  void itemLocationExistsForEachSourceAloneAndTombstonesWhenItGoes() {
    h.upsert(NON_COS_ITEM_BALANCE, row("MI_LOC", "L1", "ITEM_NO", "100", "QTY", 1));
    assertThat(h.itemLocation("100", "L1").path("nonCosBalance").path("QTY").asInt()).isEqualTo(1);
    assertThat(h.itemLocation("100", "L1").path("balances")).isEmpty();
    h.delete(NON_COS_ITEM_BALANCE, row("MI_LOC", "L1", "ITEM_NO", "100"));
    assertThat(h.itemLocation("100", "L1")).isNull();
    h.upsert(LOCAL_COST, row("MI_LOC", "L2", "ITEM_NO", "100", "EFFECTIVE_DATE", "2026-01-01", "EXPIRATION_DATE", "2026-12-31"));
    assertThat(h.itemLocation("100", "L2").path("localCosts")).hasSize(1);
    h.delete(LOCAL_COST, row("MI_LOC", "L2", "ITEM_NO", "100", "EFFECTIVE_DATE", "2026-01-01", "EXPIRATION_DATE", "2026-12-31"));
    assertThat(h.itemLocation("100", "L2")).isNull();
    h.upsert(NON_COS_ITEM_BALANCE, row("MI_LOC", "L1", "ITEM_NO", "100", "QTY", 2));
    assertThat(h.itemLocation("100", "L1").path("nonCosBalance").path("QTY").asInt()).isEqualTo(2);
  }

  @Test
  void itemLocationRepublishedWhenIdenticalRowReturnsAfterDelete() {
    h.upsert(NON_COS_ITEM_BALANCE, row("MI_LOC", "L1", "ITEM_NO", "100", "QTY", 1));
    h.newRecords(itemLocationTopic());
    h.delete(NON_COS_ITEM_BALANCE, row("MI_LOC", "L1", "ITEM_NO", "100"));
    h.upsert(NON_COS_ITEM_BALANCE, row("MI_LOC", "L1", "ITEM_NO", "100", "QTY", 1));
    List<TestRecord<String, byte[]>> records = h.newRecords(itemLocationTopic());
    assertThat(records).hasSize(2);
    assertThat(records.get(0).value()).isNull();
    assertThat(records.get(1).value()).isNotNull();
  }

  // --- STEP side ---

  @Test
  void deletingAndReaddingStepUnitClearsAndRestoresTheUnit() {
    item("100", "AB", "G1");
    h.upsert(STEP_UNIT, row("STEP_UNIT_ID", "LB", "UNIT_NAME", "pound"));
    stepValue("P1", itemAttr, " ", "100");
    stepValue("P1", weightAttr, "LB", "2.5");
    h.delete(STEP_UNIT, row("STEP_UNIT_ID", "LB"));
    JsonNode weight = h.item("100").path("stepProducts").get(0).path("attributes").path("SHIPPING_WEIGHT").get(0);
    assertThat(weight.path("value").asText()).isEqualTo("2.5");
    assertThat(weight.path("stepUnitId").asText()).isEqualTo("LB");
    assertThat(weight.path("unit").isNull()).isTrue();
    h.upsert(STEP_UNIT, row("STEP_UNIT_ID", "LB", "UNIT_NAME", "lb"));
    weight = h.item("100").path("stepProducts").get(0).path("attributes").path("SHIPPING_WEIGHT").get(0);
    assertThat(weight.path("unit").path("UNIT_NAME").asText()).isEqualTo("lb");
  }

  @Test
  void deletingAndReaddingStepProductRowKeepsAttributes() {
    item("100", "AB", "G1");
    h.upsert(STEP_PRODUCT, row("STEP_PRODUCT_ID", "P1", "NAME", "one"));
    stepValue("P1", itemAttr, " ", "100");
    stepValue("P1", descAttr, " ", "desc");
    h.delete(STEP_PRODUCT, row("STEP_PRODUCT_ID", "P1"));
    JsonNode product = h.item("100").path("stepProducts").get(0);
    assertThat(product.path("product").isNull()).isTrue();
    assertThat(product.path("attributes").path("SHORT_DESC").get(0).path("value").asText()).isEqualTo("desc");
    h.upsert(STEP_PRODUCT, row("STEP_PRODUCT_ID", "P1", "NAME", "one again"));
    assertThat(h.item("100").path("stepProducts").get(0).path("product").path("NAME").asText()).isEqualTo("one again");
  }

  @Test
  void stepProductDisappearsWhenAllItsValuesAreDeletedAndReappearsWhenReadded() {
    item("100", "AB", "G1");
    h.upsert(STEP_PRODUCT, row("STEP_PRODUCT_ID", "P1", "NAME", "one"));
    stepValue("P1", itemAttr, " ", "100");
    stepValue("P1", descAttr, " ", "desc");
    deleteStepValue("P1", descAttr, " ", "desc");
    deleteStepValue("P1", itemAttr, " ", "100");
    assertThat(h.item("100").path("stepProducts")).isEmpty();
    stepValue("P1", itemAttr, " ", "100");
    JsonNode product = h.item("100").path("stepProducts").get(0);
    assertThat(product.path("product").path("NAME").asText()).isEqualTo("one");
    assertThat(product.path("attributes").has("SHORT_DESC")).isFalse();
  }

  @Test
  void multipleStepProductsPerItem() {
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    stepValue("P2", itemAttr, " ", "100 ");
    stepValue("P3", itemAttr, " ", "100");
    stepValue("P2", descAttr, " ", "two");
    assertThat(texts(h.item("100").path("stepProducts"), "stepProductId")).containsExactly("P1", "P2", "P3");
    assertThat(h.item("100").path("stepProducts").get(1).path("attributes").path("SHORT_DESC").get(0).path("value").asText()).isEqualTo("two");
    deleteStepValue("P2", itemAttr, " ", "100 ");
    assertThat(texts(h.item("100").path("stepProducts"), "stepProductId")).containsExactly("P1", "P3");
    h.delete(STEP_PRODUCT, row("STEP_PRODUCT_ID", "P1"));
    assertThat(texts(h.item("100").path("stepProducts"), "stepProductId")).containsExactly("P1", "P3");
  }

  @Test
  void stepProductWaitingForItsItemAppearsWhenTheItemArrives() {
    stepValue("P1", itemAttr, " ", "100");
    h.upsert(STEP_PRODUCT, row("STEP_PRODUCT_ID", "P1", "NAME", "one"));
    assertThat(h.item("100")).isNull();
    item("100", "AB", "G1");
    assertThat(texts(h.item("100").path("stepProducts"), "stepProductId")).containsExactly("P1");
  }

  @Test
  void stepChangesWhileTheItemIsAbsentAreReflectedWhenItReturns() {
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    h.delete(ITEM_PROFILE, row("ITEM_NO", "100"));
    stepValue("P2", itemAttr, " ", "100");
    deleteStepValue("P1", itemAttr, " ", "100");
    h.upsert(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "01", "COST", 1));
    assertThat(h.item("100")).isNull();
    item("100", "AB", "G1");
    assertThat(texts(h.item("100").path("stepProducts"), "stepProductId")).containsExactly("P2");
    assertThat(h.item("100").path("costs")).hasSize(1);
  }

  // --- classification hierarchy ---

  @Test
  void deletingAMiddleClassificationNodeTruncatesDescendantPathsAndReaddRestoresThem() {
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C1", "PARENT_STEP_CLASSIFICATION_ID", "Motion", "NAME", "Power"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C2", "PARENT_STEP_CLASSIFICATION_ID", "C1", "NAME", "Bearings"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C3", "PARENT_STEP_CLASSIFICATION_ID", "C2", "NAME", "Ball"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C4", "PARENT_STEP_CLASSIFICATION_ID", "C3", "NAME", "Deep groove"));
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C4"));
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C2"));
    JsonNode links = h.item("100").path("stepProducts").get(0).path("classifications");
    assertThat(texts(links, "stepClassificationId")).containsExactly("C2", "C4");
    assertThat(texts(links.get(1).path("path"), "NAME")).containsExactly("Power", "Bearings", "Ball", "Deep groove");
    h.delete(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C2"));
    links = h.item("100").path("stepProducts").get(0).path("classifications");
    assertThat(links.get(0).path("inWebHierarchy").asBoolean()).isFalse();
    assertThat(links.get(0).path("path")).isEmpty();
    assertThat(links.get(1).path("inWebHierarchy").asBoolean()).isFalse();
    assertThat(texts(links.get(1).path("path"), "NAME")).containsExactly("Ball", "Deep groove");
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C2", "PARENT_STEP_CLASSIFICATION_ID", "C1", "NAME", "Bearings 2"));
    links = h.item("100").path("stepProducts").get(0).path("classifications");
    assertThat(links.get(0).path("inWebHierarchy").asBoolean()).isTrue();
    assertThat(texts(links.get(0).path("path"), "NAME")).containsExactly("Power", "Bearings 2");
    assertThat(links.get(1).path("inWebHierarchy").asBoolean()).isTrue();
    assertThat(texts(links.get(1).path("path"), "NAME")).containsExactly("Power", "Bearings 2", "Ball", "Deep groove");
  }

  @Test
  void productClassificationLinkDeletedAndReadded() {
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C1", "PARENT_STEP_CLASSIFICATION_ID", "Motion"));
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C1"));
    h.delete(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C1"));
    assertThat(h.item("100").path("stepProducts").get(0).path("classifications")).isEmpty();
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C1"));
    assertThat(h.item("100").path("stepProducts").get(0).path("classifications").get(0).path("inWebHierarchy").asBoolean()).isTrue();
  }

  @Test
  void twoProductsLinkedToOneClassificationBothFollowItsRename() {
    item("100", "AB", "G1");
    item("200", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    stepValue("P2", itemAttr, " ", "200");
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C1", "PARENT_STEP_CLASSIFICATION_ID", "Motion", "NAME", "a"));
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C1"));
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P2", "STEP_CLASSIFICATION_ID", "C1"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C1", "PARENT_STEP_CLASSIFICATION_ID", "Motion", "NAME", "b"));
    for (String itemNo : List.of("100", "200")) {
      JsonNode link = h.item(itemNo).path("stepProducts").get(0).path("classifications").get(0);
      assertThat(texts(link.path("path"), "NAME")).containsExactly("b");
    }
  }

  // --- item lifecycle and no-op suppression ---

  @Test
  void itemDeletedThenRecreatedGetsEveryJoinBackAndIsRepublished() {
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N1", "MFR_NAME", "SKF"));
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1"));
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC1", "STOREROOM_NO", "1", "QTY_ON_HAND", 5));
    h.upsert(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "01", "COST", 1.5));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R1", "ITEM_NO", "100", "MFR_CTL_NO", " ", "PROD_GROUP_NO", " "));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R2", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", " "));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R3", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", "G1"));
    stepValue("P1", itemAttr, " ", "100");
    item("100", "AB", "G1");
    JsonNode before = h.item("100");
    h.newRecords(itemTopic());
    h.delete(ITEM_PROFILE, row("ITEM_NO", "100"));
    List<TestRecord<String, byte[]>> deleted = h.newRecords(itemTopic());
    assertThat(deleted).hasSize(1);
    assertThat(deleted.get(0).value()).isNull();
    assertThat(h.item("100")).isNull();
    item("100", "AB", "G1");
    List<TestRecord<String, byte[]>> recreated = h.newRecords(itemTopic());
    assertThat(recreated).isNotEmpty();
    assertThat(parse(recreated.get(recreated.size() - 1).value())).isEqualTo(before);
  }

  @Test
  void itemRepublishedWhenIdenticalRowReturnsAfterDelete() {
    item("100", "AB", "G1");
    h.newRecords(itemTopic());
    h.delete(ITEM_PROFILE, row("ITEM_NO", "100"));
    item("100", "AB", "G1");
    List<TestRecord<String, byte[]>> records = h.newRecords(itemTopic());
    assertThat(records).hasSize(2);
    assertThat(records.get(0).value()).isNull();
    assertThat(records.get(1).value()).isNotNull();
  }

  @Test
  void deleteForAnUnknownKeyPublishesNothing() {
    h.delete(ITEM_PROFILE, row("ITEM_NO", "nope"));
    h.delete(MFR_NAME, row("MFR_NAME_ID", "nope"));
    h.delete(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "nope"));
    h.delete(ITEM_BALANCE, row("ITEM_NO", "1", "MI_LOC", "2", "STOREROOM_NO", "3"));
    assertThat(h.newRecords(itemTopic())).isEmpty();
    assertThat(h.newRecords(itemLocationTopic())).isEmpty();
  }

  @Test
  void unrelatedChangesPublishNothing() {
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1"));
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    h.newRecords(itemTopic());
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "ZZ", "MFR_NAME_ID", "N1"));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "RX", "ITEM_NO", "999", "MFR_CTL_NO", " ", "PROD_GROUP_NO", " "));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "RY", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", "OTHER"));
    stepValue("P1", "UNCONFIGURED", " ", "x");
    h.upsert(STEP_UNIT, row("STEP_UNIT_ID", "KG"));
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    assertThat(h.newRecords(itemTopic())).isEmpty();
  }

  // --- message formats end to end ---

  @Test
  void jsonEnvelopeUpsertsAndDeletesFlowThroughTheTopology() {
    h.raw(MFR_PROFILE, "{\"MFR_CTL_NO\":\"AB\"}",
        "{\"op\":\"I\",\"before\":null,\"after\":{\"mfr_ctl_no\":{\"string\":\"AB\"},\"mfr_name_id\":{\"string\":\"N1\"},\"last_event_at\":\"x\"},\"ts_ms\":1}");
    h.raw(MFR_NAME, "{\"MFR_NAME_ID\":\"N1\"}",
        "{\"op\":\"I\",\"after\":{\"MFR_NAME_ID\":\"N1\",\"MFR_NAME\":\"SKF\\u0000\"},\"ts_ms\":1}");
    h.raw(ITEM_PROFILE, "{\"ITEM_NO\":\"100\"}",
        "{\"op\":\"U\",\"before\":{\"ITEM_NO\":\"100\"},\"after\":{\"ITEM_NO\":\"100\",\"MFR_CTL_NO\":\"AB\",\"LAST_EVENT_AT\":\"2026\"},\"ts_ms\":2}");
    JsonNode doc = h.item("100");
    assertThat(doc.path("item").has("LAST_EVENT_AT")).isFalse();
    assertThat(doc.path("item").has("OP")).isFalse();
    assertThat(doc.path("manufacturer").path("profile").has("LAST_EVENT_AT")).isFalse();
    assertThat(doc.path("manufacturer").path("name").path("MFR_NAME").asText()).isEqualTo("SKF");
    h.raw(MFR_NAME, null, "{\"op\":\"D\",\"before\":{\"MFR_NAME_ID\":\"N1\"},\"after\":null,\"ts_ms\":3}");
    assertThat(h.item("100").path("manufacturer").path("name").isNull()).isTrue();
    h.raw(ITEM_PROFILE, "{\"ITEM_NO\":\"100\"}",
        "{\"op\":\"D\",\"before\":{\"ITEM_NO\":\"100\",\"MFR_CTL_NO\":\"AB\"},\"after\":null,\"ts_ms\":4}");
    assertThat(h.item("100")).isNull();
  }

  @Test
  void jsonEnvelopeDeleteWithoutBeforeImageDeletesByMessageKey() {
    item("100", "AB", "G1");
    h.raw(ITEM_PROFILE, "{\"ITEM_NO\":\"100\"}", "{\"op\":\"D\",\"before\":null,\"after\":null,\"ts_ms\":4}");
    assertThat(h.item("100")).isNull();
  }

  @Test
  void avroEnvelopeUpsertsAndDeletesFlowThroughTheTopology() {
    Map<String, Object> mfr = new LinkedHashMap<>();
    mfr.put("mfr_ctl_no", "AB");
    mfr.put("mfr_name_id", "N1");
    mfr.put("sellable", "Y");
    mfr.put("LAST_EVENT_AT", "2026-01-01");
    h.raw(MFR_PROFILE, null, avro("I", null, mfr, false));
    Map<String, Object> item = new LinkedHashMap<>();
    item.put("ITEM_NO", "100  ");
    item.put("MFR_CTL_NO", "AB");
    item.put("QTY", 5L);
    item.put("WEIGHT", 2.5d);
    h.raw(ITEM_PROFILE, utf8("{\"ITEM_NO\":\"100\"}"), avro("U", null, item, true));
    Map<String, Object> cost = new LinkedHashMap<>();
    cost.put("ITEM_NO", "100");
    cost.put("CORP_MI_LOC", "01");
    cost.put("COST", "1.50");
    h.raw(ITEM_COST, keyOf(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "01")), avro("I", null, cost, true));
    JsonNode doc = h.item("100");
    assertThat(doc).isNotNull();
    assertThat(doc.path("item").path("QTY").asInt()).isEqualTo(5);
    assertThat(doc.path("item").path("WEIGHT").decimalValue()).isEqualByComparingTo("2.5");
    assertThat(doc.path("manufacturer").path("profile").path("SELLABLE").asText()).isEqualTo("Y");
    assertThat(doc.path("manufacturer").path("profile").has("LAST_EVENT_AT")).isFalse();
    assertThat(doc.path("costs")).hasSize(1);
    Map<String, Object> mfrKey = new LinkedHashMap<>();
    mfrKey.put("MFR_CTL_NO", "AB");
    h.raw(MFR_PROFILE, null, avro("D", mfrKey, null, false));
    assertThat(h.item("100").path("manufacturer").isNull()).isTrue();
    h.raw(ITEM_COST, keyOf(ITEM_COST, row("ITEM_NO", "100", "CORP_MI_LOC", "01")), avro("D", null, null, true));
    assertThat(h.item("100").path("costs")).isEmpty();
    h.raw(ITEM_PROFILE, utf8("{\"ITEM_NO\":\"100\"}"), avro("D", null, null, false));
    assertThat(h.item("100")).isNull();
  }

  @Test
  void tombstoneVariantsDeleteThroughTheTopology() {
    item("100", "AB", "G1");
    item("200", "AB", "G1");
    item("300", "AB", "G1");
    h.raw(ITEM_PROFILE, "{\"ITEM_NO\":\"100\"}", "");
    h.raw(ITEM_PROFILE, "{\"ITEM_NO\":\"200\"}", "null");
    h.raw(ITEM_PROFILE, "\"300\"", null);
    assertThat(h.item("100")).isNull();
    assertThat(h.item("200")).isNull();
    assertThat(h.item("300")).isNull();
  }
}
