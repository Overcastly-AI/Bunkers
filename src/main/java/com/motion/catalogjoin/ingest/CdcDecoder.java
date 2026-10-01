package com.motion.catalogjoin.ingest;

import com.fasterxml.jackson.core.json.JsonReadFeature;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.SourceTable;
import java.io.IOException;
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
import org.apache.avro.generic.GenericDatumReader;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.BinaryDecoder;
import org.apache.avro.io.DecoderFactory;

/**
 * Turns a raw CDC message (key bytes, value bytes) into rows with canonical keys.
 *
 * <p>Accepted value shapes:
 *
 * <ul>
 *   <li>Avro IBM CDC envelope ({@link CdcEnvelope#SCHEMA}), raw or Confluent wire format.
 *   <li>JSON IBM CDC envelope: an object with a string {@code op} and an {@code after} and/or
 *       {@code before} field (field names in any case). {@code op = "D"} is a delete.
 *   <li>Flat JSON (KCOP): the value object is the row.
 *   <li>Tombstone: null, empty, or the literal text {@code null}. The key identifies the row.
 * </ul>
 *
 * <p>The key, when it is a JSON object, is merged into the row first and value columns overwrite it.
 * A single-column key may also be a JSON scalar or printable text; binary keys are ignored. Column
 * names are upper-cased, Avro-JSON union wrappers ({@code {"string":"ABC"}}) are unwrapped, NUL
 * characters are stripped, decimals become {@link BigDecimal}, and the configured dropped columns
 * are removed. An update whose before image has a different key than its after image becomes a
 * delete of the old key plus an upsert of the new one.
 */
public final class CdcDecoder {

  private static final Set<String> UNION_BRANCHES =
      Set.of("NULL", "BOOLEAN", "INT", "LONG", "FLOAT", "DOUBLE", "STRING", "BYTES", "MAP", "ARRAY");
  /** Accepts raw control characters (NUL) inside strings; they are stripped afterwards. */
  private static final ObjectMapper LENIENT =
      Json.MAPPER.copy()
          .enable(JsonReadFeature.ALLOW_UNESCAPED_CONTROL_CHARS.mappedFeature())
          .enable(DeserializationFeature.FAIL_ON_TRAILING_TOKENS);

  private final CatalogConfig config;
  private final PayloadFormat format;
  private final Set<String> droppedColumns;
  private final GenericDatumReader<GenericRecord> avroReader = new GenericDatumReader<>(CdcEnvelope.SCHEMA);

  public CdcDecoder(CatalogConfig config) {
    this.config = config;
    this.format = config.payloadFormat();
    this.droppedColumns = config.droppedColumns();
  }

  /** One change, or two for an update that moved the row to a new key. */
  public List<Decoded> decode(SourceTable table, byte[] rawKey, byte[] rawValue) throws InvalidRecordException {
    try {
      return decodeChecked(table, rawKey, rawValue);
    } catch (NestedValueException e) {
      throw new InvalidRecordException(e.getMessage(), e);
    }
  }

  private List<Decoded> decodeChecked(SourceTable table, byte[] rawKey, byte[] rawValue) throws InvalidRecordException {
    Map<String, Object> keyColumns = decodeKey(table, rawKey);

    if (isTombstone(rawValue)) {
      if (keyColumns.isEmpty()) {
        throw new InvalidRecordException("Tombstone without a usable key");
      }
      return List.of(new Decoded(canonicalKey(table, keyColumns), null));
    }

    Change change = decodeValue(rawValue);
    if (change.delete()) {
      return List.of(new Decoded(canonicalKey(table, merge(keyColumns, change.before())), null));
    }
    Map<String, Object> row = merge(keyColumns, change.after());
    String key = canonicalKey(table, row);
    if (change.before() != null) {
      Map<String, Object> before = merge(keyColumns, change.before());
      if (hasKey(table, before)) {
        String oldKey = canonicalKey(table, before);
        if (!oldKey.equals(key)) {
          return List.of(new Decoded(oldKey, null), new Decoded(key, row));
        }
      }
    }
    return List.of(new Decoded(key, row));
  }

  private static Map<String, Object> merge(Map<String, Object> keyColumns, Map<String, Object> image) {
    Map<String, Object> merged = new LinkedHashMap<>(keyColumns);
    if (image != null) {
      merged.putAll(image);
    }
    return merged;
  }

  // --- key -------------------------------------------------------------------------------------

  private Map<String, Object> decodeKey(SourceTable table, byte[] rawKey) {
    if (rawKey == null || rawKey.length == 0) {
      return Map.of();
    }
    List<String> keyColumns = config.keyColumns(table);
    try {
      JsonNode node = LENIENT.readTree(rawKey);
      Object value = node == null ? null : toJava(node);
      if (value instanceof Map<?, ?> map) {
        return normalizeRow(map);
      }
      // A single-column key may be a JSON string or integer; null, arrays and other scalars are not keys.
      boolean scalar = value instanceof String || (value instanceof Number && node.isIntegralNumber());
      return scalar && keyColumns.size() == 1 ? Map.of(keyColumns.get(0), normalizeValue(value)) : Map.of();
    } catch (IOException | RuntimeException notJson) {
      // Not JSON; fall through.
    }
    if (keyColumns.size() == 1) {
      String text = printableUtf8(rawKey);
      if (text != null && !text.isBlank() && "{[".indexOf(text.charAt(0)) < 0) {
        return Map.of(keyColumns.get(0), text);
      }
    }
    // Binary (e.g. Avro) keys are not decoded; the key columns must then come from the value.
    return Map.of();
  }

