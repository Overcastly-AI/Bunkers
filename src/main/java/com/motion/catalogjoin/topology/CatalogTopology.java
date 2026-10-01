package com.motion.catalogjoin.topology;

import static com.motion.catalogjoin.Columns.ITEM_NO;
import static com.motion.catalogjoin.Columns.LOCATION_TYPE;
import static com.motion.catalogjoin.Columns.MFR_CTL_NO;
import static com.motion.catalogjoin.Columns.MFR_NAME_ID;
import static com.motion.catalogjoin.Columns.MI_LOC;
import static com.motion.catalogjoin.Columns.OPEN_CLOSED;
import static com.motion.catalogjoin.Columns.PRODUCT_GROUP_NO;
import static com.motion.catalogjoin.Columns.PROD_GROUP_NO;
import static com.motion.catalogjoin.Columns.STEP_ATTRIBUTE_ID;
import static com.motion.catalogjoin.Columns.STEP_CLASSIFICATION_ID;
import static com.motion.catalogjoin.Columns.STEP_PRODUCT_ID;
import static com.motion.catalogjoin.Columns.STEP_UNIT_ID;
import static com.motion.catalogjoin.Columns.VALUE;
import static com.motion.catalogjoin.SourceTable.ITEM_BALANCE;
import static com.motion.catalogjoin.SourceTable.ITEM_COST;
import static com.motion.catalogjoin.SourceTable.ITEM_PRICE_CACHE;
import static com.motion.catalogjoin.SourceTable.ITEM_PROFILE;
import static com.motion.catalogjoin.SourceTable.ITEM_RESTRICT_RULE;
import static com.motion.catalogjoin.SourceTable.LOCAL_COST;
import static com.motion.catalogjoin.SourceTable.LOCATION_PROFILE;
import static com.motion.catalogjoin.SourceTable.MFR_NAME;
import static com.motion.catalogjoin.SourceTable.MFR_PROFILE;
import static com.motion.catalogjoin.SourceTable.NON_COS_ITEM_BALANCE;
import static com.motion.catalogjoin.SourceTable.STEP_CLASSIFICATION;
import static com.motion.catalogjoin.SourceTable.STEP_PRODUCT;
import static com.motion.catalogjoin.SourceTable.STEP_PRODUCT_CLASSIFICATION;
import static com.motion.catalogjoin.SourceTable.STEP_PRODUCT_VALUES;
import static com.motion.catalogjoin.SourceTable.STEP_UNIT;
import static com.motion.catalogjoin.model.Docs.list;
import static com.motion.catalogjoin.model.Docs.map;
import static com.motion.catalogjoin.model.Docs.values;

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Rows;
import com.motion.catalogjoin.SourceTable;
import com.motion.catalogjoin.ingest.Sources;
import com.motion.catalogjoin.model.Docs;
import com.motion.catalogjoin.model.Group;
import com.motion.catalogjoin.model.ModelSerdes;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;
import java.util.function.BiFunction;
import java.util.function.Function;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Grouped;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Named;
import org.apache.kafka.streams.kstream.Produced;
import org.apache.kafka.streams.kstream.Repartitioned;
import org.apache.kafka.streams.kstream.TableJoined;
import org.apache.kafka.streams.kstream.ValueJoiner;

/**
 * The whole application: every source is either foreign-key joined or re-keyed and aggregated to
 * the output grain, then left-joined onto the root table. Table-table joins recompute when either
 * side changes, so there is no one-sided refresh and no scheduled rebuild.
 *
 * <pre>
 * catalog.output.item           key ITEM_NO           root ITEM_PROFILE
 * catalog.output.item-location  key ITEM_NO + MI_LOC  root ITEM_BALANCE | NON_COS_ITEM_BALANCE | LOCAL_COST
 * catalog.output.item-price     key ITEM_NO + MI_LOC + CUSTOMER_NO   (ITEM_PRICE_CACHE, normalized, 1:1)
 * </pre>
 *
 * Every value is a JSON-shaped map built directly in its published shape (docs/CONTRACTS.md), and
 * every operator, store and internal topic is named so the topology stays compatible across code
 * changes that do not touch it.
 */
public final class CatalogTopology {

  private final StreamsBuilder builder;
  private final CatalogConfig config;
  private final Sources sources;

