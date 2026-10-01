package com.motion.catalogjoin.sim;

import com.fasterxml.jackson.databind.JsonNode;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Rows;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.sim.SimModel.Slot;
import com.motion.catalogjoin.sim.SimModel.TableRow;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;

/**
 * Computes what the published documents must contain after the given round, straight from the
 * model (no replay), and compares that with what the app actually published. Both sides are
 * reduced to the same summary (trimmed strings, normalized numbers, sorted lists) so the check is
 * about content, not formatting.
 */
public final class Verifier {

  /** Published documents keyed by their Kafka key; only sampled items need to be present. */
  public record Published(Map<String, JsonNode> items, Map<String, JsonNode> itemLocations, Map<String, JsonNode> prices) {}

  public record Mismatch(String kind, String key, String expected, String actual) {}

  public record Report(int itemsChecked, int itemsPresent, int itemLocationsChecked, int pricesChecked, List<Mismatch> mismatches, long mismatchCount) {
    public boolean passed() {
      return mismatchCount == 0;
    }

    public String describe() {
      StringBuilder out = new StringBuilder();
      out.append(String.format(
          "checked %,d items (%,d published), %,d item-location docs, %,d prices: %s%n",
          itemsChecked, itemsPresent, itemLocationsChecked, pricesChecked,
          passed() ? "ALL MATCH" : mismatchCount + " MISMATCHES"));
      for (Mismatch m : mismatches) {
        out.append(String.format("  [%s] %s%n    expected: %s%n    actual:   %s%n", m.kind(), m.key(), m.expected(), m.actual()));
      }
      return out.toString();
    }
  }

  private static final int MAX_REPORTED = 10;

  private final SimModel model;
  private final int round;
  private final int sampleEvery;
  private final Map<String, List<String>> attributeNames = new HashMap<>();

  public Verifier(SimModel model, int round, int sampleEvery) {
    this.model = model;
    this.round = round;
    this.sampleEvery = sampleEvery;
    SimModel.CONFIGURED_ATTRIBUTES.forEach((name, id) -> attributeNames.computeIfAbsent(id, k -> new ArrayList<>()).add(name));
  }

  /** Whether a published key belongs to a sampled item (so readers can skip everything else). */
  public boolean isSampled(String key) {
    String itemNo = Keys.parse(key).get("ITEM_NO");
    if (itemNo == null) {
      return false;
    }
    try {
      int item = Integer.parseInt(itemNo.trim());
      return item >= 0 && item < model.items() && model.sampled(item, sampleEvery);
    } catch (NumberFormatException e) {
      return false;
    }
  }

  public Report verify(Published published) {
    List<Mismatch> reported = new ArrayList<>();
    long[] mismatches = {0};
    int items = 0, present = 0, locationDocs = 0, prices = 0;

    Map<Integer, Map<String, JsonNode>> locationDocsByItem = byItem(published.itemLocations());
    Map<Integer, Map<String, JsonNode>> pricesByItem = byItem(published.prices());

    for (int i = 0; i < model.items(); i++) {
      if (!model.sampled(i, sampleEvery)) {
        continue;
      }
      items++;
      String key = Keys.of("ITEM_NO", SimModel.itemNo(i));
      JsonNode doc = published.items().get(key);
      if (doc != null) {
        present++;
      }
      compare("item", key, expectedItem(i), doc == null ? null : actualItem(doc), reported, mismatches);

      Map<String, Object> expectedLocations = expectedItemLocations(i);
      Map<String, Object> actualLocations = new TreeMap<>();
      locationDocsByItem.getOrDefault(i, Map.of()).forEach((k, v) -> actualLocations.put(k, actualItemLocation(v)));
      locationDocs += Math.max(expectedLocations.size(), actualLocations.size());
      compare("item-location", key, expectedLocations, actualLocations, reported, mismatches);

      Map<String, Object> expectedPrices = expectedPrices(i);
      Map<String, Object> actualPrices = new TreeMap<>();
      pricesByItem.getOrDefault(i, Map.of()).forEach((k, v) -> actualPrices.put(k, num(v.path("PRICE"))));
      prices += Math.max(expectedPrices.size(), actualPrices.size());
      compare("item-price", key, expectedPrices, actualPrices, reported, mismatches);
    }
    return new Report(items, present, locationDocs, prices, reported, mismatches[0]);
  }

