package com.motion.catalogjoin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Map;
import java.util.Properties;
import org.junit.jupiter.api.Test;

class CatalogConfigTest {

  private static Properties base() {
    Properties p = new Properties();
    p.setProperty("catalog.step.attribute.ITEM_NUMBER", "A-ITEM");
    return p;
  }

  @Test
  void defaultsFollowTheTopicNamingConvention() {
    CatalogConfig config = CatalogConfig.from(base());
    assertThat(config.topic(SourceTable.ITEM_PROFILE)).isEqualTo("topic.brop.item_profile-json");
    assertThat(config.topic(SourceTable.MFR_NAME)).isEqualTo("topic.misearch.mfr_name-json");
    assertThat(config.itemTopic()).isEqualTo("catalog.item");
    assertThat(config.partitions()).isNull();
  }

  @Test
  void catalogKeysStayOutOfStreamsProperties() {
    Properties p = base();
    p.setProperty("bootstrap.servers", "kafka:9092");
    p.setProperty("catalog.topic.item_profile", "custom.items");
    CatalogConfig config = CatalogConfig.from(p);
    assertThat(config.topic(SourceTable.ITEM_PROFILE)).isEqualTo("custom.items");
    assertThat(config.streamsProperties()).containsOnlyKeys("bootstrap.servers");
  }

  @Test
  void itemNumberAttributeIsRequired() {
    assertThatThrownBy(() -> CatalogConfig.from(new Properties()))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("ITEM_NUMBER");
  }

  @Test
  void environmentReferencesAreResolved() {
    Map<String, String> env = Map.of("KAFKA_PASSWORD", "s3cret");
    assertThat(CatalogConfig.resolveEnv("user=x password=${KAFKA_PASSWORD};", env::get)).isEqualTo("user=x password=s3cret;");
    assertThat(CatalogConfig.resolveEnv("${MISSING:fallback}", env::get)).isEqualTo("fallback");
    assertThatThrownBy(() -> CatalogConfig.resolveEnv("${MISSING}", env::get)).isInstanceOf(IllegalArgumentException.class);
  }
}
