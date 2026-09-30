package com.motion.catalogjoin;

import com.fasterxml.jackson.core.type.TypeReference;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Map;
import java.util.TreeMap;

/**
 * Canonical record keys. Every key in this application, internal or published, is a JSON object of
 * key columns with column names upper-cased and sorted, and values rendered as trimmed strings:
 *
 * <pre>{"ITEM_NO":"123","MI_LOC":"0042"}</pre>
 *
 * <p>Because the same function builds a table's own key and every foreign key that points at it,
 * joins match on value alone (DB2 CHAR padding and number-vs-string differences do not matter), and
 * every table is partitioned by the same bytes.
 */
public final class Keys {

  private static final TypeReference<TreeMap<String, String>> KEY_TYPE = new TypeReference<>() {};

  private Keys() {}

  public static String of(String column, Object value) {
    TreeMap<String, String> key = new TreeMap<>();
    key.put(column, render(value));
    return Json.writeString(key);
  }

  public static String of(String column1, Object value1, String column2, Object value2) {
    TreeMap<String, String> key = new TreeMap<>();
    key.put(column1, render(value1));
    key.put(column2, render(value2));
    return Json.writeString(key);
  }

  /** Canonical key built from the given columns of a row. */
  public static String of(Map<String, Object> row, Iterable<String> columns) {
    TreeMap<String, String> key = new TreeMap<>();
    for (String column : columns) {
      key.put(column, render(row.get(column)));
    }
    return Json.writeString(key);
  }

  /**
   * Foreign-key reference for a single column, or {@code null} when the value is missing or blank.
   * A null foreign key means "no match"; left joins still emit the left row.
   */
  public static String ref(String column, Object value) {
    String rendered = render(value);
    return rendered == null || rendered.isEmpty() ? null : of(column, rendered);
  }

  public static Map<String, String> parse(String key) {
    try {
      return Json.MAPPER.readValue(key, KEY_TYPE);
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }

  static String render(Object value) {
    return value == null ? null : Rows.text(value).trim();
  }
}
