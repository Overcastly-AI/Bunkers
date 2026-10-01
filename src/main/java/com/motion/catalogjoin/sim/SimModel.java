package com.motion.catalogjoin.sim;

import static com.motion.catalogjoin.sim.Mix.frac;
import static com.motion.catalogjoin.sim.Mix.mod;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.SourceTable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

/**
 * A synthetic catalog whose entire history is a pure function of (seed, scale, round).
 *
 * <p>Data is organized in <em>slots</em>: a unit that changes together (an item's profile, all
 * balance rows of an item, a STEP product with its values and classification links, ...). A slot
 * has a version that goes up by one in each churn round in which it changes; its rows are a
 * function of (slot, id, version). The generator emits the difference between consecutive versions
 * (upserts and deletes, including delete-old-key + insert-new-key edits), and the verifier
 * recomputes the final version of any slot without replaying anything.
 */
public final class SimModel {

  public enum Slot {
    ITEM(0.02),
    MFR(0.02),
    MFR_NAME(0.05),
    LOCATION(0.05),
    BALANCES(0.10),
    ITEM_COST(0.03),
    NON_COS(0.03),
    LOCAL_COSTS(0.03),
    ITEM_RULES(0.05),
    MFR_RULES(0.05),
    UNIT(0.20),
    PRODUCT(0.05),
    CLASS(0.02),
    PRICES(0.05);

    final double churn;

    Slot(double churn) {
      this.churn = churn;
    }
  }

  /** One source row. */
  public record TableRow(SourceTable table, Map<String, Object> row) {}

  /** Attributes the app does not project; the generator sends them anyway to exercise the filter. */
  static final int UNCONFIGURED_ATTRIBUTES = 10;

  static final int GROUPS = 20;
  static final int UNITS = 20;
  static final int L1 = 20;
  static final int L2 = 200;
  static final int L3 = 2000;
  static final int CLASSES = L1 + L2 + L3;

  // Hash purposes.
  private static final long CHURN = 1, ITEM_DEL = 2, ITEM_MFR = 3, ITEM_MFR_CH = 4, ITEM_MFR2 = 5, ITEM_GRP = 6,
      ITEM_GRP_CH = 7, ITEM_GRP2 = 8, PRICE = 9, MFR_DEL = 10, MFR_NAME_CH = 11, MFR_NAME2 = 12, SELL = 13,
      LOC_CLOSED = 14, POPULAR = 15, BAL_K = 16, BAL_LOC = 17, STORE = 18, BAL_DEL = 19, QTY = 20, COST_DEL = 21,
      COST = 22, NC = 23, NC_DEL = 24, NC_QTY = 25, LC = 26, LC_N = 27, LC_COST = 28, RI = 29, RI_DEL = 30, RM = 31,
      RM_DEL = 32, RG = 33, RG_DEL = 34, PX = 35, P_DEL = 36, BRIDGE = 37, UPC = 38, WEIGHT = 39, WEIGHT_UNIT = 40,
      LINK_N = 41, LINK_CH = 42, LINK = 43, CLASS_CH = 44, CLASS_PARENT = 45, PR = 46, CUST = 47, PR_DEL = 48,
      PR_VAL = 49, SAMPLE = 50;

  private final long seed;
  private final int items;
  private final int mfrs;
  private final int locations;
  private final int warehouses;
  private final int pricesPerItem;
  // Codes and ids come from the app's configuration, so the simulation always matches it.
  private final Map<String, String> attributes;
  private final String root;
  private final String otherRoot;
  private final String warehouseType;
  private final String branchType;
  private final String open;
  private final String closed;
  private final String unsellable;

