package com.motion.catalogjoin.ops;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Topics;
import com.motion.catalogjoin.clients.Client;
import com.motion.catalogjoin.clients.HttpDelivery;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ExecutionException;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.ListOffsetsResult.ListOffsetsResultInfo;
import org.apache.kafka.clients.admin.OffsetSpec;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.common.TopicPartition;

/**
 * {@code catalog-join replay-client --client NAME --from earliest|<ISO-8601 time>}: moves a client's
 * delivery back so {@code deliver} re-posts its topic from there. The topic is compacted, so this
 * re-sends the latest value of every key changed since then (from {@code earliest}: every key),
 * not each intermediate change. The client's {@code deliver} must be stopped; to re-send a few
 * keys while it runs, use {@code republish --only NAME}.
 */
public final class ReplayClient {

  private ReplayClient() {}

  public static int run(CatalogConfig config, String name, String from, boolean dryRun) throws Exception {
    Client client = config.clients().get(name);
    if (client == null) {
      System.err.println("No client '" + name + "'; configured clients: " + config.clients().keySet());
      return 2;
    }
    if (from == null) {
      System.err.println("--from earliest|<ISO-8601 time, e.g. 2026-10-01T00:00:00Z> is required");
      return 2;
    }
    OffsetSpec spec = from.equals("earliest") ? OffsetSpec.earliest() : OffsetSpec.forTimestamp(Instant.parse(from).toEpochMilli());
    String group = HttpDelivery.groupId(config, name);
    try (Admin admin = Admin.create(Topics.adminClient(config))) {
      var description = admin.describeConsumerGroups(List.of(group)).all().get().get(group);
      if (!description.members().isEmpty()) {
        System.err.printf("%s has %d active member(s): stop `deliver --client %s` first, then run this again.%n",
            group, description.members().size(), name);
        return 1;
      }
      List<TopicPartition> partitions = admin.describeTopics(List.of(client.topic())).allTopicNames().get()
          .get(client.topic()).partitions().stream().map(p -> new TopicPartition(client.topic(), p.partition())).toList();
      Map<TopicPartition, Long> target = offsets(admin, partitions, spec);
      Map<TopicPartition, Long> end = offsets(admin, partitions, OffsetSpec.latest());
      Map<TopicPartition, OffsetAndMetadata> committed = admin.listConsumerGroupOffsets(group).partitionsToOffsetAndMetadata().get();

      Map<TopicPartition, OffsetAndMetadata> reset = new TreeMap<>(java.util.Comparator.comparingInt(TopicPartition::partition));
      long resend = 0;
      for (TopicPartition partition : partitions) {
        long offset = target.get(partition) < 0 ? end.get(partition) : target.get(partition); // nothing after `from`
        reset.put(partition, new OffsetAndMetadata(offset));
        resend += end.get(partition) - offset;
        OffsetAndMetadata current = committed.get(partition);
        System.out.printf("  %s: %s -> %d (end %d)%n", partition, current == null ? "none" : current.offset(), offset, end.get(partition));
      }
      System.out.printf("%s %s back to %s: up to %,d record(s) to re-post (fewer after compaction and per-batch dedup).%n",
          dryRun ? "Would move" : "Moved", group, from, resend);
      if (!dryRun) {
        admin.alterConsumerGroupOffsets(group, reset).all().get();
      }
      return 0;
    } catch (ExecutionException e) {
      System.err.println("Could not reset " + group + ": " + e.getCause());
      return 1;
    }
  }

  private static Map<TopicPartition, Long> offsets(Admin admin, List<TopicPartition> partitions, OffsetSpec spec)
      throws Exception {
    Map<TopicPartition, OffsetSpec> request = new HashMap<>();
    partitions.forEach(p -> request.put(p, spec));
    Map<TopicPartition, Long> offsets = new HashMap<>();
    for (Map.Entry<TopicPartition, ListOffsetsResultInfo> e : admin.listOffsets(request).all().get().entrySet()) {
      offsets.put(e.getKey(), e.getValue().offset());
    }
    return offsets;
  }
}
