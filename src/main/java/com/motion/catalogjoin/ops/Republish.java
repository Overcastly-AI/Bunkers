package com.motion.catalogjoin.ops;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Topics;
import com.motion.catalogjoin.clients.Client;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

/**
 * {@code catalog-join republish}: asks the running app to publish the current document for some
 * keys again, even though it has not changed. A request is a record on {@code
 * <catalog.output.republish>.<doc>}, keyed like the document; the app looks the document up when it
 * processes the request, so a republish never overtakes a newer update. A key with no document
 * publishes a tombstone.
 */
public final class Republish {

  /** One request: the document type ({@code item} or {@code item-location}) and, optionally, which outputs. */
  public record Request(String doc, Set<String> outputs) {

    /** Whether the output {@code name} ({@code item}, {@code item-location} or {@code client-NAME}) should publish. */
    public boolean wants(String source, String name) {
      return doc.equals(source) && (outputs.isEmpty() || outputs.contains(name));
    }
  }

  private Republish() {}

  public static String encode(Request request) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("doc", request.doc());
    value.put("outputs", List.copyOf(request.outputs()));
    return Json.writeString(value);
  }

  /** The request, or null for a malformed one (which the app ignores). */
  public static Request decode(String value) {
    try {
      Map<String, Object> map = Json.read(value);
      Object outputs = map.get("outputs");
      Set<String> names = new TreeSet<>();
      if (outputs instanceof List<?> list) {
        list.forEach(o -> names.add(String.valueOf(o)));
      }
      return map.get("doc") instanceof String doc ? new Request(doc, names) : null;
    } catch (RuntimeException e) {
      return null;
    }
  }

  /**
   * A canonical document key from {@code COLUMN=value[,COLUMN=value]}, checked against the
   * document type's key columns.
   */
  public static String key(String doc, String text) {
    Set<String> expected = new TreeSet<>(Arrays.asList(Client.SOURCES.get(doc).split(",")));
    Map<String, Object> row = new HashMap<>();
    for (String part : text.split(",")) {
      String[] kv = part.split("=", 2);
      if (kv.length != 2 || kv[1].isBlank()) {
        throw new IllegalArgumentException("Bad key '" + text + "'; expected " + String.join("=…,", expected) + "=…");
      }
      row.put(kv[0].trim().toUpperCase(java.util.Locale.ROOT), kv[1].trim());
    }
    if (!row.keySet().equals(expected)) {
      throw new IllegalArgumentException("A " + doc + " key has columns " + expected + ", not " + row.keySet() + " ('" + text + "')");
    }
    return Keys.of(row, expected);
  }

  /** Output names that {@code doc} documents publish to: the document topic and its clients. */
  public static Set<String> outputs(CatalogConfig config, String doc) {
    Set<String> names = new TreeSet<>(Set.of(doc));
    config.clients().values().stream().filter(c -> c.source().equals(doc)).forEach(c -> names.add("client-" + c.name()));
    return names;
  }

  /** CLI: {@code republish [config ...] --doc item|item-location (--key K ... | --keys-file F) [--only NAME ...]}. */
  public static int run(CatalogConfig config, String doc, List<String> keyArgs, List<String> keyFiles, List<String> only)
      throws IOException {
    if (doc.equals("item-price")) {
      System.err.println("item-price documents are a 1:1 copy of ITEM_PRICE_CACHE; re-produce that source row instead.");
      return 2;
    }
    if (!Client.SOURCES.containsKey(doc)) {
      System.err.println("--doc must be one of " + Client.SOURCES.keySet() + ", not " + doc);
      return 2;
    }
    Set<String> available = outputs(config, doc);
    Set<String> outputs = new TreeSet<>();
    for (String name : only) {
      String output = name.equals(doc) || name.startsWith("client-") ? name : "client-" + name;
      if (!available.contains(output)) {
        System.err.println("--only " + name + ": " + doc + " documents publish to " + available);
        return 2;
      }
      outputs.add(output);
    }
    Set<String> keys = new LinkedHashSet<>();
    keyArgs.forEach(k -> keys.add(key(doc, k)));
    for (String file : keyFiles) {
      for (String line : Files.readAllLines(Path.of(file))) {
        if (!line.isBlank() && !line.startsWith("#")) {
          keys.add(key(doc, line.trim()));
        }
      }
    }
    if (keys.isEmpty()) {
      System.err.println("No keys: pass --key COLUMN=value[,COLUMN=value] or --keys-file FILE");
      return 2;
    }
    send(config, new Request(doc, outputs), keys);
    System.out.printf("Requested %,d %s document(s) to be republished to %s%n", keys.size(), doc,
        outputs.isEmpty() ? available : outputs);
    return 0;
  }

  /** Produces one request per key to the control topic. */
  public static void send(CatalogConfig config, Request request, Iterable<String> keys) {
    Map<String, Object> props = new HashMap<>(Topics.adminClient(config));
    props.put(ProducerConfig.ACKS_CONFIG, "all");
    props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
    String value = encode(request);
    List<java.util.concurrent.Future<?>> sent = new ArrayList<>();
    try (KafkaProducer<String, String> producer = new KafkaProducer<>(props, new StringSerializer(), new StringSerializer())) {
      for (String key : keys) {
        sent.add(producer.send(new ProducerRecord<>(config.republishTopic(request.doc()), key, value)));
      }
      producer.flush();
      for (var future : sent) {
        future.get();
      }
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException(e);
    } catch (java.util.concurrent.ExecutionException e) {
      throw new IllegalStateException("Could not send republish requests to " + config.republishTopic(request.doc()), e.getCause());
    }
  }
}
