package com.motion.catalogjoin.ingest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.SourceTable;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.BinaryEncoder;
import org.apache.avro.io.EncoderFactory;
import org.junit.jupiter.api.Test;

class CdcDecoderTest {

  private final CdcDecoder decoder = decoder(PayloadFormat.AVRO_OR_JSON);

  private static CdcDecoder decoder(PayloadFormat format) {
    Properties props = new Properties();
    props.setProperty("catalog.payload-format", format.name());
    return new CdcDecoder(CatalogConfig.of(props));
  }

  private static byte[] utf8(String text) {
    return text == null ? null : text.getBytes(StandardCharsets.UTF_8);
  }

  /** Decodes a message that must produce exactly one change. */
  private static Decoded one(List<Decoded> changes) {
    assertThat(changes).hasSize(1);
    return changes.get(0);
  }

  private Decoded json(SourceTable table, String key, String value) throws InvalidRecordException {
    return one(decoder.decode(table, utf8(key), utf8(value)));
  }

  // --- JSON -----------------------------------------------------------------------------------

  @Test
  void flatJsonMergesKeyFirstAndValueOverwrites() throws Exception {
    Decoded d = json(SourceTable.ITEM_PROFILE, "{\"item_no\":\"KEY\",\"EXTRA\":\"from-key\"}", "{\"ITEM_NO\":\"123\",\"descr\":\"x\"}");
    assertThat(d.key()).isEqualTo("{\"ITEM_NO\":\"123\"}");
    assertThat(d.row()).containsEntry("ITEM_NO", "123").containsEntry("DESCR", "x").containsEntry("EXTRA", "from-key");
  }

  @Test
  void jsonEnvelopeUsesAfterImage() throws Exception {
    Decoded d = json(SourceTable.MFR_PROFILE, "{\"MFR_CTL_NO\":\"AB\"}",
        "{\"op\":\"U\",\"before\":{\"MFR_CTL_NO\":\"AB\",\"SELLABLE\":\"Y\"},\"after\":{\"MFR_CTL_NO\":\"AB\",\"SELLABLE\":\"N\"},\"ts_ms\":1}");
    assertThat(d.isDelete()).isFalse();
    assertThat(d.row()).containsEntry("SELLABLE", "N").doesNotContainKeys("OP", "BEFORE", "AFTER", "TS_MS");
  }

  @Test
  void jsonEnvelopeDeleteUsesBeforeImageForTheKey() throws Exception {
    Decoded d = json(SourceTable.MFR_PROFILE, null, "{\"op\":\"D\",\"before\":{\"MFR_CTL_NO\":\"AB\"},\"after\":null}");
    assertThat(d.isDelete()).isTrue();
    assertThat(d.key()).isEqualTo("{\"MFR_CTL_NO\":\"AB\"}");
  }

  @Test
  void avroJsonUnionWrappersAreUnwrappedRecursively() throws Exception {
    Decoded d = json(SourceTable.ITEM_PROFILE, "{\"ITEM_NO\":{\"string\":\"1\"}}",
        "{\"ITEM_NO\":{\"string\":\"1\"},\"QTY\":{\"long\":5},\"PRICE\":{\"double\":2.5},\"NOTE\":{\"null\":null},\"WRAPPED\":{\"STRING\":{\"string\":\"x\"}}}");
    assertThat(d.row())
        .containsEntry("ITEM_NO", "1")
        .containsEntry("QTY", 5)
        .containsEntry("NOTE", null)
        .containsEntry("WRAPPED", "x");
    assertThat((BigDecimal) d.row().get("PRICE")).isEqualByComparingTo("2.5");
  }

  @Test
  void tombstoneVariantsAreDeletes() throws Exception {
    for (String value : new String[] {null, "", "null", "  null "}) {
      Decoded d = json(SourceTable.ITEM_PROFILE, "{\"ITEM_NO\":\"1\"}", value);
      assertThat(d.isDelete()).as("value %s", value).isTrue();
      assertThat(d.key()).isEqualTo("{\"ITEM_NO\":\"1\"}");
    }
  }

  @Test
  void tombstoneWithoutKeyIsInvalid() {
    assertThatThrownBy(() -> json(SourceTable.ITEM_PROFILE, null, null))
        .isInstanceOf(InvalidRecordException.class);
    assertThatThrownBy(() -> json(SourceTable.ITEM_PROFILE, "{}", null))
        .isInstanceOf(InvalidRecordException.class);
  }

  @Test
  void missingKeyColumnIsInvalid() {
    assertThatThrownBy(() -> json(SourceTable.ITEM_BALANCE, "{\"ITEM_NO\":\"1\"}", "{\"ITEM_NO\":\"1\",\"MI_LOC\":\"2\"}"))
        .isInstanceOf(InvalidRecordException.class)
        .hasMessageContaining("STOREROOM_NO");
  }