  private CatalogTopology(StreamsBuilder builder, CatalogConfig config) {
    this.builder = builder;
    this.config = config;
    this.sources = new Sources(builder, config);
  }

  public static Topology build(CatalogConfig config) {
    StreamsBuilder builder = new StreamsBuilder();
    new CatalogTopology(builder, config).define();
    return builder.build();
  }

  private void define() {
    Set<String> attributeIds = Set.copyOf(config.stepAttributes().values());
    config.itemNumberAttribute(); // fail fast when the bridge attribute is not configured
    sources.filterKeys(STEP_PRODUCT_VALUES, key -> attributeIds.contains(key.get(STEP_ATTRIBUTE_ID)));

    defineItem(stepProductsByItem());
    defineItemLocation();
    sources.decoded(ITEM_PRICE_CACHE)
        .to(config.itemPriceTopic(), Produced.with(Serdes.String(), ModelSerdes.DOC).withName("item-price-sink"));
  }

  // --- STEP: products keyed STEP_PRODUCT_ID, bridged to ITEM_NO ----------------------------------

  private KTable<String, Group<Map<String, Object>>> stepProductsByItem() {
    // {value: STEP_PRODUCT_VALUES row, unit: STEP_UNIT row}, grouped by product
    KTable<String, Group<Map<String, Object>>> values = group(
        fkJoin(table(STEP_PRODUCT_VALUES), table(STEP_UNIT), ref(STEP_UNIT_ID), pair("value", "unit"), "step-value-unit"),
        "step-values-by-product", v -> Keys.ref(STEP_PRODUCT_ID, map(v.get("value")).get(STEP_PRODUCT_ID)),
        v -> config.key(STEP_PRODUCT_VALUES, map(v.get("value"))));

    // {link: STEP_PRODUCT_CLASSIFICATION row, classification: path}, grouped by product
    KTable<String, Group<Map<String, Object>>> links = group(
        fkJoin(table(STEP_PRODUCT_CLASSIFICATION), classificationPaths(), ref(STEP_CLASSIFICATION_ID),
            pair("link", "classification"), "step-classification-path"),
        "step-classifications-by-product", l -> Keys.ref(STEP_PRODUCT_ID, map(l.get("link")).get(STEP_PRODUCT_ID)),
        l -> config.key(STEP_PRODUCT_CLASSIFICATION, map(l.get("link"))));

    KTable<String, Map<String, Object>> products = values
        .outerJoin(links, (v, l) -> Docs.of("values", values(v), "links", values(l)), Named.as("step-product-values-classifications"))
        .outerJoin(table(STEP_PRODUCT), (p, row) -> Docs.with(p, "product", row), Named.as("step-product-row"))
        .mapValues(this::stepProduct, Named.as("step-product"), Stores.materialized("step-product", ModelSerdes.DOC));

    return group(products, "step-products-by-item",
        p -> Keys.ref(ITEM_NO, itemNumber(p)), p -> Keys.of(STEP_PRODUCT_ID, p.get("stepProductId")));
  }

  /** The published STEP product: attributes by configured name, classifications with their paths. */
  private Map<String, Object> stepProduct(String key, Map<String, Object> parts) {
    Map<String, List<Map<String, Object>>> attributes = new TreeMap<>();
    for (Map<String, Object> entry : list(parts.get("values"))) {
      Map<String, Object> row = map(entry.get("value"));
      String attributeId = Rows.str(row, STEP_ATTRIBUTE_ID);
      config.stepAttributes().forEach((name, id) -> {
        if (id.equals(attributeId)) {
          attributes.computeIfAbsent(name, k -> new ArrayList<>())
              .add(Docs.of("value", row.get(VALUE), "stepUnitId", Rows.str(row, STEP_UNIT_ID), "unit", entry.get("unit")));
        }
      });
    }
    List<Map<String, Object>> classifications = new ArrayList<>();
    for (Map<String, Object> entry : list(parts.get("links"))) {
      Map<String, Object> link = map(entry.get("link"));
      Map<String, Object> path = map(entry.get("classification"));
      classifications.add(Docs.of(
          "stepClassificationId", Rows.str(link, STEP_CLASSIFICATION_ID),
          "link", link,
          "inWebHierarchy", path != null && Boolean.TRUE.equals(path.get("inWebHierarchy")),
          "path", path == null ? List.of() : path.get("path")));
    }
    return Docs.of(
        "stepProductId", Keys.part(key, STEP_PRODUCT_ID),
        "product", parts.get("product"),
        "attributes", attributes,
        "classifications", classifications);
  }