  private static void compare(String kind, String key, Object expected, Object actual, List<Mismatch> out, long[] count) {
    String e = Json.writeString(expected);
    String a = Json.writeString(actual);
    if (!e.equals(a)) {
      count[0]++;
      if (out.size() < MAX_REPORTED) {
        out.add(new Mismatch(kind, key, e, a));
      }
    }
  }

  private Map<Integer, Map<String, JsonNode>> byItem(Map<String, JsonNode> docs) {
    Map<Integer, Map<String, JsonNode>> out = new HashMap<>();
    docs.forEach((key, doc) -> {
      if (doc != null && isSampled(key)) {
        int item = Integer.parseInt(Keys.parse(key).get("ITEM_NO"));
        out.computeIfAbsent(item, k -> new TreeMap<>()).put(key, doc);
      }
    });
    return out;
  }

  // --- expected, from the model ------------------------------------------------------------------

  private List<TableRow> rows(Slot slot, int id) {
    return model.rows(slot, id, model.version(slot, id, round));
  }

  private static Map<String, Object> single(List<TableRow> rows) {
    return rows.isEmpty() ? null : rows.get(0).row();
  }

  private static int index(String id) {
    return Integer.parseInt(id.substring(1));
  }

  Map<String, Object> expectedItem(int i) {
    Map<String, Object> item = single(rows(Slot.ITEM, i));
    if (item == null) {
      return null;
    }
    Map<String, Object> out = new TreeMap<>();
    out.put("descr", str(item.get("DESCR")));
    String mfr = str(item.get("MFR_CTL_NO"));
    String group = str(item.get("PRODUCT_GROUP_NO"));
    out.put("mfrCtlNo", mfr);
    out.put("group", group);
    out.put("listPrice", num(item.get("LIST_PRICE")));

    int m = index(mfr);
    Map<String, Object> profile = single(rows(Slot.MFR, m));
    if (profile == null) {
      out.put("manufacturer", null);
    } else {
      Map<String, Object> manufacturer = new TreeMap<>();
      manufacturer.put("sellable", str(profile.get("SELLABLE")));
      Map<String, Object> name = single(rows(Slot.MFR_NAME, index(str(profile.get("MFR_NAME_ID")))));
      manufacturer.put("name", name == null ? null : str(name.get("MFR_NAME")));
      out.put("manufacturer", manufacturer);
    }

    Map<String, Object> rules = new TreeMap<>();
    rules.put("item", sorted(rows(Slot.ITEM_RULES, i).stream().map(r -> str(r.row().get("CTL_NO"))).toList()));
    List<TableRow> mfrRules = rows(Slot.MFR_RULES, m);
    rules.put("mfr", sorted(mfrRules.stream().filter(r -> Rows.isBlank(r.row(), "PROD_GROUP_NO"))
        .map(r -> str(r.row().get("CTL_NO"))).toList()));
    rules.put("group", sorted(mfrRules.stream().filter(r -> group.equals(Rows.str(r.row(), "PROD_GROUP_NO")))
        .map(r -> str(r.row().get("CTL_NO"))).toList()));
    out.put("rules", rules);

    List<String> dcStock = new ArrayList<>();
    for (TableRow balance : rows(Slot.BALANCES, i)) {
      String miLoc = str(balance.row().get("MI_LOC"));
      Map<String, Object> location = single(rows(Slot.LOCATION, Integer.parseInt(miLoc)));
      if (location != null && "W".equals(location.get("LOCATION_TYPE")) && "O".equals(location.get("OPEN_CLOSED"))) {
        dcStock.add(miLoc + "/" + str(balance.row().get("STOREROOM_NO")) + "=" + num(balance.row().get("QTY_ON_HAND")));
      }
    }
    out.put("dcStock", sorted(dcStock));
    out.put("costs", sorted(rows(Slot.ITEM_COST, i).stream()
        .map(r -> str(r.row().get("CORP_MI_LOC")) + "=" + num(r.row().get("COST"))).toList()));

    List<Map<String, Object>> products = new ArrayList<>();
    Set<Integer> candidates = new LinkedHashSet<>(List.of(i, i ^ 1));
    for (int p : candidates) {
      if (p >= model.items()) {
        continue;
      }
      List<TableRow> productRows = rows(Slot.PRODUCT, p);
      boolean bridged = productRows.stream().anyMatch(r -> r.table() == SourceTable.STEP_PRODUCT_VALUES
          && SimModel.ATTR_ITEM.equals(r.row().get("STEP_ATTRIBUTE_ID"))
          && SimModel.itemNo(i).equals(str(r.row().get("VALUE"))));
      if (bridged) {
        products.add(expectedProduct(p, productRows));
      }
    }
    products.sort((a, b) -> ((String) a.get("id")).compareTo((String) b.get("id")));
    out.put("stepProducts", products);
    return out;
  }

