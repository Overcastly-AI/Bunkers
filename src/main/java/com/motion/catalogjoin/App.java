package com.motion.catalogjoin;

import com.motion.catalogjoin.clients.HttpDelivery;
import com.motion.catalogjoin.ops.DltReplay;
import com.motion.catalogjoin.ops.ReplayClient;
import com.motion.catalogjoin.ops.Republish;
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
        tracer-config   Write the Datadog agent settings (dd.*) to FILE when tracing is on (used by
                        bin/catalog-join): catalog-join tracer-config FILE [config ...]
        sim-generate    Load simulation: produce sim.* rounds to the source topics. --create-topics also
                        creates source and output topics.
        sim-verify      Load simulation: wait for the app to catch up, then check its output.
        deliver         Post a client's topic to its HTTP endpoint: deliver [config ...] --client NAME
                        (catalog.client.NAME.*; see catalog-join.properties).

      Replay (see README "Replay"):
        republish       Publish the current document for some keys again, even if unchanged:
                        republish [config ...] [--doc item|item-location] --key ITEM_NO=1[,MI_LOC=X] ...
                        [--keys-file FILE] [--only item|item-location|CLIENT ...]
        replay-client   Move a client's delivery back so deliver re-posts from there (deliver stopped):
                        replay-client [config ...] --client NAME --from earliest|2026-10-01T00:00:00Z [--dry-run]
        dlt-replay      Replay dead letters after fixing their cause: source dead letters go back to
                        their topic unless a newer record for the key exists (--force replays anyway);
                        with --client NAME, rejected batches' keys are republished with current values.
                        dlt-replay [config ...] [--client NAME] [--force] [--from-beginning] [--dry-run]

      Configuration: catalog-join.properties in the jar holds every setting and its default. Files are
      layered on top in order (later wins), then --set overrides. With no files, CATALOG_CONFIG (a
      comma-separated list of files) is used when set.
      """;

  private App() {}

  public static void main(String[] argv) throws Exception {
    List<String> args = new ArrayList<>(List.of(argv));
    String command = args.isEmpty() || args.get(0).endsWith(".properties") ? "run" : args.remove(0);
    Path output = command.equals("tracer-config") && !args.isEmpty() ? Path.of(args.remove(0)) : null;
    List<Path> files = new ArrayList<>();
    Map<String, String> overrides = new LinkedHashMap<>();
    Set<String> flags = new java.util.HashSet<>();
    Map<String, List<String>> options = new LinkedHashMap<>();
    Set<String> repeatable = Set.of("--doc", "--key", "--keys-file", "--only", "--from");
    for (int i = 0; i < args.size(); i++) {
      String arg = args.get(i);
      if (arg.equals("--set") && i + 1 < args.size()) {
        String[] kv = args.get(++i).split("=", 2);
        overrides.put(kv[0], kv.length > 1 ? kv[1] : "");
      } else if (arg.equals("--client") && i + 1 < args.size()) {
        overrides.put("client", args.get(++i));
      } else if (repeatable.contains(arg) && i + 1 < args.size()) {
        options.computeIfAbsent(arg.substring(2), k -> new ArrayList<>()).add(args.get(++i));
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

    int exit;
    try {
      exit = dispatch(command, files, overrides, flags, options, output);
    } catch (Exception | Error e) {
      // Kafka clients start non-daemon threads; without an explicit exit a failed startup (bad
      // config, port in use, ...) would leave a live process that does nothing.
      LOG.error("{} failed", command, e);
      exit = 1;
    }
    System.exit(exit);
  }

  private static int dispatch(String command, List<Path> files, Map<String, String> overrides, Set<String> flags,
      Map<String, List<String>> options, Path output) throws Exception {
    return switch (command) {
      case "run" -> run(CatalogConfig.load(files, overrides).requireNoPlaceholders());
      case "create-topics" -> {
        Topics.createOutputs(CatalogConfig.load(files, overrides).requireNoPlaceholders());
        yield 0;
      }
      case "tracer-config" -> writeTracerConfig(CatalogConfig.load(files, overrides), output);
      case "print-config" -> {
        CatalogConfig.load(files, overrides).describe().forEach((k, v) -> System.out.println(k + "=" + v));
        yield 0;
      }
      case "sim-generate" -> Simulation.generate(CatalogConfig.load(files, overrides), flags.contains("create-topics"));
      case "sim-verify" -> Simulation.verify(CatalogConfig.load(files, overrides));
      case "deliver" -> {
        String client = overrides.remove("client");
        yield client == null ? usage() : HttpDelivery.run(CatalogConfig.load(files, overrides).requireNoPlaceholders(), client);
      }
      case "republish" -> {
        List<String> doc = options.getOrDefault("doc", List.of("item"));
        yield Republish.run(CatalogConfig.load(files, overrides), doc.get(doc.size() - 1),
            options.getOrDefault("key", List.of()), options.getOrDefault("keys-file", List.of()), options.getOrDefault("only", List.of()));
      }
      case "replay-client" -> {
        String client = overrides.remove("client");
        List<String> from = options.getOrDefault("from", List.of());
        yield client == null ? usage()
            : ReplayClient.run(CatalogConfig.load(files, overrides), client, from.isEmpty() ? null : from.get(0), flags.contains("dry-run"));
      }
      case "dlt-replay" -> {
        String client = overrides.remove("client");
        yield DltReplay.run(CatalogConfig.load(files, overrides), client,
            flags.contains("force"), flags.contains("from-beginning"), flags.contains("dry-run"));
      }
      case "help", "--help", "-h" -> {
        System.out.print(USAGE);
        yield 0;
      }
      default -> {
        System.err.print("Unknown command " + command + "\n\n" + USAGE);
        yield 2;
      }
    };
  }

  private static int usage() {
    System.err.print(USAGE);
    return 2;
  }

  /** Writes dd.* settings for the Datadog agent; leaves the file empty when tracing is off. */
  private static int writeTracerConfig(CatalogConfig config, Path output) throws IOException {
    if (output == null) {
      System.err.print(USAGE);
      return 2;
    }
    try (var out = java.nio.file.Files.newBufferedWriter(output)) {
      config.tracerProperties().store(out, "Datadog agent settings from catalog-join configuration");
    }
    if (config.tracerProperties().isEmpty()) {
      java.nio.file.Files.write(output, new byte[0]);
    }
    return 0;
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