  @Test
  void canonicalKeysSortColumnsAndTrimValues() throws Exception {
    Decoded d = json(SourceTable.NON_COS_ITEM_BALANCE, "{\"MI_LOC\":\" 01 \",\"ITEM_NO\":100}", "{\"QTY\":1}");
    assertThat(d.key()).isEqualTo("{\"ITEM_NO\":\"100\",\"MI_LOC\":\"01\"}");
  }

  @Test
  void plainStringKeyWorksForSingleColumnTables() throws Exception {
    Decoded d = json(SourceTable.ITEM_PROFILE, "ABC-1", null);
    assertThat(d.key()).isEqualTo("{\"ITEM_NO\":\"ABC-1\"}");
  }

  @Test
  void nulBytesAreStrippedAndLastEventAtIsDropped() throws Exception {
    Decoded d = json(SourceTable.ITEM_PROFILE, null, "{\"ITEM_NO\":\"1\",\"DESCR\":\"a\\u0000b\",\"last_event_at\":\"2026-01-01\"}");
    assertThat(d.row()).containsEntry("DESCR", "ab").doesNotContainKey("LAST_EVENT_AT");
  }

  @Test
  void garbageIsInvalid() {
    assertThatThrownBy(() -> json(SourceTable.ITEM_PROFILE, "{\"ITEM_NO\":\"1\"}", "<xml/>"))
        .isInstanceOf(InvalidRecordException.class);
    assertThatThrownBy(() -> json(SourceTable.ITEM_PROFILE, "{\"ITEM_NO\":\"1\"}", "[1,2]"))
        .isInstanceOf(InvalidRecordException.class);
  }

  @Test
  void jsonOnlyRejectsAvro() throws Exception {
    CdcDecoder jsonOnly = decoder(PayloadFormat.JSON_ONLY);
    byte[] avro = avro("I", null, Map.of("ITEM_NO", "1"));
    assertThatThrownBy(() -> jsonOnly.decode(SourceTable.ITEM_PROFILE, null, avro))
        .isInstanceOf(InvalidRecordException.class);
  }

  @Test
  void avroOnlyRejectsJson() {
    CdcDecoder avroOnly = decoder(PayloadFormat.AVRO_ONLY);
    assertThatThrownBy(() -> avroOnly.decode(SourceTable.ITEM_PROFILE, null, utf8("{\"ITEM_NO\":\"1\"}")))
        .isInstanceOf(InvalidRecordException.class);
  }

  @Test
  void deleteEnvelopeWithoutBeforeImageUsesTheKey() throws Exception {
    Decoded d = json(SourceTable.ITEM_PROFILE, "{\"ITEM_NO\":\"9\"}", "{\"op\":\"D\",\"before\":null,\"after\":null}");
    assertThat(d.isDelete()).isTrue();
    assertThat(d.key()).isEqualTo("{\"ITEM_NO\":\"9\"}");
  }

  @Test
  void envelopeFieldNamesAreCaseInsensitive() throws Exception {
    Decoded d = json(SourceTable.ITEM_PROFILE, null, "{\"OP\":\"U\",\"AFTER\":{\"ITEM_NO\":\"1\",\"DESCR\":\"x\"}}");
    assertThat(d.row()).containsOnlyKeys("ITEM_NO", "DESCR");
  }

  @Test
  void updateThatChangesTheKeyDeletesTheOldRow() throws Exception {
    List<Decoded> changes = decoder.decode(SourceTable.ITEM_PROFILE, null,
        utf8("{\"op\":\"U\",\"before\":{\"ITEM_NO\":\"1\"},\"after\":{\"ITEM_NO\":\"2\"}}"));
    assertThat(changes).extracting(Decoded::key).containsExactly("{\"ITEM_NO\":\"1\"}", "{\"ITEM_NO\":\"2\"}");
    assertThat(changes.get(0).isDelete()).isTrue();
    assertThat(changes.get(1).isDelete()).isFalse();
  }

  @Test
  void rawNulBytesInJsonAreStripped() throws Exception {
    char nul = 0;
    Decoded d = json(SourceTable.ITEM_PROFILE, null, "{\"ITEM_NO\":\"1\",\"DESCR\":\"a" + nul + "b\"}");
    assertThat(d.row()).containsEntry("DESCR", "ab");
  }

  @Test
  void binarySingleColumnKeysAreIgnored() throws Exception {
    byte[] avroStringKey = {0x06, 'A', 'B', 'C'};
    Decoded d = one(decoder.decode(SourceTable.ITEM_PROFILE, avroStringKey, utf8("{\"ITEM_NO\":\"XYZ\"}")));
    assertThat(d.key()).isEqualTo("{\"ITEM_NO\":\"XYZ\"}");
    assertThatThrownBy(() -> decoder.decode(SourceTable.ITEM_PROFILE, avroStringKey, null))
        .isInstanceOf(InvalidRecordException.class);
  }

