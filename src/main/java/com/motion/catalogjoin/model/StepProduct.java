package com.motion.catalogjoin.model;

import com.motion.catalogjoin.Rows;
import java.util.Map;
import java.util.Objects;

/** Everything known about one STEP product, keyed by STEP_PRODUCT_ID. */
public record StepProduct(
    String stepProductId,
    Map<String, Object> product,
    Group<StepValue> values,
    Group<StepClassification> classifications) {

  /**
   * The BROP item number this product bridges to: the configured item-number attribute's value.
   * When several values exist (briefly, during an edit) the smallest wins so the choice is stable.
   */
  public String itemNumber(String itemNumberAttributeId) {
    if (values == null) {
      return null;
    }
    return values.values().stream()
        .map(StepValue::value)
        .filter(row -> itemNumberAttributeId.equals(Rows.str(row, "STEP_ATTRIBUTE_ID")))
        .map(row -> Rows.str(row, "VALUE"))
        .filter(Objects::nonNull)
        .sorted()
        .findFirst()
        .orElse(null);
  }
}
