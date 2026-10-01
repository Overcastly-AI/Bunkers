package com.motion.catalogjoin.ingest;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import org.apache.avro.Schema;

/** The IBM CDC envelope contract, shared by the decoder and the load simulator's encoder. */
public final class CdcEnvelope {

  public static final Schema SCHEMA = load("/avro/cdc-envelope.avsc");

  public static final String OP = "op";
  public static final String BEFORE = "before";
  public static final String AFTER = "after";
  public static final String TS_MS = "ts_ms";

  public static final String INSERT = "I";
  public static final String UPDATE = "U";
  public static final String DELETE = "D";

  /** Confluent wire format: magic byte 0x00 followed by a 4-byte schema id. */
  public static final byte CONFLUENT_MAGIC = 0;
  public static final int CONFLUENT_HEADER_BYTES = 5;

  private CdcEnvelope() {}

  private static Schema load(String resource) {
    try (InputStream in = CdcEnvelope.class.getResourceAsStream(resource)) {
      if (in == null) {
        throw new IllegalStateException(resource + " is not on the classpath");
      }
      return new Schema.Parser().parse(in);
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }
}