  @Test
  void stepValuesKeepWhitespaceInTheirKeySoEditsDoNotCollide() throws Exception {
    String key = "{\"STEP_PRODUCT_ID\":\"P\",\"STEP_ATTRIBUTE_ID\":\"A\",\"STEP_UNIT_ID\":\" \",\"VALUE\":\"%s\"}";
    Decoded plain = json(SourceTable.STEP_PRODUCT_VALUES, key.formatted("x"), null);
    Decoded spaced = json(SourceTable.STEP_PRODUCT_VALUES, key.formatted("x "), null);
    assertThat(plain.key()).isNotEqualTo(spaced.key());
    assertThat(plain.key()).contains("\"STEP_UNIT_ID\":\"\"");
  }

  @Test
  void droppedColumnsComeFromConfiguration() throws Exception {
    Properties props = new Properties();
    props.setProperty("catalog.ingest.dropped-columns", "secret, last_event_at");
    CdcDecoder custom = new CdcDecoder(CatalogConfig.of(props));
    Decoded d = one(custom.decode(SourceTable.ITEM_PROFILE, null, utf8("{\"ITEM_NO\":\"1\",\"SECRET\":\"s\",\"LAST_EVENT_AT\":1}")));
    assertThat(d.row()).containsOnlyKeys("ITEM_NO");
  }

  @Test
  void avroJsonWrappersForMapsAndNamedRecordsAreUnwrapped() throws Exception {
    Decoded map = json(SourceTable.ITEM_PROFILE, null, "{\"op\":\"U\",\"after\":{\"map\":{\"ITEM_NO\":{\"string\":\"1\"}}}}");
    assertThat(map.row()).containsEntry("ITEM_NO", "1");
    Decoded named = json(SourceTable.ITEM_PROFILE, null, "{\"op\":\"U\",\"after\":{\"com.ibm.cdc.Row\":{\"ITEM_NO\":\"2\"}}}");
    assertThat(named.row()).containsEntry("ITEM_NO", "2");
  }

  @Test
  void nestedValuesAreRejected() {
    assertThatThrownBy(() -> json(SourceTable.ITEM_PROFILE, null, "{\"ITEM_NO\":\"1\",\"DETAIL\":{\"a\":1,\"b\":2}}"))
        .isInstanceOf(InvalidRecordException.class).hasMessageContaining("DETAIL");
  }

  @Test
  void nullAndStructuredTextAreNotSingleColumnKeys() {
    for (String key : new String[] {"null", "[1]", "true", "{broken", "1.5"}) {
      assertThatThrownBy(() -> json(SourceTable.ITEM_PROFILE, key, null)).as(key).isInstanceOf(InvalidRecordException.class);
    }
  }

  // --- Avro -----------------------------------------------------------------------------------

  @Test
  void rawAvroInsert() throws Exception {
    Map<String, Object> after = new HashMap<>();
    after.put("ITEM_NO", "1");
    after.put("qty", 3L);
    after.put("weight", 1.25f);
    after.put("blob", ByteBuffer.wrap(new byte[] {1, 2}));
    after.put("gone", null);
    Decoded d = one(decoder.decode(SourceTable.ITEM_PROFILE, null, avro("I", null, after)));
    assertThat(d.key()).isEqualTo("{\"ITEM_NO\":\"1\"}");
    assertThat(d.row()).containsEntry("QTY", 3L).containsEntry("BLOB", "AQI=").containsEntry("GONE", null);
    assertThat((BigDecimal) d.row().get("WEIGHT")).isEqualByComparingTo("1.25");
  }

  @Test
  void confluentFramedAvroDelete() throws Exception {
    byte[] body = avro("D", Map.of("ITEM_NO", "7"), null);
    byte[] framed = ByteBuffer.allocate(5 + body.length).put((byte) 0).putInt(42).put(body).array();
    Decoded d = one(decoder.decode(SourceTable.ITEM_PROFILE, null, framed));
    assertThat(d.isDelete()).isTrue();
    assertThat(d.key()).isEqualTo("{\"ITEM_NO\":\"7\"}");
  }

  @Test
  void avroUpdateWithoutAfterIsInvalid() {
    assertThatThrownBy(() -> decoder.decode(SourceTable.ITEM_PROFILE, utf8("{\"ITEM_NO\":\"1\"}"), avro("U", null, null)))
        .isInstanceOf(InvalidRecordException.class);
  }

  private static byte[] avro(String op, Map<String, Object> before, Map<String, Object> after) throws IOException {
    Schema schema = CdcEnvelope.SCHEMA;
    GenericRecord record = new GenericData.Record(schema);
    record.put("op", op);
    record.put("before", before);
    record.put("after", after);
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(out, null);
    new GenericDatumWriter<GenericRecord>(schema).write(record, encoder);
    encoder.flush();
    return out.toByteArray();
  }
}
