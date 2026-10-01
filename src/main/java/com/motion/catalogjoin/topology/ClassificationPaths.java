package com.motion.catalogjoin.topology;

import static com.motion.catalogjoin.Columns.PARENT_STEP_CLASSIFICATION_ID;
import static com.motion.catalogjoin.Columns.STEP_CLASSIFICATION_ID;

import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Rows;
import com.motion.catalogjoin.model.Docs;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.processor.api.Processor;
import org.apache.kafka.streams.processor.api.ProcessorContext;
import org.apache.kafka.streams.processor.api.Record;
import org.apache.kafka.streams.state.KeyValueIterator;
import org.apache.kafka.streams.state.KeyValueStore;

/**
 * Replaces the recursive CTE. Every STEP_CLASSIFICATION change is routed to a single partition,
 * where this processor keeps the whole (small) tree and re-emits the path of the changed node and
 * of every node below it. Output, keyed by STEP_CLASSIFICATION_ID (tombstone on delete):
 *
 * <pre>{"path": [rows from just below the root down to the node], "inWebHierarchy": true|false}</pre>
 *
 * The walk stops at the configured root, so rows at or above it are never part of a path.
 */
final class ClassificationPaths implements Processor<String, Map<String, Object>, String, Map<String, Object>> {

  static final String STORE = "classification-nodes";
  private static final String ID = STEP_CLASSIFICATION_ID;
  private static final String PARENT = PARENT_STEP_CLASSIFICATION_ID;

  private final String root;
  private ProcessorContext<String, Map<String, Object>> context;
  private KeyValueStore<String, Map<String, Object>> store;
  private final Map<String, Map<String, Object>> nodes = new HashMap<>();
  private final Map<String, Set<String>> children = new HashMap<>();
  /** Output timestamps never go backwards, so the paths table never sees an out-of-order update. */
  private long timestamp = Long.MIN_VALUE;

  ClassificationPaths(String root) {
    this.root = root;
  }

  @Override
  public void init(ProcessorContext<String, Map<String, Object>> context) {
    this.context = context;
    this.store = context.getStateStore(STORE);
    try (KeyValueIterator<String, Map<String, Object>> all = store.all()) {
      while (all.hasNext()) {
        KeyValue<String, Map<String, Object>> entry = all.next();
        link(entry.key, entry.value);
      }
    }
  }

  @Override
  public void process(Record<String, Map<String, Object>> record) {
    String id = Keys.parse(record.key()).get(ID);
    if (id == null) {
      return;
    }
    Map<String, Object> previous = nodes.get(id);
    if (previous != null) {
      unlink(id, previous);
    }
    Map<String, Object> row = record.value();
    timestamp = Math.max(timestamp, record.timestamp());
    if (row == null) {
      store.delete(id);
      context.forward(new Record<String, Map<String, Object>>(Keys.of(ID, id), null, timestamp));
    } else {
      store.put(id, row);
      link(id, row);
    }
    for (String affected : subtree(id)) {
      if (nodes.containsKey(affected)) {
        context.forward(new Record<>(Keys.of(ID, affected), path(affected), timestamp));
      }
    }
  }

  private void link(String id, Map<String, Object> row) {
    nodes.put(id, row);
    String parent = Rows.str(row, PARENT);
    if (parent != null) {
      children.computeIfAbsent(parent, p -> new LinkedHashSet<>()).add(id);
    }
  }

  private void unlink(String id, Map<String, Object> row) {
    nodes.remove(id);
    String parent = Rows.str(row, PARENT);
    if (parent != null) {
      Set<String> siblings = children.get(parent);
      if (siblings != null) {
        siblings.remove(id);
        if (siblings.isEmpty()) {
          children.remove(parent);
        }
      }
    }
  }

  /** The node and all of its descendants, breadth first, each once (cycle safe). */
  private List<String> subtree(String id) {
    List<String> out = new ArrayList<>();
    Set<String> seen = new HashSet<>();
    Deque<String> queue = new ArrayDeque<>();
    queue.add(id);
    while (!queue.isEmpty()) {
      String next = queue.poll();
      if (seen.add(next)) {
        out.add(next);
        queue.addAll(children.getOrDefault(next, Set.of()));
      }
    }
    return out;
  }

  private Map<String, Object> path(String id) {
    Deque<Map<String, Object>> path = new ArrayDeque<>();
    Set<String> seen = new HashSet<>();
    String current = id;
    boolean reachedRoot = false;
    while (current != null && nodes.containsKey(current) && seen.add(current)) {
      Map<String, Object> row = nodes.get(current);
      path.addFirst(row);
      current = Rows.str(row, PARENT);
      if (root.equals(current)) {
        reachedRoot = true;
        break;
      }
    }
    return Docs.of("path", new ArrayList<>(path), "inWebHierarchy", reachedRoot && !root.equals(id));
  }
}
