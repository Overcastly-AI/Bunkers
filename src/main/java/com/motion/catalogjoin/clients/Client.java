package com.motion.catalogjoin.clients;

import java.time.Duration;
import java.util.Map;

/**
 * One downstream client: which document it reads ({@code item} or {@code item-location}), the
 * fields it wants, the compacted topic its view is published to, and, optionally, the HTTP endpoint
 * that {@code catalog-join deliver --client <name>} posts that topic to.
 */
public record Client(
    String name,
    String source,
    Projection fields,
    String topic,
    String deadLetterTopic,
    Http http) {

  public static final Map<String, String> SOURCES = Map.of("item", "ITEM_NO", "item-location", "ITEM_NO,MI_LOC");

  /** HTTP delivery settings; {@code url} is null when the client only reads the topic. */
  public record Http(String url, Map<String, String> headers, int batchSize, Duration timeout, Duration maxBackoff) {}
}