  public SimModel(CatalogConfig config) {
    CatalogConfig.Sim sim = config.sim();
    if (sim.items() < 2) {
      throw new IllegalArgumentException("sim.items must be >= 2");
    }
    this.seed = sim.seed();
    this.items = sim.items();
    this.mfrs = Math.max(20, items / 200);
    this.locations = Math.max(10, sim.locations());
    this.warehouses = Math.max(1, this.locations / 15);
    this.pricesPerItem = sim.pricesPerItem();
    this.attributes = new TreeMap<>(config.stepAttributes());
    config.itemNumberAttribute();
    this.root = config.classificationRoot();
    this.otherRoot = root + "-OTHER";
    this.warehouseType = first(config.dcLocationTypes());
    this.branchType = outside(config.dcLocationTypes());
    this.open = first(config.dcLocationStatuses());
    this.closed = outside(config.dcLocationStatuses());
    this.unsellable = config.dcExcludedSellable().isEmpty() ? "N" : first(config.dcExcludedSellable());
  }

  private static String first(Set<String> codes) {
    return new TreeSet<>(codes).first();
  }

  /** A code that is not in the set. */
  private static String outside(Set<String> codes) {
    String code = "X";
    while (codes.contains(code)) {
      code += "X";
    }
    return code;
  }

  public int items() {
    return items;
  }

  String root() {
    return root;
  }

  public int count(Slot slot) {
    return switch (slot) {
      case ITEM, BALANCES, ITEM_COST, NON_COS, LOCAL_COSTS, ITEM_RULES, PRODUCT, PRICES -> items;
      case MFR, MFR_NAME, MFR_RULES -> mfrs;
      case LOCATION -> locations;
      case UNIT -> UNITS;
      case CLASS -> CLASSES;
    };
  }

  /** Did the slot change in this round (round >= 1)? */
  public boolean changes(Slot slot, int id, int round) {
    return round > 0 && frac(h(CHURN, slot.ordinal(), id, round)) < slot.churn;
  }

  public int version(Slot slot, int id, int round) {
    int version = 0;
    for (int r = 1; r <= round; r++) {
      if (changes(slot, id, r)) {
        version++;
      }
    }
    return version;
  }

  public boolean sampled(int item, int every) {
    return every <= 1 || mod(h(SAMPLE, item), every) == 0;
  }

  // --- identifiers -----------------------------------------------------------------------------

  public static String itemNo(int i) {
    return String.format("%08d", i);
  }

  static String mfrNo(int m) {
    return "M" + m;
  }

  static String nameId(int n) {
    return "N" + n;
  }

  static String loc(int l) {
    return String.format("%04d", l);
  }

  static String storeroom(int s) {
    return String.format("%02d", s);
  }

  static String unit(int u) {
    return "U" + u;
  }

  static String group(int g) {
    return "G" + g;
  }

  static String productId(int p) {
    return "P" + p;
  }

  static String classId(int c) {
    return "C" + c;
  }

  // --- rows ------------------------------------------------------------------------------------

  public List<TableRow> rows(Slot slot, int id, int version) {
    return switch (slot) {
      case ITEM -> item(id, version);
      case MFR -> manufacturer(id, version);
      case MFR_NAME -> manufacturerName(id, version);
      case LOCATION -> location(id, version);
      case BALANCES -> balances(id, version);
      case ITEM_COST -> itemCost(id, version);
      case NON_COS -> nonCos(id, version);
      case LOCAL_COSTS -> localCosts(id, version);
      case ITEM_RULES -> itemRules(id, version);
      case MFR_RULES -> manufacturerRules(id, version);
      case UNIT -> unitRow(id, version);
      case PRODUCT -> product(id, version);
      case CLASS -> classification(id, version);
      case PRICES -> prices(id, version);
    };
  }

  private List<TableRow> item(int i, int v) {
    if (v > 0 && frac(h(ITEM_DEL, i, v)) < 0.05) {
      return List.of();
    }
    int m = v > 0 && frac(h(ITEM_MFR_CH, i, v)) < 0.2 ? mod(h(ITEM_MFR2, i, v), mfrs) : mod(h(ITEM_MFR, i), mfrs);
    int g = v > 0 && frac(h(ITEM_GRP_CH, i, v)) < 0.2 ? mod(h(ITEM_GRP2, i, v), GROUPS) : mod(h(ITEM_GRP, i), GROUPS);
    return one(SourceTable.ITEM_PROFILE, row(
        "ITEM_NO", itemNo(i),
        "MFR_CTL_NO", mfrNo(m),
        "PRODUCT_GROUP_NO", group(g),
        "GROUP_SERIAL", (long) (i % 1000),
        "DESCR", "Item " + i + " rev " + v,
        "LIST_PRICE", money(h(PRICE, i, v))));
  }

