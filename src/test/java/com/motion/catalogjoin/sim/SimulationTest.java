package com.motion.catalogjoin.sim;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.topology.CatalogTopology;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.TestInputTopic;
import org.apache.kafka.streams.TestOutputTopic;
import org.apache.kafka.streams.TopologyTestDriver;
import org.apache.kafka.streams.test.TestRecord;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

/**
 * Runs the simulated catalog (initial load + churn rounds, every message format, padded keys,
 * deletes, key-changing edits in both orders) through the real topology in-process and checks
 * every published document against the model.
 *
 * <p>The scaled variant runs a bigger catalog without any infrastructure: {@code mvn test
 * -Dtest='SimulationTest#scaled' -Dsim.items=20000 -Dsim.rounds=3} (about 30 source records per
 * item at round 0). TopologyTestDriver commits after every record, so it checks correctness, not
 * throughput, and it ignores partitioning; use sim/run-local.sh or deploy/sim for millions of
 * records.
 */
class SimulationTest {

  @Test
  void smallCatalogMatchesModelAfterChurn() {
    Result result = simulate(800, 4, 1, 0);
    System.out.print(result.report().describe());
    assertThat(result.report().mismatches()).isEmpty();
    assertThat(result.report().passed()).isTrue();
    assertThat(result.report().itemsPresent()).isGreaterThan(700);
  }

  @Test
  void smallCatalogMatchesModelWithCaching() {
    Result result = simulate(500, 3, 1, 10 * 1024 * 1024);
    System.out.print(result.report().describe());
    assertThat(result.report().passed()).isTrue();
  }

  @Test
  @EnabledIfSystemProperty(named = "sim.items", matches = "\\d+")
  void scaled() {
    int items = Integer.getInteger("sim.items");
    int rounds = Integer.getInteger("sim.rounds", 3);
    int sampleEvery = Integer.getInteger("sim.sample-every", items > 50_000 ? 10 : 1);
    Result result = simulate(items, rounds, sampleEvery, 64 * 1024 * 1024);
    System.out.print(result.report().describe());
    assertThat(result.report().passed()).isTrue();
  }

  record Result(Verifier.Report report, long messages, double seconds) {}

  static Result simulate(int items, int rounds, int sampleEvery, long cacheBytes) {
    long seed = 7;
    SimModel model = new SimModel(seed, items, 600, 2);
    Properties props = new Properties();
    props.setProperty(StreamsConfig.APPLICATION_ID_CONFIG, "catalog-join-sim");
    props.setProperty(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "unused:9092");
    props.setProperty(StreamsConfig.STATESTORE_CACHE_MAX_BYTES_CONFIG, Long.toString(cacheBytes));
    SimModel.CONFIGURED_ATTRIBUTES.forEach((name, id) -> props.setProperty("catalog.step.attribute." + name, id));
    CatalogConfig config = CatalogConfig.from(props);
    Properties streamsProps = config.streamsProperties();
    Path stateDir = tempDir();
    streamsProps.setProperty(StreamsConfig.STATE_DIR_CONFIG, stateDir.toString());

    Verifier verifier = new Verifier(model, rounds, sampleEvery);
    try (TopologyTestDriver driver = new TopologyTestDriver(CatalogTopology.build(config), streamsProps)) {
      Map<String, TestInputTopic<byte[], byte[]>> inputs = new HashMap<>();
      for (SourceTable table : SourceTable.values()) {
        inputs.put(config.topic(table), driver.createInputTopic(config.topic(table), new ByteArraySerializer(), new ByteArraySerializer()));
      }
      Map<String, Map<String, JsonNode>> published = new HashMap<>();
      Map<String, TestOutputTopic<String, byte[]>> outputs = new HashMap<>();
      for (String topic : new String[] {config.itemTopic(), config.itemLocationTopic(), config.itemPriceTopic()}) {
        outputs.put(topic, driver.createOutputTopic(topic, new StringDeserializer(), new ByteArrayDeserializer()));
        published.put(topic, new HashMap<>());
      }

      Encoder encoder = new Encoder(seed, "", Encoder.parseWeights("flat=60,envelope=25,avro=15"), 0.15);
      long[] sent = {0};
      Generator generator = new Generator(model, encoder, message -> {
        inputs.get(message.topic()).pipeInput(message.key(), message.value());
        sent[0]++;
      }, seed);

      long start = System.nanoTime();
      generator.run(0, rounds, round -> {
        driver.advanceWallClockTime(Duration.ofMinutes(1));
        drain(outputs, published, verifier);
        System.out.printf("round %d: %,d messages, %.1fs%n", round, sent[0], (System.nanoTime() - start) / 1e9);
      });
      double seconds = (System.nanoTime() - start) / 1e9;
      System.out.printf("%,d items, %,d source messages in %.1fs (%,.0f msg/s through the topology)%n",
          items, sent[0], seconds, sent[0] / seconds);

      Verifier.Report report = verifier.verify(new Verifier.Published(
          published.get(config.itemTopic()), published.get(config.itemLocationTopic()), published.get(config.itemPriceTopic())));
      return new Result(report, sent[0], seconds);
    }
  }

  private static void drain(Map<String, TestOutputTopic<String, byte[]>> outputs, Map<String, Map<String, JsonNode>> published, Verifier verifier) {
    outputs.forEach((topic, output) -> {
      Map<String, JsonNode> latest = published.get(topic);
      for (TestRecord<String, byte[]> record : output.readRecordsToList()) {
        if (!verifier.isSampled(record.key())) {
          continue;
        }
        if (record.value() == null) {
          latest.remove(record.key());
        } else {
          try {
            latest.put(record.key(), Json.MAPPER.readTree(record.value()));
          } catch (IOException e) {
            throw new UncheckedIOException(e);
          }
        }
      }
    });
  }

  private static Path tempDir() {
    try {
      return Files.createTempDirectory("catalog-join-sim");
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }
}
