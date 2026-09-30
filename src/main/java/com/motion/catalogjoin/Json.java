package com.motion.catalogjoin;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.StreamWriteFeature;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;
import java.io.IOException;
import java.io.UncheckedIOException;
import org.apache.kafka.common.serialization.Deserializer;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.serialization.Serializer;

/**
 * The one JSON configuration used for state, keys and output. Serialization is deterministic
 * (map entries and properties sorted) so identical documents always produce identical bytes, which
 * is what emit-on-change and log compaction rely on.
 */
public final class Json {

  public static final ObjectMapper MAPPER =
      JsonMapper.builder()
          .enable(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS)
          .enable(StreamWriteFeature.WRITE_BIGDECIMAL_AS_PLAIN)
          .enable(MapperFeature.SORT_PROPERTIES_ALPHABETICALLY)
          .enable(DeserializationFeature.USE_BIG_DECIMAL_FOR_FLOATS)
          .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
          .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS)
          .build();

  private Json() {}

  public static byte[] write(Object value) {
    try {
      return MAPPER.writeValueAsBytes(value);
    } catch (JsonProcessingException e) {
      throw new UncheckedIOException(e);
    }
  }

  public static String writeString(Object value) {
    try {
      return MAPPER.writeValueAsString(value);
    } catch (JsonProcessingException e) {
      throw new UncheckedIOException(e);
    }
  }

  public static <T> Serde<T> serde(Class<T> type) {
    return serde(MAPPER.constructType(type));
  }

  public static <T> Serde<T> serde(TypeReference<T> type) {
    return serde(MAPPER.constructType(type));
  }

  private static <T> Serde<T> serde(JavaType type) {
    Serializer<T> serializer = (topic, value) -> value == null ? null : write(value);
    Deserializer<T> deserializer =
        (topic, bytes) -> {
          if (bytes == null) {
            return null;
          }
          try {
            return MAPPER.readValue(bytes, type);
          } catch (IOException e) {
            throw new UncheckedIOException(e);
          }
        };
    return Serdes.serdeFrom(serializer, deserializer);
  }
}
