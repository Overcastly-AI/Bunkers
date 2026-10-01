package com.motion.catalogjoin.topology;

import static org.assertj.core.api.Assertions.assertThat;

import com.motion.catalogjoin.testing.TopologyDriver;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * Guards the names of stores and internal topics. Renaming either orphans existing state and
 * needs a planned reset, so any change to the topology must show up here as a deliberate diff.
 * Regenerate with {@code mvn test -Dtopology.update=true}.
 */
class TopologySnapshotTest {

  private static final Path SNAPSHOT = Path.of("src/test/resources/topology.txt");

  @Test
  void topologyMatchesSnapshot() throws IOException {
    String described = CatalogTopology.build(TopologyDriver.config(Map.of(), TopologyDriver.TEST_CONFIG)).describe().toString();
    if (Boolean.getBoolean("topology.update") || !Files.exists(SNAPSHOT)) {
      Files.writeString(SNAPSHOT, described, StandardCharsets.UTF_8);
    }
    assertThat(described).isEqualTo(Files.readString(SNAPSHOT, StandardCharsets.UTF_8));
  }
}
