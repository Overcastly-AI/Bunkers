package com.motion.catalogjoin.ingest;

import com.fasterxml.jackson.databind.JsonNode;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.SourceTable;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.math.BigDecimal;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericDatumReader;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.BinaryDecoder;
import org.apache.avro.io.DecoderFactory;

/**
 * Turns a raw CDC message (key bytes, value bytes) into a {@link Decoded} row with a canonical key.
 *
 * <p>Accepted value shapes:
 *
 * <ul>
 *   <li>Avro IBM CDC envelope ({@code cdc-envelope.avsc}), raw or Confluent wire format.
 *   <li>JSON IBM CDC envelope: an object with a string {@code op} and an object {@code after} (or,
 *       for {@code op = "D"}, an object {@code before}).
 *   <li>Flat JSON (KCOP): the value object is the row.
 *   <li>Tombstone: null, empty, or the literal text {@code null}. The key identifies the row.
 * </ul>
 *
 * <p>The key, when it is a JSON object, is merged into the row first and value columns overwrite it.
 * Column names are upper-cased, Avro-JSON union wrappers ({@code {"string":"ABC"}}) are unwrapped,
 * NUL characters are stripped, decimals become {@link BigDecimal}, and the service-managed {@code
 * LAST_EVENT_AT} column is dropped.
 */
public final class CdcDecoder {

  private static final Schema ENVELOPE_SCHEMA = loadSchema();
  private static final Set<String> UNION_BRANCHES =
      Set.of("NULL", "BOOLEAN", "INT", "LONG", "FLOAT", "DOUBLE", "STRING", "BYTES");
  private static final String DROPPED_COLUMN = "LAST_EVENT_AT";

  private final PayloadFormat format;
  private final GenericDatumReader<GenericRecord> avroReader =
      new GenericDatumReader<>(ENVELOPE_SCHEMA);

  public CdcDecoder(PayloadFormat format) {
    this.format = format;
  }

  public Decoded decode(SourceTable table, byte[] rawKey, byte[] rawValue)
      throws InvalidRecordException {
    Map<String, Object> keyColumns = decodeKey(table, rawKey);

    if (isTombstone(rawValue)) {
      if (keyColumns.isEmpty()) {
        throw new InvalidRecordException("Tombstone without a usable key");
      }
      return new Decoded(canonicalKey(table, keyColumns), null);
    }

    Change change = decodeValue(rawValue);
    Map<String, Object> merged = new LinkedHashMap<>(keyColumns);
    if (change.row() != null) {
      merged.putAll(change.row());
    }
    String key = canonicalKey(table, merged);
    return new Decoded(key, change.delete() ? null : merged);
  }

  // --- key -------------------------------------------------------------------------------------

  private Map<String, Object> decodeKey(SourceTable table, byte[] rawKey) {
    if (rawKey == null || rawKey.length == 0) {
      return Map.of();
    }
    try {
      JsonNode node = Json.MAPPER.readTree(rawKey);
      Object value = node == null ? null : toJava(node);
      if (value instanceof Map<?, ?> map) {
        return normalizeRow(map);
      }
      if (value != null && !(value instanceof List<?>) && table.keyColumns().size() == 1) {
        return Map.of(table.keyColumns().get(0), value);
      }
    } catch (IOException | RuntimeException notJson) {
      // Not a JSON key; fall through.
    }
    if (table.keyColumns().size() == 1) {
      String text = utf8(rawKey);
      if (text != null && !text.isBlank()) {
        return Map.of(table.keyColumns().get(0), stripNul(text));
      }
    }
    // Binary (e.g. Avro) keys are not decoded; the key columns must then come from the value.
    return Map.of();
  }

  private static String canonicalKey(SourceTable table, Map<String, Object> columns)
      throws InvalidRecordException {
    for (String column : table.keyColumns()) {
      if (columns.get(column) == null) {
        throw new InvalidRecordException("Missing key column " + column);
      }
    }
    return Keys.of(columns, table.keyColumns());
  }

  // --- value -----------------------------------------------------------------------------------

  private record Change(boolean delete, Map<String, Object> row) {}

  private static boolean isTombstone(byte[] value) {
    if (value == null || value.length == 0) {
      return true;
    }
    if (value.length > 16) {
      return false;
    }
    String text = new String(value, StandardCharsets.UTF_8).trim();
    return text.isEmpty() || text.equals("null");
  }

  private Change decodeValue(byte[] value) throws InvalidRecordException {
    boolean looksLikeJson = firstNonWhitespace(value) == '{';
    InvalidRecordException avroFailure = null;
    if (format != PayloadFormat.JSON_ONLY && !(looksLikeJson && format == PayloadFormat.AVRO_OR_JSON)) {
      try {
        return decodeAvro(value);
      } catch (InvalidRecordException e) {
        if (format == PayloadFormat.AVRO_ONLY) {
          throw e;
        }
        avroFailure = e;
      }
    }
    try {
      return decodeJson(value);
    } catch (InvalidRecordException e) {
      if (avroFailure != null) {
        e.addSuppressed(avroFailure);
      }
      throw e;
    }
  }

