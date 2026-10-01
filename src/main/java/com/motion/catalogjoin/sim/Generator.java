package com.motion.catalogjoin.sim;

import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.sim.SimModel.Slot;
import com.motion.catalogjoin.sim.SimModel.TableRow;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Emits the simulated catalog. Round 0 is the initial load (every row); each later round emits
 * the difference between consecutive slot versions: upserts for new or changed rows and deletes
 * for rows that went away. Whether the deletes or the upserts of a change go first is chosen per
 * change, to exercise both orders.
 */
final class Generator {

  /** Where messages go: Kafka, or the in-process test driver. */
  interface Sink {
    void send(Encoder.Message message);

    default void flush() {}
  }

  private static final long ORDER = 201;

  private final SimModel model;
  private final Encoder encoder;
  private final Sink sink;
  private final long seed;
  private final Map<SourceTable, long[]> counts = new EnumMap<>(SourceTable.class);

  Generator(SimModel model, Encoder encoder, Sink sink, long seed) {
    this.model = model;
    this.encoder = encoder;
    this.sink = sink;
    this.seed = seed;
  }

  /** Emits rounds {@code from..to} inclusive; returns messages sent. */
  long run(int from, int to, java.util.function.IntConsumer onRoundDone) {
    long before = total();
    for (int round = from; round <= to; round++) {
      for (Slot slot : Slot.values()) {
        int n = model.count(slot);
        for (int id = 0; id < n; id++) {
          if (round == 0) {
            emit(List.of(), model.rows(slot, id, 0), true);
          } else if (model.changes(slot, id, round)) {
            int version = model.version(slot, id, round);
            boolean deletesFirst = (Mix.hash(seed, ORDER, slot.ordinal(), id, round) & 1) == 0;
            emit(model.rows(slot, id, version - 1), model.rows(slot, id, version), deletesFirst);
          }
        }
      }
      sink.flush();
      if (onRoundDone != null) {
        onRoundDone.accept(round);
      }
    }
    return total() - before;
  }

  Map<SourceTable, long[]> counts() {
    return counts;
  }

  long total() {
    return counts.values().stream().mapToLong(c -> c[0]).sum();
  }

  private void emit(List<TableRow> previous, List<TableRow> current, boolean deletesFirst) {
    Map<String, TableRow> old = index(previous);
    Map<String, TableRow> now = index(current);
    if (deletesFirst) {
      deletes(old, now);
      upserts(old, now);
    } else {
      upserts(old, now);
      deletes(old, now);
    }
  }

  private void deletes(Map<String, TableRow> old, Map<String, TableRow> now) {
    old.forEach((key, row) -> {
      if (!now.containsKey(key)) {
        send(row, true);
      }
    });
  }

  private void upserts(Map<String, TableRow> old, Map<String, TableRow> now) {
    now.forEach((key, row) -> {
      TableRow before = old.get(key);
      if (before == null || !before.row().equals(row.row())) {
        send(row, false);
      }
    });
  }

  private void send(TableRow row, boolean delete) {
    sink.send(encoder.encode(row.table(), row.row(), delete));
    counts.computeIfAbsent(row.table(), t -> new long[1])[0]++;
  }

  private static Map<String, TableRow> index(List<TableRow> rows) {
    Map<String, TableRow> out = new LinkedHashMap<>();
    for (TableRow row : rows) {
      out.put(row.table().name() + "|" + Keys.of(row.row(), row.table().keyColumns()), row);
    }
    return out;
  }
}
