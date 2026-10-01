package com.motion.catalogjoin;

import com.motion.catalogjoin.sim.Simulation;
import com.motion.catalogjoin.topology.CatalogTopology;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.function.Predicate;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.KafkaStreams.State;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.errors.StreamsUncaughtExceptionHandler.StreamThreadExceptionResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Command-line entry point. Every command reads the same layered configuration. */
public final class App {

  private static final Logger LOG = LoggerFactory.getLogger(App.class);

  private static final String USAGE = """
      Usage: catalog-join <command> [config.properties ...] [--set key=value ...]

      Commands:
        run             Run the joiner (default when the first argument is a file).
        create-topics   Create the output and dead-letter topics (catalog.output.*).
        print-config    Print the effective configuration (secrets masked).
        sim-generate    Load simulation: produce sim.* rounds to the source topics. --create-topics also
                        creates source and output topics.
        sim-verify      Load simulation: wait for the app to catch up, then check its output.

      Configuration: catalog-join.properties in the jar holds every setting and its default. Files are
      layered on top in order (later wins), then --set overrides. With no files, CATALOG_CONFIG (a
      comma-separated list of files) is used when set.
      """;

  private App() {}

  public static void main(String[] argv) throws Exception {
    List<String> args = new ArrayList<>(List.of(argv));
    String command = args.isEmpty() || args.get(0).endsWith(".properties") ? "run" : args.remove(0);
    List<Path> files = new ArrayList<>();
    Map<String, String> overrides = new LinkedHashMap<>();
    Set<String> flags = new java.util.HashSet<>();
    for (int i = 0; i < args.size(); i++) {
      String arg = args.get(i);
      if (arg.equals("--set") && i + 1 < args.size()) {
        String[] kv = args.get(++i).split("=", 2);
        overrides.put(kv[0], kv.length > 1 ? kv[1] : "");
      } else if (arg.startsWith("--")) {
        flags.add(arg.substring(2));
      } else {
        files.add(Path.of(arg));
      }
    }
    String fromEnv = System.getenv("CATALOG_CONFIG");
    if (files.isEmpty() && fromEnv != null && !fromEnv.isBlank()) {
      for (String file : fromEnv.split(",")) {
        files.add(Path.of(file.trim()));
      }
    }

    int exit = switch (command) {
      case "run" -> run(CatalogConfig.load(files, overrides));
      case "create-topics" -> {
        Topics.createOutputs(CatalogConfig.load(files, overrides));
        yield 0;
      }
      case "print-config" -> {
        CatalogConfig.load(files, overrides).describe().forEach((k, v) -> System.out.println(k + "=" + v));
        yield 0;
      }
      case "sim-generate" -> Simulation.generate(CatalogConfig.load(files, overrides), flags.contains("create-topics"));
      case "sim-verify" -> Simulation.verify(CatalogConfig.load(files, overrides));
      case "help", "--help", "-h" -> {
        System.out.print(USAGE);
        yield 0;
      }
      default -> {
        System.err.print("Unknown command " + command + "\n\n" + USAGE);
        yield 2;
      }
    };
    System.exit(exit);
  }

  /** Runs Kafka Streams until it stops; non-zero exit if it failed, so the orchestrator restarts it. */
  private static int run(CatalogConfig config) throws Exception {
    BoundedRocksDb.configure(config.rocksDbMemoryBytes(), config.rocksDbMemtableShare());
    Topology topology = CatalogTopology.build(config);
    LOG.info("Topology:\n{}", topology.describe());

    KafkaStreams streams = new KafkaStreams(topology, config.streamsProperties());
    CountDownLatch stopped = new CountDownLatch(1);
    int[] exitCode = {0};
    streams.setUncaughtExceptionHandler(e -> {
      LOG.error("Stream thread failed; shutting down", e);
      exitCode[0] = 1;
      return StreamThreadExceptionResponse.SHUTDOWN_CLIENT;
    });
    streams.setStateListener((next, previous) -> {
      LOG.info("State {} -> {}", previous, next);
      if (next == State.ERROR) {
        exitCode[0] = 1;
      }
      if (next == State.NOT_RUNNING || next == State.ERROR) {
        stopped.countDown();
      }
    });

    HttpServer health = config.healthPort() > 0 ? startHealth(config.healthPort(), streams) : null;
    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
      streams.close(config.shutdownTimeout());
      stopped.countDown();
    }, "shutdown"));

    streams.start();
    stopped.await();
    streams.close(config.shutdownTimeout());
    if (health != null) {
      health.stop(0);
    }
    return exitCode[0];
  }

  /**
   * {@code /health/live}: 200 unless Kafka Streams has failed or stopped (restoring state is live).
   * {@code /health/ready}: 200 only while RUNNING.
   */
  private static HttpServer startHealth(int port, KafkaStreams streams) throws IOException {
    HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
    Set<State> dead = Set.of(State.ERROR, State.PENDING_ERROR, State.NOT_RUNNING, State.PENDING_SHUTDOWN);
    respond(server, "/health/live", streams, state -> !dead.contains(state));
    respond(server, "/health/ready", streams, state -> state == State.RUNNING);
    server.start();
    return server;
  }

  private static void respond(HttpServer server, String path, KafkaStreams streams, Predicate<State> ok) {
    server.createContext(path, exchange -> {
      State state = streams.state();
      byte[] body = state.name().getBytes(StandardCharsets.UTF_8);
      exchange.sendResponseHeaders(ok.test(state) ? 200 : 503, body.length);
      try (OutputStream out = exchange.getResponseBody()) {
        out.write(body);
      }
    });
  }
}
