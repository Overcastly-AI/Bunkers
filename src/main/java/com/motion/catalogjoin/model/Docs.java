package com.motion.catalogjoin.model;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Documents are plain JSON-shaped maps: source rows, joined pairs and published documents alike.
 * Helpers here never mutate their input (values may be shared with Kafka Streams caches).
 */
public final class Docs {

  private Docs() {}

  /** {@code of("a", 1, "b", null)}; null values are kept. */
  public static Map<String, Object> of(Object... keyValues) {
    Map<String, Object> doc = new LinkedHashMap<>();
    for (int i = 0; i < keyValues.length; i += 2) {
      doc.put((String) keyValues[i], keyValues[i + 1]);
    }
    return doc;
  }

  /** A copy of {@code doc} (null = empty) with {@code value} at a dotted path, e.g. {@code restrictions.item}. */
  public static Map<String, Object> with(Map<String, Object> doc, String path, Object value) {
    Map<String, Object> copy = doc == null ? new LinkedHashMap<>() : new LinkedHashMap<>(doc);
    int dot = path.indexOf('.');
    if (dot < 0) {
      copy.put(path, value);
    } else {
      String head = path.substring(0, dot);
      copy.put(head, with(map(copy.get(head)), path.substring(dot + 1), value));
    }
    return copy;
  }

  @SuppressWarnings("unchecked")
  public static Map<String, Object> map(Object value) {
    return (Map<String, Object>) value;
  }

  @SuppressWarnings("unchecked")
  public static List<Map<String, Object>> list(Object value) {
    return value == null ? List.of() : (List<Map<String, Object>>) value;
  }

  /** The entries of an aggregate as a list in id order (empty for null). */
  public static List<Map<String, Object>> values(Group<Map<String, Object>> group) {
    return group == null ? List.of() : new ArrayList<>(group.entries().values());
  }
}
