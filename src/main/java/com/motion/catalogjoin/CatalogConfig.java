package com.motion.catalogjoin;

import com.motion.catalogjoin.ingest.PayloadFormat;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Collections;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.TreeMap;
import java.util.function.UnaryOperator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * All settings, from one place. {@code catalog-join.properties} on the classpath holds every key
 * and its default; files given at startup are layered on top (later wins), then explicit
 * overrides. {@code ${ENV}} / {@code ${ENV:default}} references are resolved last. Keys under
 * {@code catalog.} and {@code sim.} configure this application; everything else is Kafka Streams
 * (and client) configuration.
 */
public final class CatalogConfig {

  public static final String DEFAULTS_RESOURCE = "/catalog-join.properties";
  /** STEP attribute whose value is the BROP ITEM_NO: the STEP-to-item bridge. */
  public static final String ITEM_NUMBER_ATTRIBUTE = "ITEM_NUMBER";

  private static final Pattern ENV_REF = Pattern.compile("\\$\\{([A-Za-z_][A-Za-z0-9_]*)(?::([^}]*))?}");
  private static final Set<String> OWN_PREFIXES = Set.of("catalog.", "sim.");

  /** Settings of the load simulator ({@code sim.*}). */
  public record Sim(long seed, int items, int locations, int pricesPerItem, int rounds, int fromRound,
      String formats, double padShare, long rate, int sourcePartitions, short sourceReplication,
      int sampleEvery, int settleTimeoutSeconds) {}

  private final Map<String, String> values;
  private final Map<SourceTable, String> topics = new EnumMap<>(SourceTable.class);
  private final Map<SourceTable, List<String>> keyColumns = new EnumMap<>(SourceTable.class);
  private final Map<SourceTable, Set<String>> exactKeyColumns = new EnumMap<>(SourceTable.class);
  private final Map<String, String> stepAttributes;

  private CatalogConfig(Map<String, String> values) {
    this.values = values;
    String prefix = get("catalog.topic-prefix");
    for (SourceTable table : SourceTable.values()) {
      topics.put(table, prefix + require("catalog.source." + table.slug() + ".topic"));
      keyColumns.put(table, list("catalog.source." + table.slug() + ".key"));
      exactKeyColumns.put(table, Set.copyOf(optionalList("catalog.source." + table.slug() + ".exact-key")));
    }
    Map<String, String> attributes = new LinkedHashMap<>();
    values.forEach((key, value) -> {
      if (key.startsWith("catalog.step.attribute.") && !value.isBlank()) {
        attributes.put(key.substring("catalog.step.attribute.".length()).toUpperCase(Locale.ROOT), value.trim());
      }
    });
    this.stepAttributes = Collections.unmodifiableMap(attributes);
  }

  /** Defaults, then each file in order, then overrides. */
  public static CatalogConfig load(List<Path> files, Map<String, String> overrides) {
    Properties merged = defaults();
    for (Path file : files) {
      try (InputStream in = Files.newInputStream(file)) {
        Properties layer = new Properties();
        layer.load(in);
        merged.putAll(layer);
      } catch (IOException e) {
        throw new UncheckedIOException("Cannot read config " + file, e);
      }
    }
    merged.putAll(overrides);
    return resolve(merged, System::getenv);
  }

  /** Defaults plus the given overrides (tests, tools). */
  public static CatalogConfig of(Properties overrides) {
    Properties merged = defaults();
    merged.putAll(overrides);
    return resolve(merged, System::getenv);
  }

  static CatalogConfig resolve(Properties merged, UnaryOperator<String> env) {
    Map<String, String> values = new TreeMap<>();
    for (String name : merged.stringPropertyNames()) {
      values.put(name, resolveEnv(merged.getProperty(name), env).trim());
    }
    return new CatalogConfig(Collections.unmodifiableMap(values));
  }