  private Map<String, Object> expectedProduct(int p, List<TableRow> rows) {
    Map<String, Object> out = new TreeMap<>();
    out.put("id", SimModel.productId(p));
    Map<String, List<String>> attributes = new TreeMap<>();
    List<String> weightUnits = new ArrayList<>();
    List<Map<String, Object>> classes = new ArrayList<>();
    for (TableRow row : rows) {
      switch (row.table()) {
        case STEP_PRODUCT -> out.put("name", str(row.row().get("PRODUCT_NAME")));
        case STEP_PRODUCT_VALUES -> {
          String attribute = (String) row.row().get("STEP_ATTRIBUTE_ID");
          for (String name : attributeNames.getOrDefault(attribute, List.of())) {
            attributes.computeIfAbsent(name, k -> new ArrayList<>()).add(str(row.row().get("VALUE")));
            if (name.equals("SHIPPING_WEIGHT")) {
              Map<String, Object> unit = single(rows(Slot.UNIT, index(str(row.row().get("STEP_UNIT_ID")))));
              weightUnits.add(unit == null ? null : str(unit.get("UNIT_NAME")));
            }
          }
        }
        case STEP_PRODUCT_CLASSIFICATION -> classes.add(expectedClass(str(row.row().get("STEP_CLASSIFICATION_ID"))));
        default -> {}
      }
    }
    out.putIfAbsent("name", null);
    attributes.values().forEach(v -> v.sort(null));
    out.put("attributes", attributes);
    out.put("weightUnits", sorted(weightUnits));
    classes.sort((a, b) -> ((String) a.get("id")).compareTo((String) b.get("id")));
    out.put("classes", classes);
    return out;
  }

  private Map<String, Object> expectedClass(String classId) {
    List<String> path = new ArrayList<>();
    String current = classId;
    String top = null;
    while (current.startsWith("C")) {
      Map<String, Object> row = single(rows(Slot.CLASS, index(current)));
      if (row == null) {
        break;
      }
      path.add(0, str(row.get("CLASSIFICATION_NAME")));
      top = str(row.get("PARENT_STEP_CLASSIFICATION_ID"));
      current = top;
    }
    Map<String, Object> out = new TreeMap<>();
    out.put("id", classId);
    out.put("inWeb", SimModel.ROOT.equals(top));
    out.put("path", path);
    return out;
  }

