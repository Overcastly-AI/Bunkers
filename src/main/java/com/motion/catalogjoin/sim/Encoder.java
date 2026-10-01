package com.motion.catalogjoin.sim;

import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.SourceTable;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.math.BigDecimal;
import java.nio.ByteBuffer;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.BinaryEncoder;
import org.apache.avro.io.EncoderFactory;

/**
 * Turns simulated rows into CDC messages in the formats the app accepts: flat JSON (KCOP), the
 * JSON IBM CDC envelope (with or without Avro-JSON union wrappers), and the Avro envelope (raw or
 * Confluent-framed). DB2 CHAR padding is added to key columns for a fixed share of rows; the
 * choice is per row, never per message, so every message for a row has identical key bytes and
 * lands on the same partition, as it would from a real producer.
 */
final class Encoder {

  enum Format { FLAT, ENVELOPE, AVRO }

  record Message(String topic, byte[] key, byte[] value) {}

  private static final Schema ENVELOPE = loadSchema();
  private static final long FORMAT = 101, PAD = 102, WRAP = 103, FRAME = 104;

  private final long seed;
  private final String topicPrefix;
  private final Map<Format, Integer> weights;
  private final int totalWeight;
  private final double padShare;
  private final GenericDatumWriter<GenericRecord> avroWriter = new GenericDatumWriter<>(ENVELOPE);
  private long sequence;

  Encoder(long seed, String topicPrefix, Map<Format, Integer> weights, double padShare) {
    this.seed = seed;
    this.topicPrefix = topicPrefix;
    this.weights = weights;
    this.totalWeight = weights.values().stream().mapToInt(Integer::intValue).sum();
    this.padShare = padShare;
    if (totalWeight <= 0) {
      throw new IllegalArgumentException("format weights must add up to more than 0");
    }
  }

  String topic(SourceTable table) {
    return topicPrefix + table.defaultTopic();
  }

  /** An upsert of {@code row}, or a delete of the row whose last image is {@code row}. */
  Message encode(SourceTable table, Map<String, Object> row, boolean delete) {
    long n = sequence++;
    String canonical = Keys.of(row, table.keyColumns());
    boolean pad = Mix.frac(Mix.hash(seed, PAD, canonical.hashCode(), table.ordinal())) < padShare;
    Map<String, Object> image = pad ? padKeyColumns(table.keyColumns(), row) : row;

    Map<String, Object> key = new LinkedHashMap<>();
    for (String column : table.keyColumns()) {
      key.put(column, image.get(column));
    }
    byte[] keyBytes = Json.write(key);

    Format format = pick(Mix.hash(seed, FORMAT, n));
    byte[] value =
        switch (format) {
          case FLAT -> delete ? null : Json.write(image);
          case ENVELOPE -> {
            Map<String, Object> envelope = new LinkedHashMap<>();
            envelope.put("op", delete ? "D" : "U");
            boolean wrap = Mix.frac(Mix.hash(seed, WRAP, n)) < 0.5;
            Map<String, Object> body = wrap ? wrapUnions(image) : image;
            envelope.put("before", delete ? body : null);
            envelope.put("after", delete ? null : body);
            envelope.put("ts_ms", 1_780_000_000_000L + n);
            yield Json.write(envelope);
          }
          case AVRO -> avro(delete, image, Mix.frac(Mix.hash(seed, FRAME, n)) < 0.5);
        };
    return new Message(topic(table), keyBytes, value);
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
    row.forEach((column, value) -> {
      if (value instanceof String) {
        wrapped.put(column, Map.of("string", value));
      } else if (value instanceof Long) {
        wrapped.put(column, Map.of("long", value));
      } else {
        wrapped.put(column, value);
      }
    });
    return wrapped;
  }

  private byte[] avro(boolean delete, Map<String, Object> row, boolean confluentFrame) {
    Map<String, Object> columns = new LinkedHashMap<>();
    row.forEach((column, value) ->
        columns.put(column, value instanceof BigDecimal decimal ? decimal.toPlainString() : value));
    GenericRecord envelope = new GenericData.Record(ENVELOPE);
    envelope.put("op", delete ? "D" : "U");
    envelope.put("before", delete ? columns : null);
    envelope.put("after", delete ? null : columns);
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      if (confluentFrame) {
        out.write(ByteBuffer.allocate(5).put((byte) 0).putInt(1).array());
      }
      BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(out, null);
      avroWriter.write(envelope, encoder);
      encoder.flush();
      return out.toByteArray();
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }

  static Map<Format, Integer> parseWeights(String spec) {
    Map<Format, Integer> weights = new LinkedHashMap<>();
    for (String part : spec.split(",")) {
      String[] kv = part.trim().split("[=:]");
      weights.put(Format.valueOf(kv[0].trim().toUpperCase(java.util.Locale.ROOT)), Integer.parseInt(kv[1].trim()));
    }
    return weights;
  }

  private static Schema loadSchema() {
    try (InputStream in = Encoder.class.getResourceAsStream("/avro/cdc-envelope.avsc")) {
      return new Schema.Parser().parse(in);
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }
}
