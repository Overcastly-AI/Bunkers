package com.motion.catalogjoin.clients;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Topics;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.errors.WakeupException;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.apache.kafka.streams.StreamsConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * {@code catalog-join deliver --client <name>}: posts a client's topic to its HTTP endpoint.
 *
 * <p>Each POST carries a JSON array of {@code {"key": {...}, "value": {...}}}, with {@code "value":
 * null} for a deletion. Within a batch only the latest change per key is sent. Offsets are committed
 * only after the endpoint accepted the batch, so nothing is lost while it is down: 5xx, 408, 429 and
 * connection errors are retried with exponential backoff, indefinitely. A batch rejected with any
 * other 4xx goes to the client's dead-letter topic, and delivery moves on. Replaying the topic from
 * the beginning (a new consumer group) re-posts every current value.
 */
public final class HttpDelivery {

  private static final Logger LOG = LoggerFactory.getLogger(HttpDelivery.class);

  /** Where an accepted, rejected or retried batch goes; separated from Kafka for testing. */
  interface DeadLetters {
    void send(String key, String body, String error);
  }

  private final Client client;
  private final HttpClient http;
  private final DeadLetters deadLetters;
  private final AtomicBoolean running;

  HttpDelivery(Client client, DeadLetters deadLetters, AtomicBoolean running) {
    this.client = client;
    this.deadLetters = deadLetters;
    this.running = running;
    this.http = HttpClient.newBuilder().connectTimeout(client.http().timeout()).build();
  }

  public static int run(CatalogConfig config, String name) {
    Client client = config.clients().get(name);
    if (client == null || client.http().url() == null) {
      System.err.println("No client '" + name + "' with catalog.client." + name + ".http.url; configured clients: " + config.clients().keySet());
      return 2;
    }
    Map<String, Object> common = Topics.adminClient(config);
    Map<String, Object> consumerProps = new HashMap<>(common);
    consumerProps.put(ConsumerConfig.GROUP_ID_CONFIG,
        config.streamsProperties().getProperty(StreamsConfig.APPLICATION_ID_CONFIG) + "-deliver-" + name);
    consumerProps.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
    consumerProps.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
    consumerProps.put(ConsumerConfig.ISOLATION_LEVEL_CONFIG, "read_committed");
    consumerProps.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, Integer.toString(client.http().batchSize()));
    // A batch may wait out a long outage of the endpoint before it is committed.
    consumerProps.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, Integer.toString(Integer.MAX_VALUE));

    AtomicBoolean running = new AtomicBoolean(true);
    try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(consumerProps, new StringDeserializer(), new StringDeserializer());
        KafkaProducer<String, byte[]> producer = new KafkaProducer<>(new HashMap<>(common), new StringSerializer(), new ByteArraySerializer())) {
      Thread main = Thread.currentThread();
      Runtime.getRuntime().addShutdownHook(new Thread(() -> {
        running.set(false);
        consumer.wakeup();
        try {
          main.join(30_000);
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
        }
      }));
      HttpDelivery delivery = new HttpDelivery(client, (key, body, error) -> {
        ProducerRecord<String, byte[]> record = new ProducerRecord<>(client.deadLetterTopic(), key, body.getBytes(StandardCharsets.UTF_8));
        record.headers().add("catalog.error", error.getBytes(StandardCharsets.UTF_8));
        producer.send(record);
      }, running);
      consumer.subscribe(List.of(client.topic()));
      LOG.info("Delivering {} to {}", client.topic(), client.http().url());
      while (running.get()) {
        ConsumerRecords<String, String> records = consumer.poll(Duration.ofSeconds(1));
        if (records.isEmpty()) {
          continue;
        }
        List<ConsumerRecord<String, String>> batch = new ArrayList<>();
        records.forEach(batch::add);
        if (!delivery.deliver(batch)) {
          break; // shutting down mid-retry: the batch is not committed and is redelivered on restart
        }
        producer.flush();
        consumer.commitSync();
      }
    } catch (WakeupException e) {
      // shutdown
    }
    return 0;
  }

  /** Posts one batch; returns false only when asked to stop before the endpoint accepted it. */
  boolean deliver(List<ConsumerRecord<String, String>> records) {
    String body = body(records);
    Duration backoff = Duration.ofSeconds(1);
    while (running.get()) {
      String error;
      try {
        HttpRequest.Builder request = HttpRequest.newBuilder(URI.create(client.http().url()))
            .timeout(client.http().timeout())
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(body));
        client.http().headers().forEach(request::header);
        HttpResponse<String> response = http.send(request.build(), HttpResponse.BodyHandlers.ofString());
        int status = response.statusCode();
        if (status / 100 == 2) {
          return true;
        }
        error = "HTTP " + status + ": " + response.body();
        if (status / 100 == 4 && status != 408 && status != 429) {
          LOG.error("{} rejected a batch of {}; dead-lettering it: {}", client.name(), records.size(), error);
          deadLetters.send(records.get(0).key(), body, error);
          return true;
        }
      } catch (java.io.IOException e) {
        error = e.toString();
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        return false;
      }
      LOG.warn("{} delivery failed ({}); retrying in {}", client.name(), error, backoff);
      try {
        Thread.sleep(backoff.toMillis());
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        return false;
      }
      backoff = backoff.multipliedBy(2).compareTo(client.http().maxBackoff()) > 0 ? client.http().maxBackoff() : backoff.multipliedBy(2);
    }
    return false;
  }

  /** {@code [{"key": {...}, "value": {...} | null}, ...]}, latest change per key, in order. */
  static String body(List<ConsumerRecord<String, String>> records) {
    Map<String, String> latest = new LinkedHashMap<>();
    for (ConsumerRecord<String, String> record : records) {
      latest.remove(record.key());
      latest.put(record.key(), record.value());
    }
    List<Map<String, Object>> items = new ArrayList<>();
    latest.forEach((key, value) -> {
      Map<String, Object> item = new LinkedHashMap<>();
      item.put("key", Keys.parse(key));
      item.put("value", value == null ? null : Json.read(value));
      items.add(item);
    });
    return Json.writeString(items);
  }
}