  private Change decodeAvro(byte[] value) throws InvalidRecordException {
    int offset = 0;
    if (value.length > 5 && value[0] == 0) {
      offset = 5; // Confluent wire format: magic byte 0x00 + 4-byte schema id.
    }
    GenericRecord envelope;
    try {
      BinaryDecoder decoder =
          DecoderFactory.get().binaryDecoder(value, offset, value.length - offset, null);
      envelope = avroReader.read(null, decoder);
      if (!decoder.isEnd()) {
        throw new InvalidRecordException("Trailing bytes after Avro envelope");
      }
    } catch (IOException | RuntimeException e) {
      throw new InvalidRecordException("Not an Avro CDC envelope: " + e.getMessage(), e);
    }
    String op = String.valueOf(envelope.get("op")).trim().toUpperCase(Locale.ROOT);
    Map<String, Object> before = avroMap(envelope.get("before"));
    Map<String, Object> after = avroMap(envelope.get("after"));
    return switch (op) {
      case "D" -> new Change(true, before);
      case "I", "U" -> {
        if (after == null) {
          throw new InvalidRecordException("Avro envelope op " + op + " without 'after'");
        }
        yield new Change(false, after);
      }
      default -> throw new InvalidRecordException("Unknown Avro envelope op '" + op + "'");
    };
  }

  private static Map<String, Object> avroMap(Object value) {
    if (!(value instanceof Map<?, ?> map)) {
      return null;
    }
    Map<String, Object> out = new LinkedHashMap<>();
    for (Map.Entry<?, ?> entry : map.entrySet()) {
      out.put(String.valueOf(entry.getKey()), fromAvro(entry.getValue()));
    }
    return normalizeRow(out);
  }

  private static Object fromAvro(Object value) {
    if (value instanceof CharSequence text) {
      return text.toString();
    }
    if (value instanceof ByteBuffer buffer) {
      ByteBuffer copy = buffer.duplicate();
      byte[] bytes = new byte[copy.remaining()];
      copy.get(bytes);
      return Base64.getEncoder().encodeToString(bytes);
    }
    return value;
  }

  private Change decodeJson(byte[] value) throws InvalidRecordException {
    JsonNode node;
    try {
      node = Json.MAPPER.readTree(value);
    } catch (IOException e) {
      throw new InvalidRecordException("Value is neither Avro nor JSON: " + e.getMessage(), e);
    }
    Object parsed = node == null ? null : toJava(node);
    if (!(parsed instanceof Map<?, ?> object)) {
      throw new InvalidRecordException("JSON value is not an object");
    }
    Object op = object.get("op");
    Object after = object.get("after");
    Object before = object.get("before");
    if (op instanceof String opText) {
      boolean delete = opText.trim().equalsIgnoreCase("D");
      if (after instanceof Map<?, ?> afterRow && !delete) {
        return new Change(false, normalizeRow(afterRow));
      }
      if (delete && (before instanceof Map<?, ?> || after instanceof Map<?, ?>)) {
        Map<?, ?> image = before instanceof Map<?, ?> b ? b : (Map<?, ?>) after;
        return new Change(true, normalizeRow(image));
      }
    }
    return new Change(false, normalizeRow(object));
  }

  // --- normalization ---------------------------------------------------------------------------

  private static Map<String, Object> normalizeRow(Map<?, ?> source) {
    Map<String, Object> row = new LinkedHashMap<>();
    for (Map.Entry<?, ?> entry : source.entrySet()) {
      String column = String.valueOf(entry.getKey()).trim().toUpperCase(Locale.ROOT);
      if (column.equals(DROPPED_COLUMN)) {
        continue;
      }
      row.put(column, normalizeValue(entry.getValue()));
    }
    return row;
  }

  private static Object normalizeValue(Object value) {
    if (value instanceof String text) {
      return stripNul(text);
    }
    if (value instanceof Float f) {
      return Float.isFinite(f) ? new BigDecimal(Float.toString(f)) : f.toString();
    }
    if (value instanceof Double d) {
      return Double.isFinite(d) ? BigDecimal.valueOf(d) : d.toString();
    }
    return value;
  }

  /** JSON tree to plain Java values, collapsing Avro-JSON union wrappers. */
  private static Object toJava(JsonNode node) {
    if (node.isObject() && node.size() == 1) {
      String field = node.fieldNames().next();
      if (UNION_BRANCHES.contains(field.toUpperCase(Locale.ROOT))) {
        return toJava(node.get(field));
      }
    }
    if (node.isObject()) {
      Map<String, Object> map = new LinkedHashMap<>();
      Iterator<Map.Entry<String, JsonNode>> fields = node.fields();
      while (fields.hasNext()) {
        Map.Entry<String, JsonNode> field = fields.next();
        map.put(field.getKey(), toJava(field.getValue()));
      }
      return map;
    }
    if (node.isArray()) {
      List<Object> list = new ArrayList<>();
      node.forEach(element -> list.add(toJava(element)));
      return list;
    }
    if (node.isNull() || node.isMissingNode()) {
      return null;
    }
    if (node.isTextual()) {
      return node.textValue();
    }
    if (node.isIntegralNumber()) {
      return node.numberValue();
    }
    if (node.isNumber()) {
      return node.decimalValue();
    }
    if (node.isBoolean()) {
      return node.booleanValue();
    }
    if (node.isBinary()) {
      try {
        return Base64.getEncoder().encodeToString(node.binaryValue());
      } catch (IOException e) {
        throw new UncheckedIOException(e);
      }
    }
    return node.asText();
  }

  private static String stripNul(String text) {
    return text.indexOf('\u0000') < 0 ? text : text.replace("\u0000", "");
  }

  private static int firstNonWhitespace(byte[] bytes) {
    for (byte b : bytes) {
      if (!Character.isWhitespace(b)) {
        return b;
      }
    }
    return -1;
  }

  private static String utf8(byte[] bytes) {
    try {
      return StandardCharsets.UTF_8
          .newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(bytes))
          .toString();
    } catch (CharacterCodingException e) {
      return null;
    }
  }

  private static Schema loadSchema() {
    try (InputStream in = CdcDecoder.class.getResourceAsStream("/avro/cdc-envelope.avsc")) {
      if (in == null) {
        throw new IllegalStateException("avro/cdc-envelope.avsc not on classpath");
      }
      return new Schema.Parser().parse(in);
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }
}
