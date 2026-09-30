package com.motion.catalogjoin.ingest;

import java.util.Map;

/**
 * A decoded source record: the canonical key and the current row, or a {@code null} row for a
 * delete.
 */
public record Decoded(String key, Map<String, Object> row) {

  public boolean isDelete() {
    return row == null;
  }
}
