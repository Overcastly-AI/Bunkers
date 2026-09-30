package com.motion.catalogjoin.ingest;

/** Which encodings the decoder accepts for source message values. */
public enum PayloadFormat {
  AVRO_ONLY,
  JSON_ONLY,
  /** Try Avro (raw or Confluent-framed) first, then JSON. */
  AVRO_OR_JSON
}
