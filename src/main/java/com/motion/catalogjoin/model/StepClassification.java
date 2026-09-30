package com.motion.catalogjoin.model;

import java.util.Map;

/** A STEP_PRODUCT_CLASSIFICATION row joined to its classification path (null when unknown). */
public record StepClassification(Map<String, Object> link, ClassPath classification) {}
