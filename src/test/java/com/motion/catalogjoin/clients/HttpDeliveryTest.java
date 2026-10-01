package com.motion.catalogjoin.clients;

import static org.assertj.core.api.Assertions.assertThat;

import com.motion.catalogjoin.Json;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class HttpDeliveryTest {

  private HttpServer server;
  private final ConcurrentLinkedQueue<String> bodies = new ConcurrentLinkedQueue<>();
  private final List<String> deadLettered = new ArrayList<>();

  @AfterEach
  void stop() {
    server.stop(0);
  }

  /** Responds with the given statuses in order, then 200 forever. */
  private HttpDelivery endpoint(int... statuses) throws IOException {
    AtomicInteger call = new AtomicInteger();
    server = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
    server.createContext("/stock", exchange -> {
      bodies.add(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
      int n = call.getAndIncrement();
      int status = n < statuses.length ? statuses[n] : 200;
      byte[] response = ("status " + status).getBytes(StandardCharsets.UTF_8);
      exchange.sendResponseHeaders(status, response.length);
      exchange.getResponseBody().write(response);
      exchange.close();
    });
    server.start();
    Client client = new Client("qdrant", "item", Projection.parse("itemNo"), "t", "t.dlt",
        new Client.Http("http://localhost:" + server.getAddress().getPort() + "/stock", Map.of("X-Token", "abc"), 500,
            Duration.ofSeconds(5), Duration.ofMillis(10)));
    return new HttpDelivery(client, (key, body, error) -> deadLettered.add(error), new AtomicBoolean(true));
  }

  private static ConsumerRecord<String, String> record(String item, String value) {
    return new ConsumerRecord<>("t", 0, 0, "{\"ITEM_NO\":\"" + item + "\"}", value);
  }

  @Test
  void postsLatestChangePerKeyWithDeletesAsNull() throws IOException {
    HttpDelivery delivery = endpoint();
    assertThat(delivery.deliver(List.of(
        record("1", "{\"inStock\":true}"), record("2", "{\"inStock\":true}"), record("1", "{\"inStock\":false}"), record("3", null))))
        .isTrue();
    assertThat(bodies).hasSize(1);
    assertThat(Json.MAPPER.readTree(bodies.peek()).toString()).isEqualTo(
        "[{\"key\":{\"ITEM_NO\":\"2\"},\"value\":{\"inStock\":true}},"
            + "{\"key\":{\"ITEM_NO\":\"1\"},\"value\":{\"inStock\":false}},"
            + "{\"key\":{\"ITEM_NO\":\"3\"},\"value\":null}]");
  }

  @Test
  void retriesServerErrorsAndThrottlingUntilAccepted() throws IOException {
    HttpDelivery delivery = endpoint(503, 429, 500);
    assertThat(delivery.deliver(List.of(record("1", "{\"inStock\":true}")))).isTrue();
    assertThat(bodies).hasSize(4);
    assertThat(deadLettered).isEmpty();
  }

  @Test
  void rejectedBatchesAreDeadLetteredNotRetried() throws IOException {
    HttpDelivery delivery = endpoint(400);
    assertThat(delivery.deliver(List.of(record("1", "{\"inStock\":true}")))).isTrue();
    assertThat(bodies).hasSize(1);
    assertThat(deadLettered).singleElement().asString().contains("HTTP 400");
  }
}
