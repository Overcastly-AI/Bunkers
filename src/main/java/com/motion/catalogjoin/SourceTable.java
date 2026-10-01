package com.motion.catalogjoin;

import java.util.Locale;

/**
 * The CDC source tables. Only the identity lives here; each table's topic and key columns come
 * from configuration ({@code catalog.source.<slug>.topic} / {@code .key}).
 */
public enum SourceTable {
  STEP_PRODUCT_VALUES,
  STEP_UNIT,
  STEP_PRODUCT,
  STEP_PRODUCT_CLASSIFICATION,
  STEP_CLASSIFICATION,
  ITEM_PROFILE,
  MFR_PROFILE,
  ITEM_BALANCE,
  LOCATION_PROFILE,
  ITEM_COST,
  NON_COS_ITEM_BALANCE,
  LOCAL_COST,
  ITEM_RESTRICT_RULE,
  MFR_NAME,
  ITEM_PRICE_CACHE;

  /** Lower-case name used in configuration keys and internal topic/store names, e.g. {@code item_profile}. */
  public String slug() {
    return name().toLowerCase(Locale.ROOT);
  }
}