  Map<String, Object> expectedItemLocations(int i) {
    Map<String, Object> out = new TreeMap<>();
    Map<String, List<String>> balances = new TreeMap<>();
    Map<String, Object> nonCos = new TreeMap<>();
    Map<String, List<String>> localCosts = new TreeMap<>();
    for (TableRow r : rows(Slot.BALANCES, i)) {
      balances.computeIfAbsent(str(r.row().get("MI_LOC")), k -> new ArrayList<>())
          .add(str(r.row().get("STOREROOM_NO")) + "=" + num(r.row().get("QTY_ON_HAND")));
    }
    for (TableRow r : rows(Slot.NON_COS, i)) {
      nonCos.put(str(r.row().get("MI_LOC")), num(r.row().get("QTY")));
    }
    for (TableRow r : rows(Slot.LOCAL_COSTS, i)) {
      localCosts.computeIfAbsent(str(r.row().get("MI_LOC")), k -> new ArrayList<>())
          .add(str(r.row().get("EFFECTIVE_DATE")) + "|" + str(r.row().get("EXPIRATION_DATE")) + "=" + num(r.row().get("COST")));
    }
    Set<String> locs = new java.util.TreeSet<>();
    locs.addAll(balances.keySet());
    locs.addAll(nonCos.keySet());
    locs.addAll(localCosts.keySet());
    for (String loc : locs) {
      Map<String, Object> doc = new TreeMap<>();
      Map<String, Object> location = single(rows(Slot.LOCATION, Integer.parseInt(loc)));
      doc.put("location", location == null ? null : str(location.get("OPEN_CLOSED")));
      doc.put("balances", sorted(balances.getOrDefault(loc, List.of())));
      doc.put("nonCos", nonCos.get(loc));
      doc.put("localCosts", sorted(localCosts.getOrDefault(loc, List.of())));
      out.put(Keys.of("ITEM_NO", SimModel.itemNo(i), "MI_LOC", loc), doc);
    }
    return out;
  }

  Map<String, Object> expectedPrices(int i) {
    Map<String, Object> out = new TreeMap<>();
    for (TableRow r : rows(Slot.PRICES, i)) {
      out.put(Keys.of(r.row(), SourceTable.ITEM_PRICE_CACHE.keyColumns()), num(r.row().get("PRICE")));
    }
    return out;
  }

  // --- actual, from published JSON -----------------------------------------------------------------

  static Map<String, Object> actualItem(JsonNode doc) {
    Map<String, Object> out = new TreeMap<>();
    JsonNode item = doc.path("item");
    out.put("descr", str(item.path("DESCR")));
    out.put("mfrCtlNo", str(item.path("MFR_CTL_NO")));
    out.put("group", str(item.path("PRODUCT_GROUP_NO")));
    out.put("listPrice", num(item.path("LIST_PRICE")));

    JsonNode manufacturer = doc.path("manufacturer");
    if (manufacturer.isNull() || manufacturer.isMissingNode()) {
      out.put("manufacturer", null);
    } else {
      Map<String, Object> m = new TreeMap<>();
      m.put("sellable", str(manufacturer.path("profile").path("SELLABLE")));
      JsonNode name = manufacturer.path("name");
      m.put("name", name.isNull() || name.isMissingNode() ? null : str(name.path("MFR_NAME")));
      out.put("manufacturer", m);
    }

    Map<String, Object> rules = new TreeMap<>();
    rules.put("item", texts(doc.path("restrictions").path("item"), "CTL_NO"));
    rules.put("mfr", texts(doc.path("restrictions").path("manufacturer"), "CTL_NO"));
    rules.put("group", texts(doc.path("restrictions").path("manufacturerProductGroup"), "CTL_NO"));
    out.put("rules", rules);

    List<String> dcStock = new ArrayList<>();
    doc.path("dcStock").forEach(entry -> {
      JsonNode balance = entry.path("balance");
      dcStock.add(str(balance.path("MI_LOC")) + "/" + str(balance.path("STOREROOM_NO")) + "=" + num(balance.path("QTY_ON_HAND")));
    });
    out.put("dcStock", sorted(dcStock));
    List<String> costs = new ArrayList<>();
    doc.path("costs").forEach(c -> costs.add(str(c.path("CORP_MI_LOC")) + "=" + num(c.path("COST"))));
    out.put("costs", sorted(costs));

    List<Map<String, Object>> products = new ArrayList<>();
    doc.path("stepProducts").forEach(p -> {
      Map<String, Object> product = new TreeMap<>();
      product.put("id", str(p.path("stepProductId")));
      JsonNode row = p.path("product");
      product.put("name", row.isNull() || row.isMissingNode() ? null : str(row.path("PRODUCT_NAME")));
      Map<String, List<String>> attributes = new TreeMap<>();
      List<String> weightUnits = new ArrayList<>();
      p.path("attributes").fields().forEachRemaining(field -> {
        List<String> values = new ArrayList<>();
        field.getValue().forEach(v -> {
          values.add(str(v.path("value")));
          if (field.getKey().equals("SHIPPING_WEIGHT")) {
            JsonNode unit = v.path("unit");
            weightUnits.add(unit.isNull() || unit.isMissingNode() ? null : str(unit.path("UNIT_NAME")));
          }
        });
        values.sort(null);
        attributes.put(field.getKey(), values);
      });
      product.put("attributes", attributes);
      product.put("weightUnits", sorted(weightUnits));
      List<Map<String, Object>> classes = new ArrayList<>();
      p.path("classifications").forEach(c -> {
        Map<String, Object> cls = new TreeMap<>();
        cls.put("id", str(c.path("stepClassificationId")));
        cls.put("inWeb", c.path("inWebHierarchy").asBoolean());
        List<String> path = new ArrayList<>();
        c.path("path").forEach(node -> path.add(str(node.path("CLASSIFICATION_NAME"))));
        cls.put("path", path);
        classes.add(cls);
      });
      classes.sort((a, b) -> ((String) a.get("id")).compareTo((String) b.get("id")));
      product.put("classes", classes);
      products.add(product);
    });
    products.sort((a, b) -> ((String) a.get("id")).compareTo((String) b.get("id")));
    out.put("stepProducts", products);
    return out;
  }

