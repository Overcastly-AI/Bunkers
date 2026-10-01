package com.motion.catalogjoin;

import java.math.BigDecimal;
import java.util.Map;

/** Helpers for reading columns out of a row ({@code Map<String, Object>}, column names upper-case). */
public final class Rows {

  private Rows() {}

  /** Trimmed text value of a column, or {@code null} when the column is missing, null or blank. */
  public static String str(Map<String, Object> row, String column) {
    if (row == null) {
      return null;
    }
    Object value = row.get(column);
    if (value == null) {
      return null;
    }
    String text = text(value).trim();
    return text.isEmpty() ? null : text;
  }

  public static boolean isBlank(Map<String, Object> row, String column) {
    return str(row, column) == null;
  }

  /** Whether the column's trimmed value is one of {@code values}. */
  public static boolean in(Map<String, Object> row, String column, java.util.Set<String> values) {
    String value = str(row, column);
    return value != null && values.contains(value);
  }

  /** String form of a scalar. Numbers render without exponent or trailing zeros (123.0 -> "123"). */
  public static String text(Object value) {
    if (value instanceof BigDecimal decimal) {
      return decimal.signum() == 0 ? "0" : decimal.stripTrailingZeros().toPlainString();
    }
    if (value instanceof Double || value instanceof Float) {
      double d = ((Number) value).doubleValue();
      if (Double.isFinite(d)) {
        return text(BigDecimal.valueOf(d));
      }
    }
    return String.valueOf(value);
  }
}