  private boolean hasKey(SourceTable table, Map<String, Object> columns) {
    return config.keyColumns(table).stream().allMatch(c -> columns.get(c) != null);
  }

  private String canonicalKey(SourceTable table, Map<String, Object> columns) throws InvalidRecordException {
    for (String column : config.keyColumns(table)) {
      if (columns.get(column) == null) {
        throw new InvalidRecordException("Missing key column " + column);
      }
    }
    return config.key(table, columns);
  }

  // --- value -----------------------------------------------------------------------------------

  /** A decoded value: an upsert (after, optionally before) or a delete (before, possibly null). */
  private record Change(boolean delete, Map<String, Object> before, Map<String, Object> after) {}

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
    if (value.length > CdcEnvelope.CONFLUENT_HEADER_BYTES && value[0] == CdcEnvelope.CONFLUENT_MAGIC) {
      offset = CdcEnvelope.CONFLUENT_HEADER_BYTES;
    }
    GenericRecord envelope;
    try {
      BinaryDecoder decoder = DecoderFactory.get().binaryDecoder(value, offset, value.length - offset, null);
      envelope = avroReader.read(null, decoder);
      if (!decoder.isEnd()) {
        throw new InvalidRecordException("Trailing bytes after Avro envelope");
      }
    } catch (IOException | RuntimeException e) {
      throw new InvalidRecordException("Not an Avro CDC envelope: " + e.getMessage(), e);
    }
    return change(String.valueOf(envelope.get(CdcEnvelope.OP)),
        avroMap(envelope.get(CdcEnvelope.BEFORE)), avroMap(envelope.get(CdcEnvelope.AFTER)), "Avro");
  }

  private static Change change(String op, Map<String, Object> before, Map<String, Object> after, String source)
      throws InvalidRecordException {
    String code = op.trim().toUpperCase(Locale.ROOT);
    if (code.equals(CdcEnvelope.DELETE)) {
      return new Change(true, before, null);
    }
    if (code.equals(CdcEnvelope.INSERT) || code.equals(CdcEnvelope.UPDATE)) {
      if (after == null) {
        throw new InvalidRecordException(source + " envelope op " + code + " without '" + CdcEnvelope.AFTER + "'");
      }
      return new Change(false, before, after);
    }
    throw new InvalidRecordException("Unknown " + source + " envelope op '" + op + "'");
  }

  private Map<String, Object> avroMap(Object value) {
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
      node = LENIENT.readTree(value);
    } catch (IOException e) {
      throw new InvalidRecordException("Value is neither Avro nor JSON: " + e.getMessage(), e);
    }
    Object parsed = node == null ? null : toJava(node);
    if (!(parsed instanceof Map<?, ?> object)) {
      throw new InvalidRecordException("JSON value is not an object");
    }
    Map<String, Object> fields = new LinkedHashMap<>();
    object.forEach((k, v) -> fields.put(String.valueOf(k).toLowerCase(Locale.ROOT), v));
    boolean envelope = fields.get(CdcEnvelope.OP) instanceof String
        && (fields.containsKey(CdcEnvelope.AFTER) || fields.containsKey(CdcEnvelope.BEFORE));
    if (!envelope) {
      return new Change(false, null, normalizeRow(object));
    }
    return change((String) fields.get(CdcEnvelope.OP), jsonImage(fields.get(CdcEnvelope.BEFORE)),
        jsonImage(fields.get(CdcEnvelope.AFTER)), "JSON");
  }

  private Map<String, Object> jsonImage(Object image) throws InvalidRecordException {
    if (image == null) {
      return null;
    }
    if (!(image instanceof Map<?, ?> map)) {
      throw new InvalidRecordException("JSON envelope image is not an object");
    }
    // Avro-JSON wraps a named record type as {"full.Name": {...}}.
    if (map.size() == 1 && map.values().iterator().next() instanceof Map<?, ?> inner) {
      map = inner;
    }
    return normalizeRow(map);
  }

  // --- normalization ---------------------------------------------------------------------------

  /** Upper-cased columns, dropped columns removed; rows are flat, so nested values are rejected. */
  private Map<String, Object> normalizeRow(Map<?, ?> source) {
    Map<String, Object> row = new LinkedHashMap<>();
    for (Map.Entry<?, ?> entry : source.entrySet()) {
      String column = stripNul(String.valueOf(entry.getKey())).trim().toUpperCase(Locale.ROOT);
      if (entry.getValue() instanceof Map<?, ?> || entry.getValue() instanceof List<?>) {
        throw new NestedValueException(column);
      }
      if (!droppedColumns.contains(column)) {
        row.put(column, normalizeValue(entry.getValue()));
      }
    }
    return row;
  }

  /** Unchecked so it can leave lambdas; turned into an invalid record by {@link #decode}. */
  private static final class NestedValueException extends RuntimeException {
    NestedValueException(String column) {
      super("Column " + column + " holds a nested value; rows must be flat");
    }
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

  /** UTF-8 text without control characters, or null (binary keys such as Avro start with one). */
  private static String printableUtf8(byte[] bytes) {
    String text;
    try {
      text = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(bytes))
          .toString();
    } catch (CharacterCodingException e) {
      return null;
    }
    return text.chars().anyMatch(Character::isISOControl) ? null : text;
  }
}
