package com.motion.catalogjoin.topology;

import com.motion.catalogjoin.CatalogConfig;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.streams.kstream.Repartitioned;
import org.apache.kafka.streams.state.KeyValueStore;
import org.apache.kafka.streams.state.StoreBuilder;

/**
 * How stores and internal topics are named and built. Names are part of the deployed state (the
 * snapshot test pins them), so they are made in exactly one place.
 */
public final class Stores {

  private Stores() {}

  public static String storeName(String name) {
    return name + "-store";
  }

  public static <V> Materialized<String, V, KeyValueStore<Bytes, byte[]>> materialized(String name, Serde<V> values) {
    return Materialized.<String, V, KeyValueStore<Bytes, byte[]>>as(storeName(name))
        .withKeySerde(Serdes.String())
        .withValueSerde(values);
  }

  /** A repartition topic; uses catalog.partitions when set. */
  public static <V> Repartitioned<String, V> repartitioned(String name, Serde<V> values, CatalogConfig config) {
    Repartitioned<String, V> repartitioned =
        Repartitioned.<String, V>as(name).withKeySerde(Serdes.String()).withValueSerde(values);
    return config.partitions() == null ? repartitioned : repartitioned.withNumberOfPartitions(config.partitions());
  }

  public static <V> StoreBuilder<KeyValueStore<String, V>> keyValueStore(String name, Serde<V> values) {
    return org.apache.kafka.streams.state.Stores.keyValueStoreBuilder(
        org.apache.kafka.streams.state.Stores.persistentKeyValueStore(name), Serdes.String(), values);
  }
}
