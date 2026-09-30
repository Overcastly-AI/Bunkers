package com.motion.catalogjoin;

import com.motion.catalogjoin.ingest.PayloadFormat;
import java.util.Collections;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import java.util.function.UnaryOperator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Application settings. Keys under {@code catalog.} configure this application; every other key
 * is passed through to Kafka Streams unchanged. Values may reference environment variables as
 * {@code ${NAME}} or {@code ${NAME:default}}.
 */
public final class CatalogConfig {

  public static final String PREFIX = "catalog.";

  /** STEP attribute that carries the BROP item number; it is the STEP-to-item bridge. */
  public static final String ITEM_NUMBER_ATTRIBUTE = "ITEM_NUMBER";

  private static final Pattern ENV_REF = Pattern.compile("\\$\\{([A-Za-z_][A-Za-z0-9_]*)(?::([^}]*))?}");

  private final Map<SourceTable, String> topics;
  private final PayloadFormat payloadFormat;
  private final String itemTopic;
  private final String itemLocationTopic;
  private final String itemPriceTopic;
  private final String deadLetterTopic;
  private final Map<String, String> stepAttributes;
  private final String classificationRoot;
  private final Integer partitions;
  private final Properties streamsProperties;

  private CatalogConfig(Properties raw) {
    Map<SourceTable, String> topicMap = new EnumMap<>(SourceTable.class);
    for (SourceTable table : SourceTable.values()) {
      topicMap.put(table, raw.getProperty(PREFIX + "topic." + table.slug(), table.defaultTopic()));
    }
    this.topics = Collections.unmodifiableMap(topicMap);
    this.payloadFormat =
        PayloadFormat.valueOf(
            raw.getProperty(PREFIX + "payload-format", PayloadFormat.AVRO_OR_JSON.name())
                .trim()
                .toUpperCase(Locale.ROOT));
    this.itemTopic = raw.getProperty(PREFIX + "output.item", "catalog.item");
    this.itemLocationTopic = raw.getProperty(PREFIX + "output.item-location", "catalog.item-location");
    this.itemPriceTopic = raw.getProperty(PREFIX + "output.item-price", "catalog.item-price");
    this.deadLetterTopic = raw.getProperty(PREFIX + "output.dead-letter", "catalog.join.dlt");
    this.classificationRoot = raw.getProperty(PREFIX + "step.classification-root", "Motion").trim();
    String partitionsValue = raw.getProperty(PREFIX + "partitions", "").trim();
    this.partitions = partitionsValue.isEmpty() ? null : Integer.valueOf(partitionsValue);

    Map<String, String> attributes = new LinkedHashMap<>();
    String attributePrefix = PREFIX + "step.attribute.";
    for (String name : raw.stringPropertyNames()) {
      if (name.startsWith(attributePrefix)) {
        String value = raw.getProperty(name).trim();
        if (!value.isEmpty()) {
          attributes.put(name.substring(attributePrefix.length()).toUpperCase(Locale.ROOT), value);
        }
      }
    }
    if (!attributes.containsKey(ITEM_NUMBER_ATTRIBUTE)) {
      throw new IllegalArgumentException(
          "Missing required setting " + attributePrefix + ITEM_NUMBER_ATTRIBUTE
              + " (the STEP_ATTRIBUTE_ID that holds the item number)");
    }
    this.stepAttributes = Collections.unmodifiableMap(attributes);

    Properties streams = new Properties();
    for (String name : raw.stringPropertyNames()) {
      if (!name.startsWith(PREFIX)) {
        streams.setProperty(name, raw.getProperty(name));
      }
    }
    this.streamsProperties = streams;
  }

  public static CatalogConfig from(Properties properties) {
    return from(properties, System::getenv);
  }

  static CatalogConfig from(Properties properties, UnaryOperator<String> env) {
    Properties resolved = new Properties();
    for (String name : properties.stringPropertyNames()) {
      resolved.setProperty(name, resolveEnv(properties.getProperty(name), env));
    }
    return new CatalogConfig(resolved);
  }

  static String resolveEnv(String value, UnaryOperator<String> env) {
    Matcher matcher = ENV_REF.matcher(value);
    StringBuilder out = new StringBuilder();
    while (matcher.find()) {
      String replacement = env.apply(matcher.group(1));
      if (replacement == null) {
        replacement = matcher.group(2);
      }
      if (replacement == null) {
        throw new IllegalArgumentException("Environment variable " + matcher.group(1) + " is not set");
      }
      matcher.appendReplacement(out, Matcher.quoteReplacement(replacement));
    }
    matcher.appendTail(out);
    return out.toString();
  }

  public String topic(SourceTable table) {
    return topics.get(table);
  }

  public PayloadFormat payloadFormat() {
    return payloadFormat;
  }

  public String itemTopic() {
    return itemTopic;
  }

  public String itemLocationTopic() {
    return itemLocationTopic;
  }

  public String itemPriceTopic() {
    return itemPriceTopic;
  }

  public String deadLetterTopic() {
    return deadLetterTopic;
  }

  /** Output field name (e.g. {@code SHIPPING_WEIGHT}) to STEP_ATTRIBUTE_ID, in configured order. */
  public Map<String, String> stepAttributes() {
    return stepAttributes;
  }

  /** Parent id at the top of the web hierarchy (the old recursive CTE's root). */
  public String classificationRoot() {
    return classificationRoot;
  }

  /** Partition count for internal repartition topics, or {@code null} to let Kafka Streams decide. */
  public Integer partitions() {
    return partitions;
  }

  public Properties streamsProperties() {
    Properties copy = new Properties();
    copy.putAll(streamsProperties);
    return copy;
  }
}