  private static Properties defaults() {
    Properties defaults = new Properties();
    try (InputStream in = CatalogConfig.class.getResourceAsStream(DEFAULTS_RESOURCE)) {
      if (in == null) {
        throw new IllegalStateException(DEFAULTS_RESOURCE + " is not on the classpath");
      }
      defaults.load(in);
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
    return defaults;
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

  // --- generic access ------------------------------------------------------------------------------

  public String get(String key) {
    return values.getOrDefault(key, "");
  }

  private String require(String key) {
    String value = get(key);
    if (value.isEmpty()) {
      throw new IllegalArgumentException("Missing required setting " + key);
    }
    return value;
  }

  private int integer(String key) {
    return Integer.parseInt(require(key));
  }

  private List<String> list(String key) {
    require(key);
    return optionalList(key);
  }

  private List<String> optionalList(String key) {
    return Arrays.stream(get(key).split(",")).map(String::trim).filter(s -> !s.isEmpty()).toList();
  }

  /** Every effective setting, with secrets masked; for {@code print-config}. */
  public Map<String, String> describe() {
    Map<String, String> out = new TreeMap<>();
    values.forEach((key, value) -> {
      String lower = key.toLowerCase(Locale.ROOT);
      boolean secret = lower.contains("password") || lower.contains("secret") || lower.contains("jaas") || lower.contains("token");
      out.put(key, secret && !value.isEmpty() ? "****" : value);
    });
    return out;
  }

  // --- topics --------------------------------------------------------------------------------------

  public String topic(SourceTable table) {
    return topics.get(table);
  }

  public List<String> keyColumns(SourceTable table) {
    return keyColumns.get(table);
  }

  /** The canonical key of a row of {@code table} (see {@link Keys}). */
  public String key(SourceTable table, Map<String, Object> row) {
    return Keys.of(row, keyColumns.get(table), exactKeyColumns.get(table));
  }

  public String itemTopic() {
    return output("item");
  }

  public String itemLocationTopic() {
    return output("item-location");
  }

  public String itemPriceTopic() {
    return output("item-price");
  }

  public String deadLetterTopic() {
    return output("dead-letter");
  }

  public List<String> outputTopics() {
    return List.of(itemTopic(), itemLocationTopic(), itemPriceTopic());
  }

  private String output(String name) {
    return get("catalog.topic-prefix") + require("catalog.output." + name);
  }

  public int outputPartitions() {
    return integer("catalog.output.partitions");
  }

  public short outputReplication() {
    return (short) integer("catalog.output.replication");
  }

  public int outputMaxMessageBytes() {
    return integer("catalog.output.max-message-bytes");
  }

  public long deadLetterRetentionMs() {
    return Long.parseLong(require("catalog.output.dead-letter-retention-ms"));
  }

  /** Partition count for internal repartition topics, or {@code null} to follow the sources. */
  public Integer partitions() {
    String value = get("catalog.partitions");
    return value.isEmpty() ? null : Integer.valueOf(value);
  }

  // --- decoding and join rules ---------------------------------------------------------------------

  public PayloadFormat payloadFormat() {
    return PayloadFormat.valueOf(require("catalog.payload-format").toUpperCase(Locale.ROOT));
  }

  public Set<String> droppedColumns() {
    return Set.copyOf(optionalList("catalog.ingest.dropped-columns").stream().map(c -> c.toUpperCase(Locale.ROOT)).toList());
  }

  /** Output name (e.g. {@code SHIPPING_WEIGHT}) to STEP_ATTRIBUTE_ID. */
  public Map<String, String> stepAttributes() {
    return stepAttributes;
  }

  public String itemNumberAttribute() {
    String id = stepAttributes.get(ITEM_NUMBER_ATTRIBUTE);
    if (id == null) {
      throw new IllegalArgumentException("Missing required setting catalog.step.attribute." + ITEM_NUMBER_ATTRIBUTE
          + " (the STEP_ATTRIBUTE_ID that holds the item number)");
    }
    return id;
  }

  public String classificationRoot() {
    return require("catalog.step.classification-root");
  }

  public Set<String> dcLocationTypes() {
    return Set.copyOf(list("catalog.dc-stock.location-types"));
  }

  public Set<String> dcLocationStatuses() {
    return Set.copyOf(list("catalog.dc-stock.location-statuses"));
  }

  public Set<String> dcExcludedSellable() {
    return Set.copyOf(optionalList("catalog.dc-stock.exclude-sellable"));
  }

  // --- runtime -------------------------------------------------------------------------------------

  public int healthPort() {
    return integer("catalog.health-port");
  }

  public java.time.Duration shutdownTimeout() {
    return java.time.Duration.ofMillis(Long.parseLong(require("catalog.shutdown-timeout-ms")));
  }

  public long rocksDbMemoryBytes() {
    return Long.parseLong(require("catalog.rocksdb.memory-bytes"));
  }

  public double rocksDbMemtableShare() {
    return Double.parseDouble(require("catalog.rocksdb.memtable-share"));
  }

  /** Everything that is not {@code catalog.*} or {@code sim.*}: Kafka Streams and client settings. */
  public Properties streamsProperties() {
    Properties out = new Properties();
    values.forEach((key, value) -> {
      if (OWN_PREFIXES.stream().noneMatch(key::startsWith)) {
        out.setProperty(key, value);
      }
    });
    return out;
  }

  public Sim sim() {
    return new Sim(
        Long.parseLong(require("sim.seed")), integer("sim.items"), integer("sim.locations"),
        integer("sim.prices-per-item"), integer("sim.rounds"), integer("sim.from-round"),
        require("sim.formats"), Double.parseDouble(require("sim.pad-share")), Long.parseLong(require("sim.rate")),
        integer("sim.source-partitions"), (short) integer("sim.source-replication"),
        integer("sim.sample-every"), integer("sim.settle-timeout-s"));
  }
}