  static Map<String, Object> actualItemLocation(JsonNode doc) {
    Map<String, Object> out = new TreeMap<>();
    JsonNode location = doc.path("location");
    out.put("location", location.isNull() || location.isMissingNode() ? null : str(location.path("OPEN_CLOSED")));
    List<String> balances = new ArrayList<>();
    doc.path("balances").forEach(b -> balances.add(str(b.path("STOREROOM_NO")) + "=" + num(b.path("QTY_ON_HAND"))));
    out.put("balances", sorted(balances));
    JsonNode nonCos = doc.path("nonCosBalance");
    out.put("nonCos", nonCos.isNull() || nonCos.isMissingNode() ? null : num(nonCos.path("QTY")));
    List<String> localCosts = new ArrayList<>();
    doc.path("localCosts").forEach(c -> localCosts.add(
        str(c.path("EFFECTIVE_DATE")) + "|" + str(c.path("EXPIRATION_DATE")) + "=" + num(c.path("COST"))));
    out.put("localCosts", sorted(localCosts));
    return out;
  }

  // --- normalization -------------------------------------------------------------------------------

  private static List<String> texts(JsonNode array, String field) {
    List<String> out = new ArrayList<>();
    array.forEach(node -> out.add(str(node.path(field))));
    return sorted(out);
  }

  private static List<String> sorted(List<String> values) {
    List<String> copy = new ArrayList<>(values);
    copy.sort((a, b) -> Objects.compare(a, b, (x, y) -> x.compareTo(y)));
    return copy;
  }

  private static String str(Object value) {
    if (value == null) {
      return null;
    }
    if (value instanceof JsonNode node) {
      return node.isNull() || node.isMissingNode() ? null : node.asText().trim();
    }
    return value.toString().trim();
  }

  private static String num(Object value) {
    String text = str(value);
    if (text == null || text.isEmpty()) {
      return text;
    }
    try {
      BigDecimal decimal = new BigDecimal(text);
      return decimal.signum() == 0 ? "0" : decimal.stripTrailingZeros().toPlainString();
    } catch (NumberFormatException e) {
      return text;
    }
  }
}