  /** The item a STEP product bridges to; with several values (briefly, during an edit) the smallest. */
  private static String itemNumber(Map<String, Object> product) {
    return list(map(product.get("attributes")).get(CatalogConfig.ITEM_NUMBER_ATTRIBUTE)).stream()
        .map(attribute -> Rows.str(attribute, "value"))
        .filter(Objects::nonNull)
        .sorted()
        .findFirst()
        .orElse(null);
  }

  /** STEP_CLASSIFICATION -> one partition -> {@link ClassificationPaths} -> table keyed STEP_CLASSIFICATION_ID. */
  private KTable<String, Map<String, Object>> classificationPaths() {
    builder.addStateStore(Stores.keyValueStore(ClassificationPaths.STORE, ModelSerdes.DOC));
    String root = config.classificationRoot();
    return sources.decoded(STEP_CLASSIFICATION)
        .repartition(Repartitioned.<String, Map<String, Object>>as("step-classification-single")
            .withKeySerde(Serdes.String()).withValueSerde(ModelSerdes.DOC).withNumberOfPartitions(1))
        .process(() -> new ClassificationPaths(root), Named.as("classification-paths"), ClassificationPaths.STORE)
        .repartition(Stores.repartitioned("classification-paths", ModelSerdes.DOC, config))
        .toTable(Named.as("classification-path-table"), Stores.materialized("classification-path", ModelSerdes.DOC));
  }

  // --- item: catalog.output.item -------------------------------------------------------------------

  private void defineItem(KTable<String, Group<Map<String, Object>>> stepProducts) {
    KTable<String, Map<String, Object>> items = table(ITEM_PROFILE);
    KTable<String, Map<String, Object>> rules = table(ITEM_RESTRICT_RULE);

    // Manufacturer chain: ITEM_PROFILE.MFR_CTL_NO -> MFR_PROFILE.MFR_NAME_ID -> MFR_NAME.
    KTable<String, Map<String, Object>> manufacturers =
        fkJoin(table(MFR_PROFILE), table(MFR_NAME), ref(MFR_NAME_ID), pair("profile", "name"), "manufacturer-name");

    // DC stock: {balance, location} at open warehouse locations.
    Set<String> types = config.dcLocationTypes();
    Set<String> statuses = config.dcLocationStatuses();
    KTable<String, Group<Map<String, Object>>> dcStock = group(
        fkJoin(table(ITEM_BALANCE), table(LOCATION_PROFILE), ref(MI_LOC), pair("balance", "location"), "balance-location"),
        "dc-stock-by-item",
        b -> {
          Map<String, Object> location = map(b.get("location"));
          boolean open = Rows.in(location, LOCATION_TYPE, types) && Rows.in(location, OPEN_CLOSED, statuses);
          return open ? Keys.ref(ITEM_NO, map(b.get("balance")).get(ITEM_NO)) : null;
        },
        b -> config.key(ITEM_BALANCE, map(b.get("balance"))));

    // Restriction rules: the three branches of the old UNION.
    BiFunction<String, Map<String, Object>, String> productGroup =
        (key, row) -> manufacturerProductGroup(row.get(MFR_CTL_NO), row.get(PRODUCT_GROUP_NO));

    Set<String> unsellable = config.dcExcludedSellable();
    KTable<String, Map<String, Object>> docs = items
        .mapValues((key, row) -> Docs.of("itemNo", Keys.part(key, ITEM_NO), "item", row), Named.as("item-doc"))
        .leftJoin(lookup(items, manufacturers, ref(MFR_CTL_NO), "item-manufacturer", ModelSerdes.DOC),
            attach("manufacturer"), Named.as("item-doc-manufacturer"))
        .leftJoin(groupRows(rules, ITEM_RESTRICT_RULE, "rules-by-item", r -> Keys.ref(ITEM_NO, r.get(ITEM_NO))),
            attachAll("restrictions.item"), Named.as("item-doc-item-rules"))
        .leftJoin(lookup(items, groupRows(rules, ITEM_RESTRICT_RULE, "rules-by-manufacturer",
                r -> Rows.isBlank(r, PROD_GROUP_NO) ? Keys.ref(MFR_CTL_NO, r.get(MFR_CTL_NO)) : null),
            ref(MFR_CTL_NO), "item-manufacturer-rules", ModelSerdes.GROUP),
            attachAll("restrictions.manufacturer"), Named.as("item-doc-manufacturer-rules"))
        .leftJoin(lookup(items, groupRows(rules, ITEM_RESTRICT_RULE, "rules-by-manufacturer-product-group",
                r -> manufacturerProductGroup(r.get(MFR_CTL_NO), r.get(PROD_GROUP_NO))),
            productGroup, "item-product-group-rules", ModelSerdes.GROUP),
            attachAll("restrictions.manufacturerProductGroup"), Named.as("item-doc-product-group-rules"))
        .leftJoin(dcStock, attachAll("dcStock"), Named.as("item-doc-dc-stock"))
        .leftJoin(groupRows(table(ITEM_COST), ITEM_COST, "costs-by-item", r -> Keys.ref(ITEM_NO, r.get(ITEM_NO))),
            attachAll("costs"), Named.as("item-doc-costs"))
        .leftJoin(stepProducts, attachAll("stepProducts"), Named.as("item-doc-step-products"))
        .mapValues(doc -> excludeUnsellableDcStock(doc, unsellable), Named.as("item-doc-sellable"));

    publish(docs, "item", config.itemTopic());
  }

