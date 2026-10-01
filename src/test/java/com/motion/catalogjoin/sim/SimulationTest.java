package com.motion.catalogjoin.sim;

import static org.assertj.core.api.Assertions.assertThat;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.testing.TopologyDriver;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

/**
 * Runs the simulated catalog (initial load + churn rounds, every message format, padded keys,
 * deletes, key-changing edits in both orders) through the real topology in-process, configured
 * exactly like the GKE simulation (deploy/sim/catalog-join.properties), and checks every published
 * document against the model.
 *
 * <p>The scaled variant runs a bigger catalog without any infrastructure: {@code mvn test
 * -Dtest='SimulationTest#scaled' -Dsim.items=20000 -Dsim.rounds=3}. TopologyTestDriver commits
 * after every record, so this checks correctness, not throughput, and it ignores partitioning; use
 * sim/run-local.sh or deploy/sim for millions of records.
 */
class SimulationTest {

  @Test
  void smallCatalogMatchesModelAfterChurn() {
    Verifier.Report report = simulate(Map.of("sim.items", "800", "sim.rounds", "4"));
    assertThat(report.mismatches()).isEmpty();
    assertThat(report.itemsPresent()).isGreaterThan(700);
  }

  @Test
  void smallCatalogMatchesModelWithCaching() {
    Verifier.Report report = simulate(Map.of("sim.items", "500", "sim.rounds", "3", "statestore.cache.max.bytes", "10485760"));
    assertThat(report.mismatches()).isEmpty();
  }

  @Test
  @EnabledIfSystemProperty(named = "sim.items", matches = "\\d+")
  void scaled() {
    Map<String, String> overrides = new HashMap<>();
    overrides.put("sim.items", System.getProperty("sim.items"));
    overrides.put("sim.rounds", System.getProperty("sim.rounds", "3"));
    overrides.put("sim.sample-every", System.getProperty("sim.sample-every", "1"));
    overrides.put("statestore.cache.max.bytes", "67108864");
    assertThat(simulate(overrides).mismatches()).isEmpty();
  }

  static Verifier.Report simulate(Map<String, String> overrides) {
    Map<String, String> settings = new HashMap<>(Map.of("sim.sample-every", "1", "statestore.cache.max.bytes", "0"));
    settings.putAll(overrides);
    CatalogConfig config = TopologyDriver.config(settings, TopologyDriver.SIM_CONFIG);
    Verifier verifier = new Verifier(config);
    try (TopologyDriver driver = new TopologyDriver(config, verifier::isSampled)) {
      long[] sent = {0};
      long start = System.nanoTime();
      new Generator(config, message -> {
        driver.pipe(message.topic(), message.key(), message.value());
        sent[0]++;
      }).run(0, config.sim().rounds(), round -> {
        driver.advance();
        System.out.printf("round %d: %,d messages, %.1fs%n", round, sent[0], (System.nanoTime() - start) / 1e9);
      });
      Verifier.Report report = verifier.verify(driver.outputs());
      System.out.print(report.describe());
      return report;
    }
  }
}
