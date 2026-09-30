package com.motion.catalogjoin.model;

import java.util.Map;

/** One STEP_PRODUCT_VALUES row joined to its STEP_UNIT row (null when there is no unit). */
public record StepValue(Map<String, Object> value, Map<String, Object> unit) {}