  private List<TableRow> manufacturer(int m, int v) {
    if (v > 0 && frac(h(MFR_DEL, m, v)) < 0.02) {
      return List.of();
    }
    int n = v > 0 && frac(h(MFR_NAME_CH, m, v)) < 0.1 ? mod(h(MFR_NAME2, m, v), mfrs) : m;
    return one(SourceTable.MFR_PROFILE, row(
        "MFR_CTL_NO", mfrNo(m),
        "MFR_NAME_ID", nameId(n),
        "SELLABLE", frac(h(SELL, m, v)) < 0.9 ? "Y" : unsellable));
  }

  private List<TableRow> manufacturerName(int n, int v) {
    return one(SourceTable.MFR_NAME, row("MFR_NAME_ID", nameId(n), "MFR_NAME", "Maker " + n + " rev " + v));
  }

  private List<TableRow> location(int l, int v) {
    return one(SourceTable.LOCATION_PROFILE, row(
        "MI_LOC", loc(l),
        "LOCATION_TYPE", l < warehouses ? warehouseType : branchType,
        "OPEN_CLOSED", v > 0 && frac(h(LOC_CLOSED, l, v)) < 0.25 ? closed : open,
        "LOCATION_NAME", "Location " + l));
  }

  /** Locations where the item has balances (stable; about 3.5 on average, 50 for 1% of items). */
  int[] balanceLocations(int i) {
    int k = frac(h(POPULAR, i)) < 0.01 ? 50 : 1 + mod(h(BAL_K, i), 6);
    Set<Integer> chosen = new LinkedHashSet<>();
    for (int j = 0; chosen.size() < k && j < k * 3; j++) {
      chosen.add(mod(h(BAL_LOC, i, j), locations));
    }
    return chosen.stream().mapToInt(Integer::intValue).toArray();
  }

  private int storerooms(int i, int l) {
    return mod(h(STORE, i, l), 3) == 0 ? 2 : 1;
  }

  private List<TableRow> balances(int i, int v) {
    List<TableRow> out = new ArrayList<>();
    for (int l : balanceLocations(i)) {
      for (int s = 1; s <= storerooms(i, l); s++) {
        if (v > 0 && frac(h(BAL_DEL, i, l, s, v)) < 0.05) {
          continue;
        }
        out.add(new TableRow(SourceTable.ITEM_BALANCE, row(
            "ITEM_NO", itemNo(i),
            "MI_LOC", loc(l),
            "STOREROOM_NO", storeroom(s),
            "QTY_ON_HAND", (long) mod(h(QTY, i, l, s, v), 500))));
      }
    }
    return out;
  }

  private List<TableRow> itemCost(int i, int v) {
    if (v > 0 && frac(h(COST_DEL, i, v)) < 0.02) {
      return List.of();
    }
    return one(SourceTable.ITEM_COST, row(
        "ITEM_NO", itemNo(i), "CORP_MI_LOC", "0001", "COST", money(h(COST, i, v))));
  }

  private List<TableRow> nonCos(int i, int v) {
    if (frac(h(NC, i)) >= 0.1 || (v > 0 && frac(h(NC_DEL, i, v)) < 0.1)) {
      return List.of();
    }
    return one(SourceTable.NON_COS_ITEM_BALANCE, row(
        "MI_LOC", loc(balanceLocations(i)[0]), "ITEM_NO", itemNo(i), "QTY", (long) mod(h(NC_QTY, i, v), 100)));
  }

