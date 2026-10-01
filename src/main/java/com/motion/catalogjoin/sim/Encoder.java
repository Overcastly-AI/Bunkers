package com.motion.catalogjoin.sim;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.ingest.CdcEnvelope;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.math.BigDecimal;
import java.nio.ByteBuffer;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.BinaryEncoder;
import org.apache.avro.io.EncoderFactory;

/**
 * Turns simulated rows into CDC messages in the formats the app accepts: flat JSON (KCOP), the
 * JSON IBM CDC envelope (with or without Avro-JSON union wrappers), and the Avro envelope (raw or
 * Confluent-framed), mixed as {@code sim.formats} says. DB2 CHAR padding is added to key columns
 * for {@code sim.pad-share} of rows; the choice is per row, never per message, so every message for
 * a row has identical key bytes and lands on the same partition, as it would from a real producer.
 */
final class Encoder {

  enum Format { FLAT, ENVELOPE, AVRO }

  record Message(String topic, byte[] key, byte[] value) {}

  private static final long FORMAT = 101, PAD = 102, WRAP = 103, FRAME = 104;
  private static final long FIRST_TIMESTAMP = 1_780_000_000_000L;

  private final CatalogConfig config;
  private final long seed;
  private final Map<Format, Integer> weights;
  private final int totalWeight;
  private final double padShare;
  private final GenericDatumWriter<GenericRecord> avroWriter = new GenericDatumWriter<>(CdcEnvelope.SCHEMA);
  private long sequence;

  Encoder(CatalogConfig config) {
    this.config = config;
    this.seed = config.sim().seed();
    this.weights = parseWeights(config.sim().formats());
    this.totalWeight = weights.values().stream().mapToInt(Integer::intValue).sum();
    this.padShare = config.sim().padShare();
    if (totalWeight <= 0) {
      throw new IllegalArgumentException("sim.formats weights must add up to more than 0");
    }
  }

  /** An upsert of {@code row}, or a delete of the row whose last image is {@code row}. */
  Message encode(SourceTable table, Map<String, Object> row, boolean delete) {
    long n = sequence++;
    List<String> keyColumns = config.keyColumns(table);
    boolean pad = Mix.frac(Mix.hash(seed, PAD, config.key(table, row).hashCode(), table.ordinal())) < padShare;
    Map<String, Object> image = pad ? padKeyColumns(keyColumns, row) : row;

    Map<String, Object> key = new LinkedHashMap<>();
    keyColumns.forEach(column -> key.put(column, image.get(column)));

    byte[] value = switch (pick(Mix.hash(seed, FORMAT, n))) {
      case FLAT -> delete ? null : Json.write(image);
      case ENVELOPE -> {
        Map<String, Object> body = Mix.frac(Mix.hash(seed, WRAP, n)) < 0.5 ? wrapUnions(image) : image;
        Map<String, Object> envelope = new LinkedHashMap<>();
        envelope.put(CdcEnvelope.OP, delete ? CdcEnvelope.DELETE : CdcEnvelope.UPDATE);
        envelope.put(CdcEnvelope.BEFORE, delete ? body : null);
        envelope.put(CdcEnvelope.AFTER, delete ? null : body);
        envelope.put(CdcEnvelope.TS_MS, FIRST_TIMESTAMP + n);
        yield Json.write(envelope);
      }
      case AVRO -> avro(delete, image, Mix.frac(Mix.hash(seed, FRAME, n)) < 0.5);
    };
    return new Message(config.topic(table), Json.write(key), value);
  }

  private Format pick(long h) {
    int point = Mix.mod(h, totalWeight);
    for (Map.Entry<Format, Integer> entry : weights.entrySet()) {
      point -= entry.getValue();
      if (point < 0) {
        return entry.getKey();
      }
    }
    return Format.FLAT;
  }

  private static Map<String, Object> padKeyColumns(List<String> keyColumns, Map<String, Object> row) {
    Map<String, Object> padded = new LinkedHashMap<>(row);
    for (String column : keyColumns) {
      if (padded.get(column) instanceof String text) {
        padded.put(column, text + "  ");
      }
    }
    return padded;
  }

  private static Map<String, Object> wrapUnions(Map<String, Object> row) {
    Map<String, Object> wrapped = new LinkedHashMap<>();
    row.forEach((column, value) -> wrapped.put(column,
        value instanceof String ? Map.of("string", value) : value instanceof Long ? Map.of("long", value) : value));
    return wrapped;
  }

  private byte[] avro(boolean delete, Map<String, Object> row, boolean confluentFrame) {
    Map<String, Object> columns = new LinkedHashMap<>();
    // The envelope has no decimal type: decimals travel as strings, as from IBM CDC.
    row.forEach((column, value) -> columns.put(column, value instanceof BigDecimal decimal ? decimal.toPlainString() : value));
    GenericRecord envelope = new GenericData.Record(CdcEnvelope.SCHEMA);
    envelope.put(CdcEnvelope.OP, delete ? CdcEnvelope.DELETE : CdcEnvelope.UPDATE);
    envelope.put(CdcEnvelope.BEFORE, delete ? columns : null);
    envelope.put(CdcEnvelope.AFTER, delete ? null : columns);
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      if (confluentFrame) {
        out.write(ByteBuffer.allocate(CdcEnvelope.CONFLUENT_HEADER_BYTES).put(CdcEnvelope.CONFLUENT_MAGIC).putInt(1).array());
      }
      BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(out, null);
      avroWriter.write(envelope, encoder);
      encoder.flush();
      return out.toByteArray();
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }

  private static Map<Format, Integer> parseWeights(String spec) {
    Map<Format, Integer> weights = new LinkedHashMap<>();
    for (String part : spec.split(",")) {
      String[] kv = part.trim().split("[=:]");
      weights.put(Format.valueOf(kv[0].trim().toUpperCase(Locale.ROOT)), Integer.parseInt(kv[1].trim()));
    }
    return weights;
  }
}
