package com.motion.catalogjoin.topology;

import com.motion.catalogjoin.Json;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import org.apache.kafka.streams.processor.api.FixedKeyProcessor;
import org.apache.kafka.streams.processor.api.FixedKeyProcessorContext;
import org.apache.kafka.streams.processor.api.FixedKeyRecord;
import org.apache.kafka.streams.state.KeyValueStore;

/**
 * Last step before an output topic. Serializes the document and forwards it only when its bytes
 * differ from what was last published for the key; a delete is forwarded only for a key that was
 * published. Upstream joins re-emit whenever any input changes, even when the joined result is
 * the same, so this keeps the compacted output free of no-op updates.
 */
final class EmitOnChange<V> implements FixedKeyProcessor<String, V, byte[]> {

  private final String storeName;
  private FixedKeyProcessorContext<String, byte[]> context;
  private KeyValueStore<String, byte[]> published;

  EmitOnChange(String storeName) {
    this.storeName = storeName;
  }

  @Override
  public void init(FixedKeyProcessorContext<String, byte[]> context) {
    this.context = context;
    this.published = context.getStateStore(storeName);
  }

  @Override
  public void process(FixedKeyRecord<String, V> record) {
    if (record.value() == null) {
      if (published.delete(record.key()) != null) {
        context.forward(record.withValue(null));
      }
      return;
    }
    byte[] bytes = Json.write(record.value());
    byte[] digest = digest(bytes);
    if (!Arrays.equals(digest, published.get(record.key()))) {
      published.put(record.key(), digest);
      context.forward(record.withValue(bytes));
    }
  }

  private static byte[] digest(byte[] bytes) {
    try {
      return Arrays.copyOf(MessageDigest.getInstance("SHA-256").digest(bytes), 16);
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException(e);
    }
  }
}