  private List<TableRow> localCosts(int i, int v) {
    if (frac(h(LC, i)) >= 0.2) {
      return List.of();
    }
    int[] locs = balanceLocations(i);
    int n = Math.min(locs.length, 1 + mod(h(LC_N, i), 2));
    List<TableRow> out = new ArrayList<>();
    for (int j = 0; j < n; j++) {
      // The dates are part of the key, so a new version is a delete of the old key plus an insert.
      LocalDate effective = LocalDate.of(2026, 1, 1).plusDays(v * 7L + j);
      out.add(new TableRow(SourceTable.LOCAL_COST, row(
          "MI_LOC", loc(locs[j]),
          "ITEM_NO", itemNo(i),
          "EFFECTIVE_DATE", effective.toString(),
          "EXPIRATION_DATE", effective.plusDays(365).toString(),
          "COST", money(h(LC_COST, i, j, v)))));
    }
    return out;
  }

  private List<TableRow> itemRules(int i, int v) {
    if (frac(h(RI, i)) >= 0.02 || (v > 0 && frac(h(RI_DEL, i, v)) < 0.2)) {
      return List.of();
    }
    return one(SourceTable.ITEM_RESTRICT_RULE, row(
        "CTL_NO", "RI" + i, "ITEM_NO", itemNo(i), "MFR_CTL_NO", " ", "PROD_GROUP_NO", " ", "RESTRICT_CODE", "X" + v));
  }

  private List<TableRow> manufacturerRules(int m, int v) {
    List<TableRow> out = new ArrayList<>();
    if (frac(h(RM, m)) < 0.1 && !(v > 0 && frac(h(RM_DEL, m, v)) < 0.2)) {
      out.add(new TableRow(SourceTable.ITEM_RESTRICT_RULE, row(
          "CTL_NO", "RM" + m, "ITEM_NO", " ", "MFR_CTL_NO", mfrNo(m), "PROD_GROUP_NO", " ", "RESTRICT_CODE", "M" + v)));
    }
    for (int g = 0; g < GROUPS; g++) {
      if (frac(h(RG, m, g)) < 0.1 && !(v > 0 && frac(h(RG_DEL, m, g, v)) < 0.2)) {
        out.add(new TableRow(SourceTable.ITEM_RESTRICT_RULE, row(
            "CTL_NO", "RG" + m + "_" + g, "ITEM_NO", " ", "MFR_CTL_NO", mfrNo(m), "PROD_GROUP_NO", group(g),
            "RESTRICT_CODE", "G" + v)));
      }
    }
    return out;
  }

  private List<TableRow> unitRow(int u, int v) {
    return one(SourceTable.STEP_UNIT, row("STEP_UNIT_ID", unit(u), "UNIT_NAME", "unit " + u + " rev " + v));
  }

  /** The item a STEP product bridges to at a version: itself, or occasionally its neighbour. */
  int bridgeTarget(int p, int v) {
    int neighbour = p ^ 1;
    return v > 0 && neighbour < items && frac(h(BRIDGE, p, v)) < 0.1 ? neighbour : p;
  }

