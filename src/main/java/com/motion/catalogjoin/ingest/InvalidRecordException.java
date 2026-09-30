package com.motion.catalogjoin.ingest;

/** A source record that cannot be decoded into a row. It is routed to the dead-letter topic. */
public class InvalidRecordException extends Exception {

  public InvalidRecordException(String message) {
    super(message);
  }

  public InvalidRecordException(String message, Throwable cause) {
    super(message, cause);
  }
}
