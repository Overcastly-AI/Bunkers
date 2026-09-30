package com.motion.catalogjoin.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import java.util.ArrayList;
import java.util.List;
import java.util.TreeMap;

/**
 * The value of an aggregate: entries keyed by a stable id (the canonical key of the source row).
 * Adding and removing by id is idempotent, so the aggregate converges to the same result no matter
 * how a delete and an insert for different rows interleave.
 */
public record Group<T>(TreeMap<String, T> entries) {

  public Group {
    entries = entries == null ? new TreeMap<>() : entries;
  }

  public static <T> Group<T> empty() {
    return new Group<>(new TreeMap<>());
  }

  public Group<T> with(String id, T value) {
    TreeMap<String, T> copy = new TreeMap<>(entries);
    copy.put(id, value);
    return new Group<>(copy);
  }

  public Group<T> without(String id) {
    if (!entries.containsKey(id)) {
      return this;
    }
    TreeMap<String, T> copy = new TreeMap<>(entries);
    copy.remove(id);
    return new Group<>(copy);
  }

  @JsonIgnore
  public boolean isEmpty() {
    return entries.isEmpty();
  }

  /** Values in id order. */
  public List<T> values() {
    return new ArrayList<>(entries.values());
  }

  /** Empty aggregates become deletes, so a key disappears once its last row is gone. */
  public static <T> Group<T> nullIfEmpty(Group<T> group) {
    return group == null || group.isEmpty() ? null : group;
  }

  public static <T> List<T> valuesOf(Group<T> group) {
    return group == null ? List.of() : group.values();
  }
}
