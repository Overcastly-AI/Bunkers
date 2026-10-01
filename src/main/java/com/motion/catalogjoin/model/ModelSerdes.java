package com.motion.catalogjoin.model;

import com.fasterxml.jackson.core.type.TypeReference;
import com.motion.catalogjoin.Json;
import java.util.Map;
import org.apache.kafka.common.serialization.Serde;

/** The two value types kept in state and internal topics: a document, and an aggregate of documents. */
public final class ModelSerdes {

  public static final Serde<Map<String, Object>> DOC = Json.serde(new TypeReference<>() {});
  public static final Serde<Group<Map<String, Object>>> GROUP = Json.serde(new TypeReference<>() {});

  private ModelSerdes() {}
}
