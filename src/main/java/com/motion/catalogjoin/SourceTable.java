package com.motion.catalogjoin;

import java.util.List;
import java.util.Locale;

/**
 * The CDC source tables. The key columns are the table's primary key, which is also the Kafka
 * message key and partition key on the source topic.
 */
public enum SourceTable {
  STEP_PRODUCT_VALUES("FSDB", "STEP_PRODUCT_ID", "STEP_ATTRIBUTE_ID", "STEP_UNIT_ID", "VALUE"),
  STEP_UNIT("FSDB", "STEP_UNIT_ID"),
  STEP_PRODUCT("FSDB", "STEP_PRODUCT_ID"),
  STEP_PRODUCT_CLASSIFICATION("FSDB", "STEP_PRODUCT_ID", "STEP_CLASSIFICATION_ID"),
  STEP_CLASSIFICATION("FSDB", "STEP_CLASSIFICATION_ID"),
  ITEM_PROFILE("BROP", "ITEM_NO"),
  MFR_PROFILE("BROP", "MFR_CTL_NO"),
  ITEM_BALANCE("BROP", "ITEM_NO", "MI_LOC", "STOREROOM_NO"),
  LOCATION_PROFILE("BROP", "MI_LOC"),
  ITEM_COST("BROP", "ITEM_NO", "CORP_MI_LOC"),
  NON_COS_ITEM_BALANCE("BROP", "MI_LOC", "ITEM_NO"),
  LOCAL_COST("BROP", "MI_LOC", "ITEM_NO", "EFFECTIVE_DATE", "EXPIRATION_DATE"),
  ITEM_RESTRICT_RULE("BRANCH", "CTL_NO"),
  MFR_NAME("MISEARCH", "MFR_NAME_ID"),
  ITEM_PRICE_CACHE("ITEM", "ITEM_NO", "MI_LOC", "CUSTOMER_NO");

  private final String schema;
  private final List<String> keyColumns;

  SourceTable(String schema, String... keyColumns) {
    this.schema = schema;
    this.keyColumns = List.of(keyColumns);
  }

  public String schema() {
    return schema;
  }

  public List<String> keyColumns() {
    return keyColumns;
  }

  /** {@code BROP.ITEM_PROFILE} */
  public String qualifiedName() {
    return schema + "." + name();
  }

  /** {@code topic.brop.item_profile-json} */
  public String defaultTopic() {
    return "topic." + schema.toLowerCase(Locale.ROOT) + "." + name().toLowerCase(Locale.ROOT) + "-json";
  }

  /** Short lower-case name used in internal topic and store names, e.g. {@code item_profile}. */
  public String slug() {
    return name().toLowerCase(Locale.ROOT);
  }
}
