package com.motion.catalogjoin;

import static org.assertj.core.api.Assertions.assertThatCode;

import org.junit.jupiter.api.Test;

class BoundedRocksDbTest {

  /** App configures the shared cache before Kafka Streams has loaded RocksDB's native library. */
  @Test
  void configuresBeforeAnyStoreIsOpened() {
    assertThatCode(() -> BoundedRocksDb.configure(64L * 1024 * 1024, 0.5)).doesNotThrowAnyException();
  }
}
