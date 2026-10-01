package com.motion.catalogjoin.topology;

import static org.assertj.core.api.Assertions.assertThat;

import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.model.ModelSerdes;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.processor.api.MockProcessorContext;
import org.apache.kafka.streams.processor.api.Record;
import org.apache.kafka.streams.state.KeyValueStore;
import org.junit.jupiter.api.Test;

/** A restarted processor rebuilds its in-memory tree from the store and still rewrites whole subtrees. */
class ClassificationPathsRestartTest {

  private static Map<String, Object> node(String id, String parent, String name) {
    Map<String, Object> row = new LinkedHashMap<>();
    row.put("STEP_CLASSIFICATION_ID", id);
    row.put("PARENT_STEP_CLASSIFICATION_ID", parent);
    row.put("NAME", name);
    return row;
  }

  private static String key(String id) { return Keys.of("STEP_CLASSIFICATION_ID", id); }

  @Test
  @SuppressWarnings("unchecked")
  void ancestorChangeAfterRestartRewritesDescendants() {
    MockProcessorContext<String, Map<String, Object>> context = new MockProcessorContext<>();
    KeyValueStore<String, Map<String, Object>> store = org.apache.kafka.streams.state.Stores
        .keyValueStoreBuilder(org.apache.kafka.streams.state.Stores.inMemoryKeyValueStore(ClassificationPaths.STORE),
            Serdes.String(), ModelSerdes.DOC)
        .withLoggingDisabled()
        .build();
    store.init(context.getStateStoreContext(), store);
    context.addStateStore(store);

    ClassificationPaths first = new ClassificationPaths("Motion");
    first.init(context);
    first.process(new Record<>(key("C1"), node("C1", "Motion", "Power"), 0L));
    first.process(new Record<>(key("C2"), node("C2", "C1", "Bearings"), 0L));
    first.process(new Record<>(key("C3"), node("C3", "C2", "Ball"), 0L));
    first.close();
    context.resetForwards();

    ClassificationPaths second = new ClassificationPaths("Motion");
    second.init(context);
    second.process(new Record<>(key("C1"), node("C1", "Elsewhere", "Power"), 0L));

    List<String> forwarded = new ArrayList<>();
    context.forwarded().forEach(f -> forwarded.add(f.record().key()));
    assertThat(forwarded).containsExactly(key("C1"), key("C2"), key("C3"));
    Map<String, Object> c3 = context.forwarded().get(2).record().value();
    assertThat(c3.get("inWebHierarchy")).isEqualTo(false);
    assertThat((List<Object>) c3.get("path")).hasSize(3);
  }
}
