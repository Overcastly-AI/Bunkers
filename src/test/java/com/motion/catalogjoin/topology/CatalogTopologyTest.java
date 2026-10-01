package com.motion.catalogjoin.topology;

import static com.motion.catalogjoin.SourceTable.ITEM_BALANCE;
import static com.motion.catalogjoin.SourceTable.ITEM_COST;
import static com.motion.catalogjoin.SourceTable.ITEM_PRICE_CACHE;
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
import com.motion.catalogjoin.ingest.Sources;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.apache.kafka.streams.test.TestRecord;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class CatalogTopologyTest {

  private final Harness h = new Harness();
  private final String itemAttr = h.attribute("ITEM_NUMBER");
  private final String weightAttr = h.attribute("SHIPPING_WEIGHT");
  private final String descAttr = h.attribute("SHORT_DESC");

  @AfterEach
  void close() {
    h.close();
  }

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

  // --- item root and manufacturer chain -----------------------------------------------------------

  @Test
  void itemDocumentCarriesManufacturerChainAndFollowsNameChanges() {
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N1", "MFR_NAME", "SKF"));
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1", "SELLABLE", "Y"));
    item("100", "AB", "G1");

    JsonNode doc = h.item("100");
    assertThat(doc.path("itemNo").asText()).isEqualTo("100");
    assertThat(doc.path("item").path("DESCR").asText()).isEqualTo("Bearing 100");
    assertThat(doc.path("manufacturer").path("profile").path("SELLABLE").asText()).isEqualTo("Y");
    assertThat(doc.path("manufacturer").path("name").path("MFR_NAME").asText()).isEqualTo("SKF");

    // A change two hops away (MFR_NAME) reaches the item document.
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "N1", "MFR_NAME", "SKF USA"));
    assertThat(h.item("100").path("manufacturer").path("name").path("MFR_NAME").asText()).isEqualTo("SKF USA");

    // Repointing the item at another manufacturer.
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "CD", "MFR_NAME_ID", "N2", "SELLABLE", "N"));
    item("100", "CD", "G1");
    JsonNode repointed = h.item("100");
    assertThat(repointed.path("manufacturer").path("profile").path("MFR_CTL_NO").asText()).isEqualTo("CD");
    assertThat(repointed.path("manufacturer").path("name").isNull()).isTrue();
  }

  @Test
  void itemArrivingBeforeItsManufacturerIsCompletedLater() {
    item("100", "AB", "G1");
    assertThat(h.item("100").path("manufacturer").isNull()).isTrue();
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1"));
    assertThat(h.item("100").path("manufacturer").path("profile").path("MFR_CTL_NO").asText()).isEqualTo("AB");
  }

  @Test
  void deletingTheItemPublishesATombstoneAndNoOpUpdatesAreSuppressed() {
    item("100", "AB", "G1");
    assertThat(h.newRecords(h.driver.config.itemTopic())).hasSize(1);

    item("100", "AB", "G1"); // identical row
    h.upsert(MFR_NAME, row("MFR_NAME_ID", "UNRELATED", "MFR_NAME", "x"));
    assertThat(h.newRecords(h.driver.config.itemTopic())).isEmpty();

    h.delete(ITEM_PROFILE, row("ITEM_NO", "100"));
    List<TestRecord<String, byte[]>> records = h.newRecords(h.driver.config.itemTopic());
    assertThat(records).hasSize(1);
    assertThat(records.get(0).key()).isEqualTo("{\"ITEM_NO\":\"100\"}");
    assertThat(records.get(0).value()).isNull();
  }

  @Test
  void keysMatchAcrossPaddingAndNumberFormatting() {
    h.raw(ITEM_PROFILE, "{\"ITEM_NO\":\"123   \"}", "{\"ITEM_NO\":\"123   \",\"MFR_CTL_NO\":\"AB  \"}");
    h.raw(ITEM_COST, "{\"CORP_MI_LOC\":\"01\",\"ITEM_NO\":123}", "{\"ITEM_NO\":123,\"CORP_MI_LOC\":\"01\",\"COST\":1.50}");
    h.raw(MFR_PROFILE, "{\"MFR_CTL_NO\":\"AB\"}", "{\"MFR_CTL_NO\":\"AB\",\"MFR_NAME_ID\":\"N1\"}");

    JsonNode doc = h.item("123");
    assertThat(doc.path("costs")).hasSize(1);
    assertThat(doc.path("costs").get(0).path("COST").decimalValue()).isEqualByComparingTo("1.50");
    assertThat(doc.path("manufacturer").path("profile").path("MFR_CTL_NO").asText()).isEqualTo("AB");
  }

  // --- restriction rules (the old 3-way UNION) --------------------------------------------------

  @Test
  void restrictionRulesMatchByItemManufacturerAndManufacturerProductGroup() {
    item("100", "AB", "G1");
    item("200", "AB", "G2");
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R1", "ITEM_NO", "100", "MFR_CTL_NO", " ", "PROD_GROUP_NO", " "));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R2", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", " "));
    h.upsert(ITEM_RESTRICT_RULE, row("CTL_NO", "R3", "ITEM_NO", " ", "MFR_CTL_NO", "AB", "PROD_GROUP_NO", "G1"));

    JsonNode r100 = h.item("100").path("restrictions");
    assertThat(texts(r100.path("item"), "CTL_NO")).containsExactly("R1");
    assertThat(texts(r100.path("manufacturer"), "CTL_NO")).containsExactly("R2");
    assertThat(texts(r100.path("manufacturerProductGroup"), "CTL_NO")).containsExactly("R3");

    JsonNode r200 = h.item("200").path("restrictions");
    assertThat(r200.path("item")).isEmpty();
    assertThat(texts(r200.path("manufacturer"), "CTL_NO")).containsExactly("R2");
    assertThat(r200.path("manufacturerProductGroup")).isEmpty();

    // Moving item 200 into group G1 picks up R3; deleting R2 removes it from both items.
    item("200", "AB", "G1");
    h.delete(ITEM_RESTRICT_RULE, row("CTL_NO", "R2"));
    assertThat(texts(h.item("200").path("restrictions").path("manufacturerProductGroup"), "CTL_NO")).containsExactly("R3");
    assertThat(h.item("200").path("restrictions").path("manufacturer")).isEmpty();
    assertThat(h.item("100").path("restrictions").path("manufacturer")).isEmpty();
  }

  // --- DC stock --------------------------------------------------------------------------------

  @Test
  void dcStockIncludesOnlyOpenWarehousesAndFollowsLocationChanges() {
    item("100", "AB", "G1");
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "BR1", "LOCATION_TYPE", "B", "OPEN_CLOSED", "O"));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC1", "STOREROOM_NO", "1", "QTY_ON_HAND", 5));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "BR1", "STOREROOM_NO", "1", "QTY_ON_HAND", 7));

    JsonNode dcStock = h.item("100").path("dcStock");
    assertThat(dcStock).hasSize(1);
    assertThat(dcStock.get(0).path("balance").path("MI_LOC").asText()).isEqualTo("DC1");
    assertThat(dcStock.get(0).path("location").path("LOCATION_TYPE").asText()).isEqualTo("W");

    // The DC closes: its balance drops out without any balance change.
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "C"));
    assertThat(h.item("100").path("dcStock")).isEmpty();

    // BR1 becomes a warehouse: its balance joins in.
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "BR1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    assertThat(texts(h.item("100").path("dcStock"), "balance")).hasSize(1);
    assertThat(h.item("100").path("dcStock").get(0).path("balance").path("QTY_ON_HAND").asInt()).isEqualTo(7);
  }

  @Test
  void itemsOfUnsellableManufacturersGetNoDcStock() {
    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1", "SELLABLE", "Y"));
    item("100", "AB", "G1");
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "DC1", "LOCATION_TYPE", "W", "OPEN_CLOSED", "O"));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "DC1", "STOREROOM_NO", "1", "QTY_ON_HAND", 5));
    assertThat(h.item("100").path("dcStock")).hasSize(1);

    h.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "MFR_NAME_ID", "N1", "SELLABLE", "N"));
    assertThat(h.item("100").path("dcStock")).isEmpty();
  }

  @Test
  void dcStockCodesComeFromConfiguration() {
    try (Harness custom = new Harness(Map.of("catalog.dc-stock.location-types", "DC,W", "catalog.dc-stock.exclude-sellable", ""))) {
      custom.upsert(ITEM_PROFILE, row("ITEM_NO", "100", "MFR_CTL_NO", "AB"));
      custom.upsert(MFR_PROFILE, row("MFR_CTL_NO", "AB", "SELLABLE", "N"));
      custom.upsert(LOCATION_PROFILE, row("MI_LOC", "X1", "LOCATION_TYPE", "DC", "OPEN_CLOSED", "O"));
      custom.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "X1", "STOREROOM_NO", "1"));
      assertThat(custom.item("100").path("dcStock")).hasSize(1);
    }
  }

  // --- STEP side and the ITEM_NUMBER bridge -------------------------------------------------

  @Test
  void stepProductBridgesToItemAndUnitChangesPropagate() {
    item("100", "AB", "G1");
    h.upsert(STEP_UNIT, row("STEP_UNIT_ID", "LB", "UNIT_NAME", "pound"));
    h.upsert(STEP_PRODUCT, row("STEP_PRODUCT_ID", "P1", "NAME", "Product one"));
    stepValue("P1", itemAttr, " ", "100");
    stepValue("P1", weightAttr, "LB", "2.5");
    stepValue("P1", "UNCONFIGURED", " ", "ignored");

    JsonNode products = h.item("100").path("stepProducts");
    assertThat(products).hasSize(1);
    JsonNode product = products.get(0);
    assertThat(product.path("stepProductId").asText()).isEqualTo("P1");
    assertThat(product.path("product").path("NAME").asText()).isEqualTo("Product one");
    assertThat(product.path("attributes").path("ITEM_NUMBER").get(0).path("value").asText()).isEqualTo("100");
    JsonNode weight = product.path("attributes").path("SHIPPING_WEIGHT").get(0);
    assertThat(weight.path("value").asText()).isEqualTo("2.5");
    assertThat(weight.path("unit").path("UNIT_NAME").asText()).isEqualTo("pound");
    assertThat(product.path("attributes").has("UNCONFIGURED")).isFalse();

    // The old design never refreshed on STEP_UNIT changes; here it does.
    h.upsert(STEP_UNIT, row("STEP_UNIT_ID", "LB", "UNIT_NAME", "lb"));
    assertThat(h.item("100").path("stepProducts").get(0).path("attributes").path("SHIPPING_WEIGHT").get(0)
            .path("unit").path("UNIT_NAME").asText())
        .isEqualTo("lb");
  }

  @Test
  void attributeEditConvergesWhicheverOrderTheDeleteAndInsertArrive() {
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    stepValue("P1", descAttr, " ", "old");

    // Insert of the new value first, then delete of the old one (different keys, any order).
    stepValue("P1", descAttr, " ", "new");
    deleteStepValue("P1", descAttr, " ", "old");
    assertThat(texts(h.item("100").path("stepProducts").get(0).path("attributes").path("SHORT_DESC"), "value"))
        .containsExactly("new");

    // Delete first, then insert.
    deleteStepValue("P1", descAttr, " ", "new");
    stepValue("P1", descAttr, " ", "newer");
    assertThat(texts(h.item("100").path("stepProducts").get(0).path("attributes").path("SHORT_DESC"), "value"))
        .containsExactly("newer");
  }

  @Test
  void changingTheItemNumberMovesTheProductBetweenItems() {
    item("100", "AB", "G1");
    item("200", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    assertThat(h.item("100").path("stepProducts")).hasSize(1);

    stepValue("P1", itemAttr, " ", "200");
    deleteStepValue("P1", itemAttr, " ", "100");
    assertThat(h.item("100").path("stepProducts")).isEmpty();
    assertThat(texts(h.item("200").path("stepProducts"), "stepProductId")).containsExactly("P1");

    deleteStepValue("P1", itemAttr, " ", "200");
    assertThat(h.item("200").path("stepProducts")).isEmpty();
  }

  @Test
  void classificationPathsFollowHierarchyChanges() {
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C3"));
    // Children arrive before parents.
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C3", "PARENT_STEP_CLASSIFICATION_ID", "C2", "NAME", "Ball"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C2", "PARENT_STEP_CLASSIFICATION_ID", "C1", "NAME", "Bearings"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C1", "PARENT_STEP_CLASSIFICATION_ID", "Motion", "NAME", "Power"));

    JsonNode link = h.item("100").path("stepProducts").get(0).path("classifications").get(0);
    assertThat(link.path("stepClassificationId").asText()).isEqualTo("C3");
    assertThat(link.path("inWebHierarchy").asBoolean()).isTrue();
    assertThat(texts(link.path("path"), "NAME")).containsExactly("Power", "Bearings", "Ball");

    // Renaming an ancestor rewrites the descendant's path.
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C1", "PARENT_STEP_CLASSIFICATION_ID", "Motion", "NAME", "Power Transmission"));
    link = h.item("100").path("stepProducts").get(0).path("classifications").get(0);
    assertThat(texts(link.path("path"), "NAME")).containsExactly("Power Transmission", "Bearings", "Ball");

    // Detaching the subtree from the root takes it out of the web hierarchy.
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C2", "PARENT_STEP_CLASSIFICATION_ID", "Elsewhere", "NAME", "Bearings"));
    link = h.item("100").path("stepProducts").get(0).path("classifications").get(0);
    assertThat(link.path("inWebHierarchy").asBoolean()).isFalse();
    assertThat(texts(link.path("path"), "NAME")).containsExactly("Bearings", "Ball");

    // Unlinking the product from the classification.
    h.delete(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C3"));
    assertThat(h.item("100").path("stepProducts").get(0).path("classifications")).isEmpty();
  }

  @Test
  void pathsStopAtTheRootEvenWhenTheRootRowExists() {
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "C1"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "Motion", "PARENT_STEP_CLASSIFICATION_ID", "ROOT", "NAME", "Motion"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "C1", "PARENT_STEP_CLASSIFICATION_ID", "Motion", "NAME", "Power"));
    JsonNode link = h.item("100").path("stepProducts").get(0).path("classifications").get(0);
    assertThat(link.path("inWebHierarchy").asBoolean()).isTrue();
    assertThat(texts(link.path("path"), "NAME")).containsExactly("Power");
  }

  @Test
  void classificationCycleDoesNotHang() {
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "X", "PARENT_STEP_CLASSIFICATION_ID", "Y"));
    h.upsert(STEP_CLASSIFICATION, row("STEP_CLASSIFICATION_ID", "Y", "PARENT_STEP_CLASSIFICATION_ID", "X"));
    item("100", "AB", "G1");
    stepValue("P1", itemAttr, " ", "100");
    h.upsert(STEP_PRODUCT_CLASSIFICATION, row("STEP_PRODUCT_ID", "P1", "STEP_CLASSIFICATION_ID", "X"));
    JsonNode link = h.item("100").path("stepProducts").get(0).path("classifications").get(0);
    assertThat(link.path("inWebHierarchy").asBoolean()).isFalse();
  }

  // --- catalog.item-location -------------------------------------------------------------------

  @Test
  void itemLocationDocumentCombinesSourcesAndDisappearsWithTheLastRow() {
    h.upsert(LOCATION_PROFILE, row("MI_LOC", "0042", "LOCATION_TYPE", "B", "OPEN_CLOSED", "O"));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "0042", "STOREROOM_NO", "1", "QTY_ON_HAND", 3));
    h.upsert(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "0042", "STOREROOM_NO", "2", "QTY_ON_HAND", 4));
    h.upsert(NON_COS_ITEM_BALANCE, row("MI_LOC", "0042", "ITEM_NO", "100", "QTY", 9));
    h.upsert(LOCAL_COST, row("MI_LOC", "0042", "ITEM_NO", "100", "EFFECTIVE_DATE", "2026-01-01", "EXPIRATION_DATE", "2026-12-31", "COST", 4.25));

    JsonNode doc = h.itemLocation("100", "0042");
    assertThat(doc.path("itemNo").asText()).isEqualTo("100");
    assertThat(doc.path("miLoc").asText()).isEqualTo("0042");
    assertThat(texts(doc.path("balances"), "STOREROOM_NO")).containsExactly("1", "2");
    assertThat(doc.path("nonCosBalance").path("QTY").asInt()).isEqualTo(9);
    assertThat(doc.path("localCosts")).hasSize(1);
    assertThat(doc.path("location").path("LOCATION_TYPE").asText()).isEqualTo("B");

    h.upsert(LOCATION_PROFILE, row("MI_LOC", "0042", "LOCATION_TYPE", "B", "OPEN_CLOSED", "C"));
    assertThat(h.itemLocation("100", "0042").path("location").path("OPEN_CLOSED").asText()).isEqualTo("C");

    h.delete(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "0042", "STOREROOM_NO", "1"));
    h.delete(ITEM_BALANCE, row("ITEM_NO", "100", "MI_LOC", "0042", "STOREROOM_NO", "2"));
    h.delete(NON_COS_ITEM_BALANCE, row("MI_LOC", "0042", "ITEM_NO", "100"));
    assertThat(h.itemLocation("100", "0042")).isNotNull();
    h.delete(LOCAL_COST, row("MI_LOC", "0042", "ITEM_NO", "100", "EFFECTIVE_DATE", "2026-01-01", "EXPIRATION_DATE", "2026-12-31"));
    assertThat(h.itemLocation("100", "0042")).isNull();
  }

  // --- catalog.item-price and dead letters --------------------------------------------------------

  @Test
  void pricesArePublishedNormalizedWithCanonicalKeys() {
    h.raw(ITEM_PRICE_CACHE,
        "{\"MI_LOC\":\"01\",\"ITEM_NO\":\"100\",\"CUSTOMER_NO\":\"C1 \"}",
        "{\"op\":\"U\",\"after\":{\"item_no\":{\"string\":\"100\"},\"mi_loc\":\"01\",\"customer_no\":\"C1 \",\"price\":12.5,\"last_event_at\":\"x\"}}");
    h.delete(ITEM_PRICE_CACHE, row("ITEM_NO", "100", "MI_LOC", "01", "CUSTOMER_NO", "C1"));

    List<TestRecord<String, byte[]>> records = h.newRecords(h.driver.config.itemPriceTopic());
    assertThat(records).hasSize(2);
    String key = "{\"CUSTOMER_NO\":\"C1\",\"ITEM_NO\":\"100\",\"MI_LOC\":\"01\"}";
    assertThat(records.get(0).key()).isEqualTo(key);
    JsonNode price = parse(records.get(0).value());
    assertThat(price.path("PRICE").decimalValue()).isEqualByComparingTo("12.5");
    assertThat(price.path("ITEM_NO").asText()).isEqualTo("100");
    assertThat(price.has("LAST_EVENT_AT")).isFalse();
    assertThat(records.get(1).key()).isEqualTo(key);
    assertThat(records.get(1).value()).isNull();
  }

  @Test
  void undecodableRecordsGoToTheDeadLetterTopicWithTheirOrigin() {
    h.raw(ITEM_PROFILE, "{\"ITEM_NO\":\"100\"}", "not json and not avro");
    h.raw(ITEM_PROFILE, null, "{\"DESCR\":\"no key anywhere\"}");
    item("200", "AB", "G1");

    List<TestRecord<byte[], byte[]>> dead = h.driver.deadLetters();
    assertThat(dead).hasSize(2);
    assertThat(new String(dead.get(0).value(), StandardCharsets.UTF_8)).isEqualTo("not json and not avro");
    assertThat(header(dead.get(0), Sources.HEADER_TOPIC)).isEqualTo(h.driver.config.topic(ITEM_PROFILE));
    assertThat(header(dead.get(0), Sources.HEADER_OFFSET)).isEqualTo("0");
    assertThat(header(dead.get(1), Sources.HEADER_ERROR)).contains("Missing key column ITEM_NO");
    assertThat(h.item("200")).isNotNull();
  }

  private static JsonNode parse(byte[] json) {
    try {
      return Json.MAPPER.readTree(json);
    } catch (java.io.IOException e) {
      throw new java.io.UncheckedIOException(e);
    }
  }

  private static String header(TestRecord<byte[], byte[]> record, String name) {
    return new String(record.headers().lastHeader(name).value(), StandardCharsets.UTF_8);
  }

  @Test
  void publishedDocumentsHaveTheDocumentedTopLevelShape() {
    item("100", "AB", "G1");
    JsonNode doc = h.item("100");
    List<String> fields = new ArrayList<>();
    doc.fieldNames().forEachRemaining(fields::add);
    assertThat(fields).containsExactly("costs", "dcStock", "item", "itemNo", "manufacturer", "restrictions", "stepProducts");
  }
}
