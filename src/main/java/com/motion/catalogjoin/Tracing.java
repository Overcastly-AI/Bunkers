package com.motion.catalogjoin;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.StatusCode;

/**
 * Tags on the span the Datadog agent opens for the record being processed (its Kafka Streams
 * instrumentation). Uses the OpenTelemetry API, which the agent bridges when
 * {@code dd.trace.otel.enabled=true}; without the agent every call is a no-op.
 */
public final class Tracing {

  public static final String SOURCE_TABLE = "catalog.source.table";
  public static final String KEY = "catalog.key";
  public static final String CHANGES = "catalog.changes";
  public static final String DEAD_LETTER = "catalog.dead_letter";
  public static final String OUTPUT = "catalog.output";
  public static final String PUBLISHED = "catalog.published";
  public static final String SANITIZED = "catalog.sanitized";

  private Tracing() {}

  public static void tag(String name, String value) {
    Span.current().setAttribute(name, value);
  }

  public static void tag(String name, long value) {
    Span.current().setAttribute(name, value);
  }

  public static void tag(String name, boolean value) {
    Span.current().setAttribute(name, value);
  }

  /**
   * Output documents are emitted when Kafka Streams flushes its caches at commit, outside any
   * record's span, so each publish decision gets its own short span.
   */
  public static void publish(String output, String key, boolean published) {
    Span span = GlobalOpenTelemetry.getTracer("catalog-join").spanBuilder("catalog.publish").startSpan();
    span.setAttribute(OUTPUT, output);
    span.setAttribute(KEY, key);
    span.setAttribute(PUBLISHED, published);
    span.end();
  }

  /** Marks the current record's span as failed. */
  public static void error(String message) {
    Span span = Span.current();
    span.setStatus(StatusCode.ERROR, message);
    span.setAttribute("error.message", message);
  }
}
