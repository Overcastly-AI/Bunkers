package com.motion.catalogjoin.sim;

import com.fasterxml.jackson.core.type.TypeReference;
import com.motion.catalogjoin.Json;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Predicate;

/**
 * The latest published document per key, as a consumer of a compacted topic sees it: a value
 * replaces, a tombstone removes. Only keys accepted by the filter are kept.
 */
public final class Outputs {

  private static final TypeReference<Map<String, Object>> DOC = new TypeReference<>() {};

  private final Predicate<String> keep;
  private final Map<String, Map<String, Map<String, Object>>> latest = new HashMap<>();

  public Outputs(Predicate<String> keep) {
    this.keep = keep;
  }

  public void accept(String topic, String key, byte[] value) {
    if (key == null || !keep.test(key)) {
      return;
    }
    Map<String, Map<String, Object>> docs = latest.computeIfAbsent(topic, t -> new HashMap<>());
    if (value == null) {
      docs.remove(key);
      return;
    }
    try {
      docs.put(key, Json.MAPPER.readValue(value, DOC));
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }

  public Map<String, Map<String, Object>> latest(String topic) {
    return latest.getOrDefault(topic, Map.of());
  }
}
