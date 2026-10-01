package com.motion.catalogjoin;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.errors.TopicExistsException;
import org.apache.kafka.streams.StreamsConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Topic creation and client settings for the tools, all derived from the one configuration. */
public final class Topics {

  private static final Logger LOG = LoggerFactory.getLogger(Topics.class);

  private Topics() {}

  /** Admin/producer/consumer settings (bootstrap, security, ...) as Kafka Streams would use them. */
  public static Map<String, Object> adminClient(CatalogConfig config) {
    return new StreamsConfig(config.streamsProperties()).getAdminConfigs("catalog-join-tools");
  }

  /** The compacted output topics and the dead-letter topic, sized from catalog.output.*. */
  public static void createOutputs(CatalogConfig config) {
    List<NewTopic> topics = new ArrayList<>();
    Map<String, String> compacted = Map.of(
        "cleanup.policy", "compact",
        "min.compaction.lag.ms", "0",
        "max.message.bytes", Integer.toString(config.outputMaxMessageBytes()));
    for (String topic : config.outputTopics()) {
      topics.add(new NewTopic(topic, config.outputPartitions(), config.outputReplication()).configs(compacted));
    }
    for (var client : config.clients().values()) {
      topics.add(new NewTopic(client.topic(), config.outputPartitions(), config.outputReplication()).configs(compacted));
      topics.add(new NewTopic(client.deadLetterTopic(), 1, config.outputReplication())
          .configs(Map.of("cleanup.policy", "delete", "retention.ms", Long.toString(config.deadLetterRetentionMs()))));
    }
    topics.add(new NewTopic(config.deadLetterTopic(), config.outputPartitions(), config.outputReplication())
        .configs(Map.of("cleanup.policy", "delete", "retention.ms", Long.toString(config.deadLetterRetentionMs()))));
    create(config, topics);
  }

  /** Compacted source topics (load simulation only; real sources belong to the CDC pipeline). */
  public static void createSources(CatalogConfig config, int partitions, short replication) {
    List<NewTopic> topics = new ArrayList<>();
    for (SourceTable table : SourceTable.values()) {
      topics.add(new NewTopic(config.topic(table), partitions, replication).configs(Map.of("cleanup.policy", "compact")));
    }
    create(config, topics);
  }

  private static void create(CatalogConfig config, List<NewTopic> topics) {
    try (Admin admin = Admin.create(adminClient(config))) {
      for (NewTopic topic : topics) {
        try {
          admin.createTopics(List.of(topic)).all().get();
          LOG.info("Created {}", topic.name());
        } catch (ExecutionException e) {
          if (!(e.getCause() instanceof TopicExistsException)) {
            throw new IllegalStateException("Cannot create " + topic.name(), e.getCause());
          }
          LOG.info("{} already exists; its settings were left unchanged", topic.name());
        }
      }
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException(e);
    }
  }
}
