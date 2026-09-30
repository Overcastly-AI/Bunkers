package com.motion.catalogjoin.model;

import java.util.List;
import java.util.Map;

/**
 * Where a STEP classification sits in the hierarchy.
 *
 * @param path STEP_CLASSIFICATION rows from the top-most known ancestor down to the classification
 *     itself
 * @param topParentId PARENT_STEP_CLASSIFICATION_ID of the top-most row in {@code path} (null when
 *     the walk stopped on a cycle)
 * @param inWebHierarchy true when the chain reaches the configured root (e.g. {@code Motion})
 */
public record ClassPath(List<Map<String, Object>> path, String topParentId, boolean inWebHierarchy) {}
