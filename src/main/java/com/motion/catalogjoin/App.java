package com.motion.catalogjoin;

import com.motion.catalogjoin.topology.CatalogTopology;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Properties;
import java.util.concurrent.CountDownLatch;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.errors.StreamsUncaughtExceptionHandler.StreamThreadExceptionResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Entry point. Usage: {@code java -jar catalog-join.jar [application.properties]} (or set {@code
 * CATALOG_CONFIG}). Exposes {@code GET /health} (200 while running or rebalancing) on {@code
 * catalog.health-port} (default 8080; 0 disables it). Exits non-zero if Kafka Streams fails, so the
 * orchestrator restarts it.
 */
public final class App {

  private static final Logger LOG = LoggerFactory.getLogger(App.class);

  private App() {}

  public static void main(String[] args) throws Exception {
    String configPath = args.length > 0 ? args[0] : System.getenv().getOrDefault("CATALOG_CONFIG", "application.properties");
    Properties raw = new Properties();
    try (InputStream in = Files.newInputStream(Path.of(configPath))) {
      raw.load(in);
    }
    System.getProperties().forEach((k, v) -> {
      String name = k.toString();
      if (name.startsWith(CatalogConfig.PREFIX) || raw.containsKey(name)) {
        raw.setProperty(name, v.toString());
      }
    });

    CatalogConfig config = CatalogConfig.from(raw);
    Topology topology = CatalogTopology.build(config);
    LOG.info("Topology:\n{}", topology.describe());

    Properties streamsProps = config.streamsProperties();
    streamsProps.putIfAbsent(StreamsConfig.APPLICATION_ID_CONFIG, "catalog-join");
    streamsProps.putIfAbsent(StreamsConfig.PROCESSING_GUARANTEE_CONFIG, StreamsConfig.EXACTLY_ONCE_V2);
    streamsProps.putIfAbsent(StreamsConfig.REPLICATION_FACTOR_CONFIG, "3");

    KafkaStreams streams = new KafkaStreams(topology, streamsProps);
    CountDownLatch stopped = new CountDownLatch(1);
    int[] exitCode = {0};
    streams.setUncaughtExceptionHandler(e -> {
      LOG.error("Stream thread failed; shutting down", e);
      exitCode[0] = 1;
      return StreamThreadExceptionResponse.SHUTDOWN_CLIENT;
    });
    streams.setStateListener((next, previous) -> {
      LOG.info("State {} -> {}", previous, next);
      if (next == KafkaStreams.State.ERROR) {
        exitCode[0] = 1;
      }
      if (next == KafkaStreams.State.NOT_RUNNING || next == KafkaStreams.State.ERROR) {
        stopped.countDown();
      }
    });

    int healthPort = Integer.parseInt(raw.getProperty(CatalogConfig.PREFIX + "health-port", "8080").trim());
    HttpServer health = healthPort > 0 ? startHealth(healthPort, streams) : null;

    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
      streams.close(Duration.ofSeconds(60));
      stopped.countDown();
    }, "shutdown"));

    streams.start();
    stopped.await();
    if (health != null) {
      health.stop(0);
    }
    streams.close(Duration.ofSeconds(60));
    System.exit(exitCode[0]);
  }

  private static HttpServer startHealth(int port, KafkaStreams streams) throws IOException {
    HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
    server.createContext("/health", exchange -> {
      KafkaStreams.State state = streams.state();
      boolean up = state == KafkaStreams.State.RUNNING || state == KafkaStreams.State.REBALANCING;
      byte[] body = state.name().getBytes(StandardCharsets.UTF_8);
      exchange.sendResponseHeaders(up ? 200 : 503, body.length);
      try (OutputStream out = exchange.getResponseBody()) {
        out.write(body);
      }
    });
    server.start();
    return server;
  }
}