  /** The old dc_stock_summary anti-join: no DC stock for items of an excluded SELLABLE value. */
  private static Map<String, Object> excludeUnsellableDcStock(Map<String, Object> doc, Set<String> unsellable) {
    Map<String, Object> manufacturer = map(doc.get("manufacturer"));
    boolean excluded = manufacturer != null && Rows.in(map(manufacturer.get("profile")), "SELLABLE", unsellable);
    return excluded ? Docs.with(doc, "dcStock", List.of()) : doc;
  }

  private static String manufacturerProductGroup(Object manufacturer, Object productGroup) {
    String mfr = Keys.ref(MFR_CTL_NO, manufacturer);
    String group = Keys.ref(PROD_GROUP_NO, productGroup);
    return mfr == null || group == null ? null : Keys.of(MFR_CTL_NO, manufacturer, PROD_GROUP_NO, productGroup);
  }

  // --- item at location: catalog.output.item-location ----------------------------------------------

  private void defineItemLocation() {
    Function<Map<String, Object>, String> itemLocation = r -> Keys.of(ITEM_NO, r.get(ITEM_NO), MI_LOC, r.get(MI_LOC));
    // NON_COS_ITEM_BALANCE is already keyed (ITEM_NO, MI_LOC): canonical keys sort their columns.
    KTable<String, Map<String, Object>> base =
        groupRows(table(ITEM_BALANCE), ITEM_BALANCE, "balances-by-item-location", itemLocation)
            .outerJoin(table(NON_COS_ITEM_BALANCE), (b, n) -> Docs.of("balances", values(b), "nonCosBalance", n),
                Named.as("item-location-balances-non-cos"))
            .outerJoin(groupRows(table(LOCAL_COST), LOCAL_COST, "local-costs-by-item-location", itemLocation),
                (doc, costs) -> Docs.with(doc == null ? Docs.of("balances", List.of(), "nonCosBalance", null) : doc,
                    "localCosts", values(costs)),
                Named.as("item-location-local-costs"), Stores.materialized("item-location-base", ModelSerdes.DOC));

    KTable<String, Map<String, Object>> docs = base
        .leftJoin(lookup(base, table(LOCATION_PROFILE), (key, doc) -> Keys.ref(MI_LOC, Keys.part(key, MI_LOC)),
            "item-location-location", ModelSerdes.DOC), attach("location"), Named.as("item-location-doc"))
        .mapValues((key, doc) -> Docs.with(Docs.with(doc, "itemNo", Keys.part(key, ITEM_NO)), "miLoc", Keys.part(key, MI_LOC)),
            Named.as("item-location-doc-keys"));

    publish(docs, "item-location", config.itemLocationTopic());
  }

