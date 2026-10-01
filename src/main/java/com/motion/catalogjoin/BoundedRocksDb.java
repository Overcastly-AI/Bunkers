package com.motion.catalogjoin;

import java.util.Map;
import org.apache.kafka.streams.state.RocksDBConfigSetter;
import org.rocksdb.BlockBasedTableConfig;
import org.rocksdb.Cache;
import org.rocksdb.CompressionType;
import org.rocksdb.LRUCache;
import org.rocksdb.Options;
import org.rocksdb.RocksDB;
import org.rocksdb.WriteBufferManager;

/**
 * Puts every RocksDB store in the process under one memory budget: a shared block cache that also
 * holds index/filter blocks, and memtables charged against that same cache. Without this each of
 * the app's many stores (per partition) gets its own cache and memtables, which is unbounded.
 * Sizes come from {@code catalog.rocksdb.memory-bytes} and {@code catalog.rocksdb.memtable-share}.
 */
public final class BoundedRocksDb implements RocksDBConfigSetter {

  private static Cache cache;
  private static WriteBufferManager writeBuffers;

  /** Called once at startup; falls back to the defaults file when it was not (tests). */
  public static synchronized void configure(long memoryBytes, double memtableShare) {
    if (cache != null) {
      return;
    }
    RocksDB.loadLibrary();
    cache = new LRUCache(memoryBytes, -1, false, 0.1);
    writeBuffers = new WriteBufferManager((long) (memoryBytes * memtableShare), cache);
  }

  @Override
  public void setConfig(String storeName, Options options, Map<String, Object> configs) {
    if (cache == null) {
      CatalogConfig defaults = CatalogConfig.of(new java.util.Properties());
      configure(defaults.rocksDbMemoryBytes(), defaults.rocksDbMemtableShare());
    }
    BlockBasedTableConfig table = (BlockBasedTableConfig) options.tableFormatConfig();
    table.setBlockCache(cache);
    table.setCacheIndexAndFilterBlocks(true);
    table.setCacheIndexAndFilterBlocksWithHighPriority(true);
    table.setPinTopLevelIndexAndFilter(true);
    options.setTableFormatConfig(table);
    options.setWriteBufferManager(writeBuffers);
    options.setCompressionType(CompressionType.LZ4_COMPRESSION);
  }

  @Override
  public void close(String storeName, Options options) {
    // The cache and write buffer manager are shared by every store; they live as long as the process.
  }
}
