package com.motion.catalogjoin.model;

import com.fasterxml.jackson.core.type.TypeReference;
import com.motion.catalogjoin.Json;
import java.util.Map;
import org.apache.kafka.common.serialization.Serde;

/** JSON serdes for every value type kept in state or written to internal topics. */
public final class ModelSerdes {

  public static final Serde<Map<String, Object>> ROW = Json.serde(new TypeReference<>() {});
  public static final Serde<StepValue> STEP_VALUE = Json.serde(StepValue.class);
  public static final Serde<Group<StepValue>> STEP_VALUES = Json.serde(new TypeReference<>() {});
  public static final Serde<ClassPath> CLASS_PATH = Json.serde(ClassPath.class);
  public static final Serde<StepClassification> STEP_CLASSIFICATION = Json.serde(StepClassification.class);
  public static final Serde<Group<StepClassification>> STEP_CLASSIFICATIONS = Json.serde(new TypeReference<>() {});
  public static final Serde<StepProduct> STEP_PRODUCT = Json.serde(StepProduct.class);
  public static final Serde<Group<StepProduct>> STEP_PRODUCTS = Json.serde(new TypeReference<>() {});
  public static final Serde<Manufacturer> MANUFACTURER = Json.serde(Manufacturer.class);
  public static final Serde<LocatedBalance> LOCATED_BALANCE = Json.serde(LocatedBalance.class);
  public static final Serde<Group<LocatedBalance>> LOCATED_BALANCES = Json.serde(new TypeReference<>() {});
  public static final Serde<Group<Map<String, Object>>> ROWS = Json.serde(new TypeReference<>() {});
  public static final Serde<ItemLocationDoc> ITEM_LOCATION_DOC = Json.serde(ItemLocationDoc.class);

  private ModelSerdes() {}
}
