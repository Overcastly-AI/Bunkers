package com.motion.catalogjoin.sim;

/** Deterministic hashing: every simulated value is a pure function of (seed, purpose, ids). */
final class Mix {

  private Mix() {}

  static long hash(long seed, long... parts) {
    long h = splitmix(seed ^ 0x9E3779B97F4A7C15L);
    for (long part : parts) {
      h = splitmix(h ^ part);
    }
    return h;
  }

  /** Uniform in [0, 1). */
  static double frac(long h) {
    return (h >>> 11) * 0x1.0p-53;
  }

  static int mod(long h, int n) {
    return (int) Math.floorMod(h, (long) n);
  }

  private static long splitmix(long z) {
    z += 0x9E3779B97F4A7C15L;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9L;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EBL;
    return z ^ (z >>> 31);
  }
}