  private List<TableRow> product(int p, int v) {
    if (frac(h(PX, p)) >= 0.9 || (v > 0 && frac(h(P_DEL, p, v)) < 0.02)) {
      return List.of();
    }
    String id = productId(p);
    List<TableRow> out = new ArrayList<>();
    out.add(new TableRow(SourceTable.STEP_PRODUCT, row("STEP_PRODUCT_ID", id, "PRODUCT_NAME", "Product " + p + " rev " + v)));
    int a = 0;
    for (Map.Entry<String, String> attribute : attributes.entrySet()) {
      a++;
      boolean bridge = attribute.getKey().equals(CatalogConfig.ITEM_NUMBER_ATTRIBUTE);
      String value = bridge ? itemNo(bridgeTarget(p, v)) : attribute.getKey() + " " + p + " rev " + v;
      // Every attribute but the bridge carries a unit, so unit changes reach every attribute.
      String unit = bridge ? " " : unit(mod(h(WEIGHT_UNIT, p, a, v), UNITS));
      out.add(value(id, attribute.getValue(), unit, value));
    }
    for (int x = 1; x <= UNCONFIGURED_ATTRIBUTES; x++) {
      String attributeId = String.format("SIM_X%02d", x);
      if (!attributes.containsValue(attributeId)) {
        out.add(value(id, attributeId, " ", "x" + x + "-" + p + "-" + v));
      }
    }
    int linkVersion = 0;
    for (int k = 1; k <= v; k++) {
      if (frac(h(LINK_CH, p, k)) < 0.2) {
        linkVersion = k;
      }
    }
    Set<Integer> classes = new LinkedHashSet<>();
    int links = 1 + mod(h(LINK_N, p), 2);
    for (int j = 0; j < links; j++) {
      classes.add(L1 + L2 + mod(h(LINK, p, j, linkVersion), L3));
    }
    for (int c : classes) {
      out.add(new TableRow(SourceTable.STEP_PRODUCT_CLASSIFICATION, row(
          "STEP_PRODUCT_ID", id, "STEP_CLASSIFICATION_ID", classId(c), "LINK_TYPE", "primary")));
    }
    return out;
  }

  private static TableRow value(String product, String attribute, String unit, String value) {
    return new TableRow(SourceTable.STEP_PRODUCT_VALUES, row(
        "STEP_PRODUCT_ID", product, "STEP_ATTRIBUTE_ID", attribute, "STEP_UNIT_ID", unit, "VALUE", value));
  }

  private List<TableRow> classification(int c, int v) {
    String parent;
    if (c < L1) {
      parent = root;
    } else if (c < L1 + L2) {
      parent = classId((c - L1) / 10);
      if (v > 0 && frac(h(CLASS_CH, c, v)) < 0.3) {
        int alt = mod(h(CLASS_PARENT, c, v), L1 + 1);
        parent = alt == L1 ? otherRoot : classId(alt);
      }
    } else {
      parent = classId(L1 + (c - L1 - L2) / 10);
    }
    return one(SourceTable.STEP_CLASSIFICATION, row(
        "STEP_CLASSIFICATION_ID", classId(c),
        "PARENT_STEP_CLASSIFICATION_ID", parent,
        "CLASSIFICATION_NAME", "Class " + c + " rev " + v));
  }

  private List<TableRow> prices(int i, int v) {
    if (frac(h(PR, i)) >= 0.5) {
      return List.of();
    }
    String miLoc = loc(balanceLocations(i)[0]);
    Set<String> customers = new LinkedHashSet<>();
    List<TableRow> out = new ArrayList<>();
    for (int k = 0; k < pricesPerItem; k++) {
      String customer = "C" + mod(h(CUST, i, k), 100_000);
      if (!customers.add(customer) || (v > 0 && frac(h(PR_DEL, i, k, v)) < 0.05)) {
        continue;
      }
      out.add(new TableRow(SourceTable.ITEM_PRICE_CACHE, row(
          "ITEM_NO", itemNo(i), "MI_LOC", miLoc, "CUSTOMER_NO", customer, "PRICE", money(h(PR_VAL, i, k, v)))));
    }
    return out;
  }

  // --- helpers ---------------------------------------------------------------------------------

  private long h(long purpose, long... ids) {
    long[] parts = new long[ids.length + 1];
    parts[0] = purpose;
    System.arraycopy(ids, 0, parts, 1, ids.length);
    return Mix.hash(seed, parts);
  }

  private static BigDecimal money(long h) {
    return BigDecimal.valueOf(Math.floorMod(h, 1_000_000L), 2);
  }

  private static List<TableRow> one(SourceTable table, Map<String, Object> row) {
    return List.of(new TableRow(table, row));
  }

  static Map<String, Object> row(Object... keyValues) {
    Map<String, Object> row = new LinkedHashMap<>();
    for (int i = 0; i < keyValues.length; i += 2) {
      row.put((String) keyValues[i], keyValues[i + 1]);
    }
    return row;
  }
}
