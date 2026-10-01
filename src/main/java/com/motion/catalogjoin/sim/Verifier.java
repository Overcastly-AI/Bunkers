package com.motion.catalogjoin.sim;

import static com.motion.catalogjoin.model.Docs.list;
import static com.motion.catalogjoin.model.Docs.map;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Json;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Rows;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.model.Docs;
import com.motion.catalogjoin.sim.SimModel.Slot;
import com.motion.catalogjoin.sim.SimModel.TableRow;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

/**
 * Checks published documents against the model. Two independent extractors feed the same summary
 * builders: one reads the model's rows after the final round (no replay), the other reads what the
 * app published. Summaries keep only content (trimmed strings, normalized numbers, sorted lists).
 */
public final class Verifier {

  public record Mismatch(String kind, String key, String expected, String actual) {}

  public record Report(int itemsChecked, int itemsPresent, int itemLocationsChecked, int pricesChecked,
      List<Mismatch> mismatches, long mismatchCount) {

    public boolean passed() {
      return mismatchCount == 0;
    }

    public String describe() {
      StringBuilder out = new StringBuilder(String.format(
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

  private final CatalogConfig config;
  private final SimModel model;
  private final int round;
  private final int sampleEvery;

  public Verifier(CatalogConfig config) {
    this.config = config;
    this.model = new SimModel(config);
    this.round = config.sim().rounds();
    this.sampleEvery = config.sim().sampleEvery();
  }

  /** Whether a published key belongs to a sampled item, so readers can skip everything else. */
  public boolean isSampled(String key) {
    Integer item = itemIndex(key);
    return item != null && model.sampled(item, sampleEvery);
  }

  private Integer itemIndex(String key) {
    try {
      int item = Integer.parseInt(Keys.part(key, "ITEM_NO"));
      return item >= 0 && item < model.items() ? item : null;
    } catch (RuntimeException e) {
      return null;
    }
  }

  public Report verify(Outputs published) {
    List<Mismatch> reported = new ArrayList<>();
    long[] mismatches = {0};
    int items = 0, present = 0, locationDocs = 0, prices = 0;
    Map<Integer, Map<String, Object>> locationsByItem = byItem(published.latest(config.itemLocationTopic()), Verifier::actualLocation);
    Map<Integer, Map<String, Object>> pricesByItem = byItem(published.latest(config.itemPriceTopic()), row -> num(row.get("PRICE")));

    for (int i = 0; i < model.items(); i++) {
      if (!model.sampled(i, sampleEvery)) {
        continue;
      }
      items++;
      String key = Keys.of("ITEM_NO", SimModel.itemNo(i));
      Map<String, Object> doc = published.latest(config.itemTopic()).get(key);
      present += doc == null ? 0 : 1;
      compare("item", key, expectedItem(i), doc == null ? null : actualItem(doc), reported, mismatches);

      Map<String, Object> expectedLocations = expectedLocations(i);
      Map<String, Object> actualLocations = locationsByItem.getOrDefault(i, Map.of());
      locationDocs += Math.max(expectedLocations.size(), actualLocations.size());
      compare("item-location", key, expectedLocations, actualLocations, reported, mismatches);

      Map<String, Object> expectedPrices = new TreeMap<>();
      rows(Slot.PRICES, i).forEach(r -> expectedPrices.put(config.key(SourceTable.ITEM_PRICE_CACHE, r.row()), num(r.row().get("PRICE"))));
      Map<String, Object> actualPrices = pricesByItem.getOrDefault(i, Map.of());
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

  private Map<Integer, Map<String, Object>> byItem(Map<String, Map<String, Object>> docs,
      java.util.function.Function<Map<String, Object>, Object> summary) {
    Map<Integer, Map<String, Object>> out = new HashMap<>();
    docs.forEach((key, doc) -> {
      Integer item = itemIndex(key);
      if (item != null && model.sampled(item, sampleEvery)) {
        out.computeIfAbsent(item, k -> new TreeMap<>()).put(key, summary.apply(doc));
      }
    });
    return out;
  }

  // --- summaries, shared by both sides ------------------------------------------------------------

  private static Map<String, Object> itemSummary(Map<String, Object> item, Map<String, Object> profile,
      Map<String, Object> name, List<String> itemRules, List<String> mfrRules, List<String> groupRules,
      List<Map<String, Object>> dcBalances, List<Map<String, Object>> costs, List<Map<String, Object>> products) {
    Map<String, Object> out = new TreeMap<>();
    out.put("descr", str(item.get("DESCR")));
    out.put("mfrCtlNo", str(item.get("MFR_CTL_NO")));
    out.put("group", str(item.get("PRODUCT_GROUP_NO")));
    out.put("listPrice", num(item.get("LIST_PRICE")));
    out.put("manufacturer", profile == null ? null
        : Docs.of("sellable", str(profile.get("SELLABLE")), "name", name == null ? null : str(name.get("MFR_NAME"))));
    out.put("rules", Map.of("item", sorted(itemRules), "mfr", sorted(mfrRules), "group", sorted(groupRules)));
    out.put("dcStock", sorted(dcBalances.stream()
        .map(b -> str(b.get("MI_LOC")) + "/" + str(b.get("STOREROOM_NO")) + "=" + num(b.get("QTY_ON_HAND"))).toList()));
    out.put("costs", sorted(costs.stream().map(c -> str(c.get("CORP_MI_LOC")) + "=" + num(c.get("COST"))).toList()));
    List<Map<String, Object>> sortedProducts = new ArrayList<>(products);
    sortedProducts.sort(Comparator.comparing(p -> (String) p.get("id")));
    out.put("stepProducts", sortedProducts);
    return out;
  }

  /** attributes: name -> [(value, unit row)]; classes: [(id, inWebHierarchy, path rows)]. */
  private static Map<String, Object> productSummary(String id, Map<String, Object> product,
      Map<String, List<Object[]>> attributes, List<Object[]> classes) {
    Map<String, Object> out = new TreeMap<>();
    out.put("id", id);
    out.put("name", product == null ? null : str(product.get("PRODUCT_NAME")));
    Map<String, List<String>> named = new TreeMap<>();
    attributes.forEach((name, entries) -> named.put(name, sorted(entries.stream()
        .map(e -> str(e[0]) + "@" + (e[1] == null ? "-" : str(map(e[1]).get("UNIT_NAME")))).toList())));
    out.put("attributes", named);
    List<String> summaries = new ArrayList<>();
    for (Object[] c : classes) {
      List<String> names = list(c[2]).stream().map(r -> str(r.get("CLASSIFICATION_NAME"))).toList();
      summaries.add(c[0] + (Boolean.TRUE.equals(c[1]) ? " web " : " other ") + names);
    }
    out.put("classes", sorted(summaries));
    return out;
  }

  private static Map<String, Object> locationSummary(Map<String, Object> location, List<Map<String, Object>> balances,
      Map<String, Object> nonCos, List<Map<String, Object>> localCosts) {
    Map<String, Object> out = new TreeMap<>();
    out.put("location", location == null ? null : str(location.get("OPEN_CLOSED")));
    out.put("balances", sorted(balances.stream().map(b -> str(b.get("STOREROOM_NO")) + "=" + num(b.get("QTY_ON_HAND"))).toList()));
    out.put("nonCos", nonCos == null ? null : num(nonCos.get("QTY")));
    out.put("localCosts", sorted(localCosts.stream()
        .map(c -> str(c.get("EFFECTIVE_DATE")) + "|" + str(c.get("EXPIRATION_DATE")) + "=" + num(c.get("COST"))).toList()));
    return out;
  }

  // --- actual: what the app published --------------------------------------------------------------

  private static Map<String, Object> actualItem(Map<String, Object> doc) {
    Map<String, Object> manufacturer = map(doc.get("manufacturer"));
    Map<String, Object> restrictions = map(doc.get("restrictions"));
    List<Map<String, Object>> products = new ArrayList<>();
    for (Map<String, Object> p : list(doc.get("stepProducts"))) {
      Map<String, List<Object[]>> attributes = new TreeMap<>();
      map(p.get("attributes")).forEach((name, entries) -> attributes.put(name,
          list(entries).stream().map(e -> new Object[] {e.get("value"), e.get("unit")}).toList()));
      List<Object[]> classes = list(p.get("classifications")).stream()
          .map(c -> new Object[] {str(c.get("stepClassificationId")), c.get("inWebHierarchy"), c.get("path")}).toList();
      products.add(productSummary(str(p.get("stepProductId")), map(p.get("product")), attributes, classes));
    }
    return itemSummary(map(doc.get("item")),
        manufacturer == null ? null : map(manufacturer.get("profile")),
        manufacturer == null ? null : map(manufacturer.get("name")),
        ids(restrictions.get("item")), ids(restrictions.get("manufacturer")), ids(restrictions.get("manufacturerProductGroup")),
        list(doc.get("dcStock")).stream().map(e -> map(e.get("balance"))).toList(),
        list(doc.get("costs")), products);
  }

  private static Map<String, Object> actualLocation(Map<String, Object> doc) {
    return locationSummary(map(doc.get("location")), list(doc.get("balances")), map(doc.get("nonCosBalance")), list(doc.get("localCosts")));
  }

  private static List<String> ids(Object rules) {
    return list(rules).stream().map(r -> str(r.get("CTL_NO"))).toList();
  }

  // --- expected: straight from the model ------------------------------------------------------------

  private List<TableRow> rows(Slot slot, int id) {
    return model.rows(slot, id, model.version(slot, id, round));
  }

  private Map<String, Object> single(Slot slot, int id) {
    List<TableRow> rows = rows(slot, id);
    return rows.isEmpty() ? null : rows.get(0).row();
  }

  private static int index(String id) {
    return Integer.parseInt(id.substring(1));
  }

  private Map<String, Object> expectedItem(int i) {
    Map<String, Object> item = single(Slot.ITEM, i);
    if (item == null) {
      return null;
    }
    int m = index(str(item.get("MFR_CTL_NO")));
    String group = str(item.get("PRODUCT_GROUP_NO"));
    Map<String, Object> profile = single(Slot.MFR, m);
    Map<String, Object> name = profile == null ? null : single(Slot.MFR_NAME, index(str(profile.get("MFR_NAME_ID"))));
    List<Map<String, Object>> mfrRules = rows(Slot.MFR_RULES, m).stream().map(TableRow::row).toList();

    boolean excluded = profile != null && Rows.in(profile, "SELLABLE", config.dcExcludedSellable());
    List<Map<String, Object>> dcBalances = excluded ? List.of() : rows(Slot.BALANCES, i).stream().map(TableRow::row)
        .filter(b -> {
          Map<String, Object> location = single(Slot.LOCATION, Integer.parseInt(str(b.get("MI_LOC"))));
          return Rows.in(location, "LOCATION_TYPE", config.dcLocationTypes()) && Rows.in(location, "OPEN_CLOSED", config.dcLocationStatuses());
        }).toList();

    List<Map<String, Object>> products = new ArrayList<>();
    for (int p : new LinkedHashSet<>(List.of(i, i ^ 1))) {
      if (p < model.items()) {
        List<TableRow> productRows = rows(Slot.PRODUCT, p);
        String bridgeId = config.itemNumberAttribute();
        boolean bridged = productRows.stream().anyMatch(r -> r.table() == SourceTable.STEP_PRODUCT_VALUES
            && bridgeId.equals(r.row().get("STEP_ATTRIBUTE_ID")) && SimModel.itemNo(i).equals(str(r.row().get("VALUE"))));
        if (bridged) {
          products.add(expectedProduct(p, productRows));
        }
      }
    }
    return itemSummary(item, profile, name,
        rows(Slot.ITEM_RULES, i).stream().map(r -> str(r.row().get("CTL_NO"))).toList(),
        mfrRules.stream().filter(r -> Rows.isBlank(r, "PROD_GROUP_NO")).map(r -> str(r.get("CTL_NO"))).toList(),
        mfrRules.stream().filter(r -> group.equals(Rows.str(r, "PROD_GROUP_NO"))).map(r -> str(r.get("CTL_NO"))).toList(),
        dcBalances, rows(Slot.ITEM_COST, i).stream().map(TableRow::row).toList(), products);
  }

  private Map<String, Object> expectedProduct(int p, List<TableRow> rows) {
    Map<String, Object> product = null;
    Map<String, List<Object[]>> attributes = new TreeMap<>();
    List<Object[]> classes = new ArrayList<>();
    for (TableRow row : rows) {
      Map<String, Object> r = row.row();
      switch (row.table()) {
        case STEP_PRODUCT -> product = r;
        case STEP_PRODUCT_VALUES -> config.stepAttributes().forEach((name, id) -> {
          if (id.equals(r.get("STEP_ATTRIBUTE_ID"))) {
            String unitId = Rows.str(r, "STEP_UNIT_ID");
            attributes.computeIfAbsent(name, k -> new ArrayList<>())
                .add(new Object[] {r.get("VALUE"), unitId == null ? null : single(Slot.UNIT, index(unitId))});
          }
        });
        case STEP_PRODUCT_CLASSIFICATION -> classes.add(expectedClass(str(r.get("STEP_CLASSIFICATION_ID"))));
        default -> {}
      }
    }
    return productSummary(SimModel.productId(p), product, attributes, classes);
  }

  private Object[] expectedClass(String classId) {
    List<Map<String, Object>> path = new ArrayList<>();
    String current = classId;
    while (current.matches("C\\d+")) {
      Map<String, Object> row = single(Slot.CLASS, index(current));
      path.add(0, row);
      current = str(row.get("PARENT_STEP_CLASSIFICATION_ID"));
    }
    return new Object[] {classId, model.root().equals(current), path};
  }

  private Map<String, Object> expectedLocations(int i) {
    Map<String, List<Map<String, Object>>> balances = new TreeMap<>();
    Map<String, Map<String, Object>> nonCos = new TreeMap<>();
    Map<String, List<Map<String, Object>>> localCosts = new TreeMap<>();
    rows(Slot.BALANCES, i).forEach(r -> balances.computeIfAbsent(str(r.row().get("MI_LOC")), k -> new ArrayList<>()).add(r.row()));
    rows(Slot.NON_COS, i).forEach(r -> nonCos.put(str(r.row().get("MI_LOC")), r.row()));
    rows(Slot.LOCAL_COSTS, i).forEach(r -> localCosts.computeIfAbsent(str(r.row().get("MI_LOC")), k -> new ArrayList<>()).add(r.row()));
    Set<String> locs = new TreeSet<>(balances.keySet());
    locs.addAll(nonCos.keySet());
    locs.addAll(localCosts.keySet());
    Map<String, Object> out = new TreeMap<>();
    for (String loc : locs) {
      out.put(Keys.of("ITEM_NO", SimModel.itemNo(i), "MI_LOC", loc), locationSummary(single(Slot.LOCATION, Integer.parseInt(loc)),
          balances.getOrDefault(loc, List.of()), nonCos.get(loc), localCosts.getOrDefault(loc, List.of())));
    }
    return out;
  }

  // --- normalization -------------------------------------------------------------------------------

  private static List<String> sorted(List<String> values) {
    List<String> copy = new ArrayList<>(values);
    copy.sort(Comparator.nullsFirst(Comparator.naturalOrder()));
    return copy;
  }

  private static String str(Object value) {
    return value == null ? null : Rows.text(value).trim();
  }

  /** Numbers compare by value whether they arrived as JSON numbers or as Avro strings. */
  private static String num(Object value) {
    String text = str(value);
    try {
      return text == null || text.isEmpty() ? text : Rows.text(new java.math.BigDecimal(text));
    } catch (NumberFormatException e) {
      return text;
    }
  }
}