  // --- building blocks -----------------------------------------------------------------------------

  private KTable<String, Map<String, Object>> table(SourceTable table) {
    return sources.table(table);
  }

  /** Foreign key from a single column of the left row. */
  private static BiFunction<String, Map<String, Object>, String> ref(String column) {
    return (key, row) -> Keys.ref(column, row.get(column));
  }

  /** Joins two rows into {@code {leftName: left, rightName: right}}. */
  private static ValueJoiner<Map<String, Object>, Map<String, Object>, Map<String, Object>> pair(String leftName, String rightName) {
    return (left, right) -> Docs.of(leftName, left, rightName, right);
  }

  /** Sets {@code path} on the document to the right-side value (null when there is none). */
  private static ValueJoiner<Map<String, Object>, Map<String, Object>, Map<String, Object>> attach(String path) {
    return (doc, value) -> Docs.with(doc, path, value);
  }

  /** Sets {@code path} on the document to the aggregate's rows, in id order ([] when there are none). */
  private static ValueJoiner<Map<String, Object>, Group<Map<String, Object>>, Map<String, Object>> attachAll(String path) {
    return (doc, group) -> Docs.with(doc, path, values(group));
  }

  /** Foreign-key left join; the result is materialized under {@code name}. */
  private <V, R> KTable<String, Map<String, Object>> fkJoin(KTable<String, Map<String, Object>> left, KTable<String, V> right,
      BiFunction<String, Map<String, Object>, String> foreignKey, ValueJoiner<Map<String, Object>, V, Map<String, Object>> joiner,
      String name) {
    return left.leftJoin(right, foreignKey, joiner, TableJoined.as(name), Stores.materialized(name, ModelSerdes.DOC));
  }

  /**
   * The right-side value each left row points at, keyed like the left table (deleted when there is
   * no match). Joining that narrow table back by primary key keeps the wide document out of the
   * foreign-key round trip.
   */
  private <V> KTable<String, V> lookup(KTable<String, Map<String, Object>> left, KTable<String, V> right,
      BiFunction<String, Map<String, Object>, String> foreignKey, String name, Serde<V> values) {
    return left.leftJoin(right, foreignKey, (row, value) -> value, TableJoined.as(name), Stores.materialized(name, values));
  }

  /** {@link #group} for source rows, identified by their table's key. */
  private KTable<String, Group<Map<String, Object>>> groupRows(KTable<String, Map<String, Object>> rows, SourceTable table,
      String name, Function<Map<String, Object>, String> groupKey) {
    return group(rows, name, groupKey, r -> config.key(table, r));
  }

  /**
   * Re-key a table to {@code groupKey} and collect its values per key, by {@code entryId}. Rows
   * whose group key is null are left out; a key whose last row goes away is deleted.
   */
  private KTable<String, Group<Map<String, Object>>> group(KTable<String, Map<String, Object>> table, String name,
      Function<Map<String, Object>, String> groupKey, Function<Map<String, Object>, String> entryId) {
    return table
        .filter((key, value) -> groupKey.apply(value) != null, Named.as(name + "-has-key"))
        .groupBy((key, value) -> KeyValue.pair(groupKey.apply(value), value), Grouped.with(name, Serdes.String(), ModelSerdes.DOC))
        .aggregate(
            Group::empty,
            (key, value, agg) -> agg.with(entryId.apply(value), value),
            // Returning null deletes the aggregate (and forwards a delete) once the last row is gone.
            (key, value, agg) -> Group.nullIfEmpty(agg.without(entryId.apply(value))),
            Named.as(name + "-aggregate"),
            Stores.materialized(name, ModelSerdes.GROUP));
  }

  private void publish(KTable<String, Map<String, Object>> docs, String name, String topic) {
    String store = name + "-published";
    builder.addStateStore(Stores.keyValueStore(store, Serdes.ByteArray()));
    docs.toStream(Named.as(name + "-doc-changes"))
        .processValues(() -> new EmitOnChange<Map<String, Object>>(store), Named.as(name + "-emit-on-change"), store)
        .to(topic, Produced.with(Serdes.String(), Serdes.ByteArray()).withName(name + "-sink"));
  }
}
