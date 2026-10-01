package com.motion.catalogjoin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class CatalogConfigTest {

  @Test
  void defaultsComeFromTheFileInTheJar() {
    CatalogConfig config = CatalogConfig.of(new Properties());
    assertThat(config.topic(SourceTable.ITEM_PROFILE)).isEqualTo("topic.brop.item_profile-json");
    assertThat(config.keyColumns(SourceTable.ITEM_BALANCE)).containsExactly("ITEM_NO", "MI_LOC", "STOREROOM_NO");
    assertThat(config.itemTopic()).isEqualTo("catalog.item");
    assertThat(config.classificationRoot()).isEqualTo("Motion");
    assertThat(config.dcLocationTypes()).containsExactly("W");
    assertThat(config.partitions()).isEqualTo(12);
    assertThat(config.streamsProperties()).containsEntry("processing.guarantee", "exactly_once_v2");
  }

  @Test
  void everySourceTableIsConfigured() {
    CatalogConfig config = CatalogConfig.of(new Properties());
    for (SourceTable table : SourceTable.values()) {
      assertThat(config.topic(table)).isNotBlank();
      assertThat(config.keyColumns(table)).isNotEmpty();
    }
  }

  @Test
  void topicPrefixAppliesToSourcesAndOutputs() {
    Properties p = new Properties();
    p.setProperty("catalog.topic-prefix", "sim.");
    CatalogConfig config = CatalogConfig.of(p);
    assertThat(config.topic(SourceTable.MFR_NAME)).isEqualTo("sim.topic.misearch.mfr_name-json");
    assertThat(config.outputTopics()).containsExactly("sim.catalog.item", "sim.catalog.item-location", "sim.catalog.item-price");
    assertThat(config.deadLetterTopic()).isEqualTo("sim.catalog.join.dlt");
  }

  @Test
  void laterFilesWinAndOverridesWinOverFiles(@TempDir Path dir) throws IOException {
    Path first = Files.writeString(dir.resolve("a.properties"), "catalog.health-port=1\nnum.stream.threads=4\n");
    Path second = Files.writeString(dir.resolve("b.properties"), "catalog.health-port=2\n");
    CatalogConfig config = CatalogConfig.load(List.of(first, second), Map.of("num.stream.threads", "8"));
    assertThat(config.healthPort()).isEqualTo(2);
    assertThat(config.streamsProperties()).containsEntry("num.stream.threads", "8");
  }

  @Test
  void ownSettingsStayOutOfStreamsProperties() {
    Properties streams = CatalogConfig.of(new Properties()).streamsProperties();
    assertThat(streams.stringPropertyNames()).noneMatch(k -> k.startsWith("catalog.") || k.startsWith("sim."));
  }

  @Test
  void itemNumberAttributeIsRequiredWhenUsed() {
    CatalogConfig config = CatalogConfig.of(new Properties());
    assertThatThrownBy(config::itemNumberAttribute).isInstanceOf(IllegalArgumentException.class).hasMessageContaining("ITEM_NUMBER");
  }

  @Test
  void secretsAreMaskedWhenDescribed() {
    Properties p = new Properties();
    p.setProperty("sasl.jaas.config", "x required password=\"p\";");
    assertThat(CatalogConfig.of(p).describe()).containsEntry("sasl.jaas.config", "****");
  }

  @Test
  void environmentReferencesAreResolved() {
    Map<String, String> env = Map.of("KAFKA_PASSWORD", "s3cret");
    assertThat(CatalogConfig.resolveEnv("user=x password=${KAFKA_PASSWORD};", env::get)).isEqualTo("user=x password=s3cret;");
    assertThat(CatalogConfig.resolveEnv("${MISSING:fallback}", env::get)).isEqualTo("fallback");
    assertThatThrownBy(() -> CatalogConfig.resolveEnv("${MISSING}", env::get)).isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void overlayFilesInTheRepoLoad() {
    for (String overlay : List.of("deploy/production/catalog-join.properties", "deploy/sim/catalog-join.properties",
        "deploy/local/catalog-join.properties", "src/test/resources/test.properties")) {
      assertThat(CatalogConfig.load(List.of(Path.of(overlay)), Map.of()).outputTopics()).as(overlay).hasSize(3);
    }
  }
}
