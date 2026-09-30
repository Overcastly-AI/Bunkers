package com.motion.catalogjoin.ingest;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.model.ModelSerdes;
import java.nio.charset.StandardCharsets;
import java.util.EnumMap;
import java.util.Map;
import java.util.function.Predicate;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.Branched;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.streams.kstream.Named;
import org.apache.kafka.streams.kstream.Produced;
import org.apache.kafka.streams.kstream.Repartitioned;
import org.apache.kafka.streams.processor.api.FixedKeyProcessor;
import org.apache.kafka.streams.processor.api.FixedKeyProcessorContext;
import org.apache.kafka.streams.processor.api.FixedKeyRecord;
import org.apache.kafka.streams.state.KeyValueStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Reads each CDC source topic once and exposes it three ways:
 *
 * <ul>
 *   <li>{@link #decoded} - decoded rows keyed by canonical key, in source partitioning;
 *   <li>{@link #canonical} - the same, repartitioned by canonical key;
 *   <li>{@link #table} - the canonical stream as a table (latest row per key).
 * </ul>
 *
 * <p>Repartitioning by canonical key is what makes joins safe: producers partition by their own key
 * bytes (column order, padding, number formatting), while joins need every table partitioned by the
 * exact same bytes. Records that cannot be decoded go to the dead-letter topic with the raw bytes.
 */
public final class Sources {

  private static final Logger LOG = LoggerFactory.getLogger(Sources.class);

  public static final String HEADER_ERROR = "catalog.error";
  public static final String HEADER_TOPIC = "catalog.source.topic";
  public static final String HEADER_PARTITION = "catalog.source.partition";
  public static final String HEADER_OFFSET = "catalog.source.offset";

  private final StreamsBuilder builder;
  private final CatalogConfig config;
  private final CdcDecoder decoder;
  private final Map<SourceTable, Predicate<Map<String, String>>> keyFilters = new EnumMap<>(SourceTable.class);
  private final Map<SourceTable, KStream<String, Map<String, Object>>> decoded = new EnumMap<>(SourceTable.class);
  private final Map<SourceTable, KStream<String, Map<String, Object>>> canonical = new EnumMap<>(SourceTable.class);
  private final Map<SourceTable, KTable<String, Map<String, Object>>> tables = new EnumMap<>(SourceTable.class);

  public Sources(StreamsBuilder builder, CatalogConfig config) {
    this.builder = builder;
    this.config = config;
    this.decoder = new CdcDecoder(config.payloadFormat());
  }

  /**
   * Keep only rows whose key columns match; everything else is dropped right after decoding (before
   * any repartition or state). Must be set before the table is first used.
   */
  public Sources filterKeys(SourceTable table, Predicate<Map<String, String>> keep) {
    if (decoded.containsKey(table)) {
      throw new IllegalStateException(table + " is already in use; set its key filter first");
    }
    keyFilters.put(table, keep);
    return this;
  }

  public KStream<String, Map<String, Object>> decoded(SourceTable table) {
    return decoded.computeIfAbsent(table, this::buildDecoded);
  }

  public KStream<String, Map<String, Object>> canonical(SourceTable table) {
    return canonical.computeIfAbsent(
        table,
        t -> {
          Repartitioned<String, Map<String, Object>> repartitioned =
              Repartitioned.<String, Map<String, Object>>as(t.slug() + "-by-key")
                  .withKeySerde(Serdes.String())
                  .withValueSerde(ModelSerdes.ROW);
          if (config.partitions() != null) {
            repartitioned = repartitioned.withNumberOfPartitions(config.partitions());
          }
          return decoded(t).repartition(repartitioned);
        });
  }

  public KTable<String, Map<String, Object>> table(SourceTable table) {
    return tables.computeIfAbsent(
        table,
        t ->
            canonical(t)
                .toTable(
                    Named.as(t.slug() + "-table"),
                    Materialized.<String, Map<String, Object>, KeyValueStore<Bytes, byte[]>>as(t.slug() + "-store")
                        .withKeySerde(Serdes.String())
                        .withValueSerde(ModelSerdes.ROW)));
  }

  private KStream<String, Map<String, Object>> buildDecoded(SourceTable table) {
    String topic = config.topic(table);
    String slug = table.slug();
    KStream<byte[], DecodeResult> results =
        builder.stream(topic, Consumed.with(Serdes.ByteArray(), Serdes.ByteArray()).withName(slug + "-source"))
            .mapValues((key, value) -> decode(table, key, value), Named.as(slug + "-decode"));

    Map<String, KStream<byte[], DecodeResult>> branches =
        results
            .split(Named.as(slug + "-"))
            .branch((key, result) -> result.error() == null, Branched.as("valid"))
            .defaultBranch(Branched.as("invalid"));

    branches
        .get(slug + "-invalid")
        .processValues(DeadLetterHeaders::new, Named.as(slug + "-dead-letter-headers"))
        .to(
            config.deadLetterTopic(),
            Produced.with(Serdes.ByteArray(), Serdes.ByteArray()).withName(slug + "-dead-letter"));

    KStream<String, Map<String, Object>> rows =
        branches
            .get(slug + "-valid")
            .map(
                (key, result) -> KeyValue.pair(result.decoded().key(), result.decoded().row()),
                Named.as(slug + "-rekey"));

    Predicate<Map<String, String>> keep = keyFilters.get(table);
    if (keep != null) {
      rows = rows.filter((key, row) -> keep.test(Keys.parse(key)), Named.as(slug + "-key-filter"));
    }
    return rows;
  }

  private DecodeResult decode(SourceTable table, byte[] key, byte[] value) {
    try {
      return new DecodeResult(decoder.decode(table, key, value), value, null);
    } catch (InvalidRecordException | RuntimeException e) {
      return new DecodeResult(null, value, e.getMessage() == null ? e.toString() : e.getMessage());
    }
  }

  private record DecodeResult(Decoded decoded, byte[] raw, String error) {}

  /** Adds error and origin headers and restores the raw value for the dead-letter topic. */
  private static final class DeadLetterHeaders implements FixedKeyProcessor<byte[], DecodeResult, byte[]> {

    private FixedKeyProcessorContext<byte[], byte[]> context;

    @Override
    public void init(FixedKeyProcessorContext<byte[], byte[]> context) {
      this.context = context;
    }

    @Override
    public void process(FixedKeyRecord<byte[], DecodeResult> record) {
      var headers = record.headers();
      headers.add(HEADER_ERROR, record.value().error().getBytes(StandardCharsets.UTF_8));
      context
          .recordMetadata()
          .ifPresent(
              meta -> {
                headers.add(HEADER_TOPIC, meta.topic().getBytes(StandardCharsets.UTF_8));
                headers.add(HEADER_PARTITION, Integer.toString(meta.partition()).getBytes(StandardCharsets.UTF_8));
                headers.add(HEADER_OFFSET, Long.toString(meta.offset()).getBytes(StandardCharsets.UTF_8));
                LOG.warn(
                    "Dead-lettering {}-{}@{}: {}", meta.topic(), meta.partition(), meta.offset(), record.value().error());
              });
      context.forward(record.withValue(record.value().raw()));
    }
  }
}
