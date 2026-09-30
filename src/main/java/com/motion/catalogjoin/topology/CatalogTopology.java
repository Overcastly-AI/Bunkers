package com.motion.catalogjoin.topology;

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

import com.motion.catalogjoin.CatalogConfig;
import com.motion.catalogjoin.Keys;
import com.motion.catalogjoin.Rows;
import com.motion.catalogjoin.ingest.Sources;
import com.motion.catalogjoin.model.ClassPath;
import com.motion.catalogjoin.model.Group;
import com.motion.catalogjoin.model.ItemDoc;
import com.motion.catalogjoin.model.ItemLocationDoc;
import com.motion.catalogjoin.model.LocatedBalance;
import com.motion.catalogjoin.model.Manufacturer;
import com.motion.catalogjoin.model.ModelSerdes;
import com.motion.catalogjoin.model.StepClassification;
import com.motion.catalogjoin.model.StepProduct;
import com.motion.catalogjoin.model.StepValue;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Grouped;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.streams.kstream.Named;
import org.apache.kafka.streams.kstream.Produced;
import org.apache.kafka.streams.kstream.Repartitioned;
import org.apache.kafka.streams.kstream.TableJoined;
import org.apache.kafka.streams.state.KeyValueStore;
import org.apache.kafka.streams.state.Stores;

/**
 * The whole application: every source is either foreign-key joined or re-keyed and aggregated to
 * the output grain, then left-joined onto the root table. Table-table joins recompute when either
 * side changes, so there is no one-sided refresh and no scheduled rebuild.
 *
 * <pre>
 * catalog.item           key ITEM_NO           root ITEM_PROFILE
 * catalog.item-location  key ITEM_NO + MI_LOC  root ITEM_BALANCE | NON_COS_ITEM_BALANCE | LOCAL_COST
 * catalog.item-price     key ITEM_NO + MI_LOC + CUSTOMER_NO   (ITEM_PRICE_CACHE, normalized)
 * </pre>
 *
 * Every operator, store and internal topic is named so the topology stays compatible across code
 * changes that do not touch it.
 */
public final class CatalogTopology {

  private static final String ITEM_NO = "ITEM_NO";
  private static final String MI_LOC = "MI_LOC";
  private static final String MFR_CTL_NO = "MFR_CTL_NO";
  private static final String STEP_PRODUCT_ID = "STEP_PRODUCT_ID";

  private final StreamsBuilder builder;
  private final CatalogConfig config;
  private final Sources sources;
  private final Views views;

  private CatalogTopology(StreamsBuilder builder, CatalogConfig config) {
    this.builder = builder;
    this.config = config;
    this.sources = new Sources(builder, config);
    this.views = new Views(config.stepAttributes());
  }

  public static Topology build(CatalogConfig config) {
    StreamsBuilder builder = new StreamsBuilder();
    new CatalogTopology(builder, config).define();
    return builder.build();
  }

  private void define() {
    Set<String> attributeIds = Set.copyOf(config.stepAttributes().values());
    sources.filterKeys(STEP_PRODUCT_VALUES, key -> attributeIds.contains(key.get("STEP_ATTRIBUTE_ID")));

    KTable<String, Group<StepProduct>> stepProductsByItem = stepProductsByItem();
    defineItem(stepProductsByItem);
    defineItemLocation();
    definePrice();
  }

  // --- STEP: products keyed STEP_PRODUCT_ID, bridged to ITEM_NO ---------------------------------

  private KTable<String, Group<StepProduct>> stepProductsByItem() {
    KTable<String, StepValue> values =
        sources
            .table(STEP_PRODUCT_VALUES)
            .leftJoin(
                sources.table(STEP_UNIT),
                (key, row) -> Keys.ref("STEP_UNIT_ID", row.get("STEP_UNIT_ID")),
                StepValue::new,
                TableJoined.as("step-value-unit"),
                store("step-value-unit", ModelSerdes.STEP_VALUE));

    KTable<String, Group<StepValue>> valuesByProduct =
        group(
            values,
            "step-values-by-product",
            v -> Keys.ref(STEP_PRODUCT_ID, v.value().get(STEP_PRODUCT_ID)),
            v -> Keys.of(v.value(), STEP_PRODUCT_VALUES.keyColumns()),
            ModelSerdes.STEP_VALUE,
            ModelSerdes.STEP_VALUES);

    KTable<String, StepClassification> links =
        sources
            .table(STEP_PRODUCT_CLASSIFICATION)
            .leftJoin(
                classificationPaths(),
                (key, row) -> Keys.ref(ClassificationPaths.ID, row.get(ClassificationPaths.ID)),
                StepClassification::new,
                TableJoined.as("step-classification-path"),
                store("step-classification-path", ModelSerdes.STEP_CLASSIFICATION));

    KTable<String, Group<StepClassification>> linksByProduct =
        group(
            links,
            "step-classifications-by-product",
            l -> Keys.ref(STEP_PRODUCT_ID, l.link().get(STEP_PRODUCT_ID)),
            l -> Keys.of(l.link(), STEP_PRODUCT_CLASSIFICATION.keyColumns()),
            ModelSerdes.STEP_CLASSIFICATION,
            ModelSerdes.STEP_CLASSIFICATIONS);

    KTable<String, StepProduct> products =
        valuesByProduct
            .outerJoin(
                linksByProduct,
                (v, c) -> new StepProduct(null, null, v, c),
                Named.as("step-product-values-classifications"))
            .outerJoin(
                sources.table(STEP_PRODUCT),
                (p, row) ->
                    p == null
                        ? new StepProduct(null, row, null, null)
                        : new StepProduct(null, row, p.values(), p.classifications()),
                Named.as("step-product-row"))
            .mapValues(
                (key, p) ->
                    new StepProduct(
                        Keys.parse(key).get(STEP_PRODUCT_ID), p.product(), p.values(), p.classifications()),
                Named.as("step-product"),
                store("step-product", ModelSerdes.STEP_PRODUCT));

    String itemNumberAttribute = config.stepAttributes().get(CatalogConfig.ITEM_NUMBER_ATTRIBUTE);
    return group(
        products,
        "step-products-by-item",
        p -> Keys.ref(ITEM_NO, p.itemNumber(itemNumberAttribute)),
        p -> Keys.of(STEP_PRODUCT_ID, p.stepProductId()),
        ModelSerdes.STEP_PRODUCT,
        ModelSerdes.STEP_PRODUCTS);
  }

  /**
   * STEP_CLASSIFICATION -> one partition -> {@link ClassificationPaths} -> table of paths keyed by
   * STEP_CLASSIFICATION_ID. The hierarchy is small, so a single task holding it is fine.
   */
  private KTable<String, ClassPath> classificationPaths() {
    builder.addStateStore(
        Stores.keyValueStoreBuilder(
            Stores.persistentKeyValueStore(ClassificationPaths.STORE), Serdes.String(), ModelSerdes.ROW));
    Repartitioned<String, ClassPath> byId =
        Repartitioned.<String, ClassPath>as("classification-paths")
            .withKeySerde(Serdes.String())
            .withValueSerde(ModelSerdes.CLASS_PATH);
    if (config.partitions() != null) {
      byId = byId.withNumberOfPartitions(config.partitions());
    }
    String root = config.classificationRoot();
    return sources
        .decoded(STEP_CLASSIFICATION)
        .repartition(
            Repartitioned.<String, Map<String, Object>>as("step-classification-single")
                .withKeySerde(Serdes.String())
                .withValueSerde(ModelSerdes.ROW)
                .withNumberOfPartitions(1))
        .process(() -> new ClassificationPaths(root), Named.as("classification-paths"), ClassificationPaths.STORE)
        .repartition(byId)
        .toTable(Named.as("classification-path-table"), store("classification-path", ModelSerdes.CLASS_PATH));
  }

  // --- catalog.item ------------------------------------------------------------------------------

  private void defineItem(KTable<String, Group<StepProduct>> stepProductsByItem) {
    KTable<String, Map<String, Object>> items = sources.table(ITEM_PROFILE);
    KTable<String, Map<String, Object>> locations = sources.table(LOCATION_PROFILE);

    // Manufacturer chain: ITEM_PROFILE.MFR_CTL_NO -> MFR_PROFILE.MFR_NAME_ID -> MFR_NAME.
    KTable<String, Manufacturer> manufacturers =
        sources
            .table(MFR_PROFILE)
            .leftJoin(
                sources.table(MFR_NAME),
                (key, row) -> Keys.ref("MFR_NAME_ID", row.get("MFR_NAME_ID")),
                Manufacturer::new,
                TableJoined.as("manufacturer-name"),
                store("manufacturer", ModelSerdes.MANUFACTURER));
    KTable<String, Manufacturer> itemManufacturer =
        items.leftJoin(
            manufacturers,
            (key, row) -> Keys.ref(MFR_CTL_NO, row.get(MFR_CTL_NO)),
            (row, manufacturer) -> manufacturer,
            TableJoined.as("item-manufacturer"),
            store("item-manufacturer", ModelSerdes.MANUFACTURER));

    // Restriction rules: the three branches of the old UNION.
    KTable<String, Map<String, Object>> rules = sources.table(ITEM_RESTRICT_RULE);
    Function<Map<String, Object>, String> ruleId = r -> Keys.of(r, ITEM_RESTRICT_RULE.keyColumns());
    KTable<String, Group<Map<String, Object>>> itemRules =
        group(rules, "rules-by-item", r -> Keys.ref(ITEM_NO, r.get(ITEM_NO)), ruleId, ModelSerdes.ROW, ModelSerdes.ROWS);
    KTable<String, Group<Map<String, Object>>> manufacturerRules =
        group(
            rules,
            "rules-by-manufacturer",
            r -> Rows.isBlank(r, "PROD_GROUP_NO") ? Keys.ref(MFR_CTL_NO, r.get(MFR_CTL_NO)) : null,
            ruleId,
            ModelSerdes.ROW,
            ModelSerdes.ROWS);
    KTable<String, Group<Map<String, Object>>> productGroupRules =
        group(
            rules,
            "rules-by-manufacturer-product-group",
            r -> manufacturerProductGroup(Rows.str(r, MFR_CTL_NO), Rows.str(r, "PROD_GROUP_NO")),
            ruleId,
            ModelSerdes.ROW,
            ModelSerdes.ROWS);
    KTable<String, Group<Map<String, Object>>> itemManufacturerRules =
        items.leftJoin(
            manufacturerRules,
            (key, row) -> Keys.ref(MFR_CTL_NO, row.get(MFR_CTL_NO)),
            (row, group) -> group,
            TableJoined.as("item-manufacturer-rules"),
            store("item-manufacturer-rules", ModelSerdes.ROWS));
    KTable<String, Group<Map<String, Object>>> itemProductGroupRules =
        items.leftJoin(
            productGroupRules,
            (key, row) -> manufacturerProductGroup(Rows.str(row, MFR_CTL_NO), Rows.str(row, "PRODUCT_GROUP_NO")),
            (row, group) -> group,
            TableJoined.as("item-product-group-rules"),
            store("item-product-group-rules", ModelSerdes.ROWS));

    // DC stock: balances at open warehouse locations.
    KTable<String, LocatedBalance> balances =
        sources
            .table(ITEM_BALANCE)
            .leftJoin(
                locations,
                (key, row) -> Keys.ref(MI_LOC, row.get(MI_LOC)),
                LocatedBalance::new,
                TableJoined.as("balance-location"),
                store("balance-location", ModelSerdes.LOCATED_BALANCE));
    KTable<String, Group<LocatedBalance>> dcStock =
        group(
            balances,
            "dc-stock-by-item",
            b -> isOpenWarehouse(b.location()) ? Keys.ref(ITEM_NO, b.balance().get(ITEM_NO)) : null,
            b -> Keys.of(b.balance(), ITEM_BALANCE.keyColumns()),
            ModelSerdes.LOCATED_BALANCE,
            ModelSerdes.LOCATED_BALANCES);

    KTable<String, Group<Map<String, Object>>> costs =
        group(
            sources.table(ITEM_COST),
            "costs-by-item",
            r -> Keys.ref(ITEM_NO, r.get(ITEM_NO)),
            r -> Keys.of(r, ITEM_COST.keyColumns()),
            ModelSerdes.ROW,
            ModelSerdes.ROWS);

    KTable<String, ItemDoc> docs =
        items
            .mapValues(ItemDoc::of, Named.as("item-doc"))
            .leftJoin(itemManufacturer, ItemDoc::withManufacturer, Named.as("item-doc-manufacturer"))
            .leftJoin(itemRules, ItemDoc::withItemRules, Named.as("item-doc-item-rules"))
            .leftJoin(itemManufacturerRules, ItemDoc::withManufacturerRules, Named.as("item-doc-manufacturer-rules"))
            .leftJoin(itemProductGroupRules, ItemDoc::withProductGroupRules, Named.as("item-doc-product-group-rules"))
            .leftJoin(dcStock, ItemDoc::withDcStock, Named.as("item-doc-dc-stock"))
            .leftJoin(costs, ItemDoc::withCosts, Named.as("item-doc-costs"))
            .leftJoin(stepProductsByItem, ItemDoc::withStepProducts, Named.as("item-doc-step-products"));

    publish(
        docs.toStream(Named.as("item-doc-changes"))
            .mapValues((key, doc) -> doc == null ? null : views.item(key, doc), Named.as("item-doc-view")),
        "item",
        config.itemTopic());
  }

  // --- catalog.item-location ---------------------------------------------------------------------

  private void defineItemLocation() {
    Function<Map<String, Object>, String> itemLocation = r -> Keys.of(ITEM_NO, r.get(ITEM_NO), MI_LOC, r.get(MI_LOC));

    KTable<String, Group<Map<String, Object>>> balances =
        group(
            sources.table(ITEM_BALANCE),
            "balances-by-item-location",
            itemLocation,
            r -> Keys.of(r, ITEM_BALANCE.keyColumns()),
            ModelSerdes.ROW,
            ModelSerdes.ROWS);
    KTable<String, Group<Map<String, Object>>> localCosts =
        group(
            sources.table(LOCAL_COST),
            "local-costs-by-item-location",
            itemLocation,
            r -> Keys.of(r, LOCAL_COST.keyColumns()),
            ModelSerdes.ROW,
            ModelSerdes.ROWS);
    // NON_COS_ITEM_BALANCE is already keyed (ITEM_NO, MI_LOC): canonical keys sort their columns.
    KTable<String, Map<String, Object>> nonCos = sources.table(NON_COS_ITEM_BALANCE);

    KTable<String, ItemLocationDoc> base =
        balances
            .outerJoin(
                nonCos,
                (b, n) -> ItemLocationDoc.empty().withBalances(b).withNonCosBalance(n),
                Named.as("item-location-balances-non-cos"))
            .outerJoin(
                localCosts,
                (doc, lc) -> (doc == null ? ItemLocationDoc.empty() : doc).withLocalCosts(lc),
                Named.as("item-location-local-costs"),
                store("item-location-base", ModelSerdes.ITEM_LOCATION_DOC));
    KTable<String, Map<String, Object>> location =
        base.leftJoin(
            sources.table(LOCATION_PROFILE),
            (key, doc) -> Keys.ref(MI_LOC, Keys.parse(key).get(MI_LOC)),
            (doc, loc) -> loc,
            TableJoined.as("item-location-location"),
            store("item-location-location", ModelSerdes.ROW));
    KTable<String, ItemLocationDoc> docs =
        base.leftJoin(location, ItemLocationDoc::withLocation, Named.as("item-location-doc"));

    publish(
        docs.toStream(Named.as("item-location-doc-changes"))
            .mapValues((key, doc) -> doc == null ? null : views.itemLocation(key, doc), Named.as("item-location-doc-view")),
        "item-location",
        config.itemLocationTopic());
  }

  // --- catalog.item-price ------------------------------------------------------------------------

  /** Customer-grain prices are too many per item to embed; they are published normalized, 1:1. */
  private void definePrice() {
    sources
        .decoded(ITEM_PRICE_CACHE)
        .to(config.itemPriceTopic(), Produced.with(Serdes.String(), ModelSerdes.ROW).withName("item-price-sink"));
  }

  // --- helpers -----------------------------------------------------------------------------------

  /**
   * Re-key a table to {@code groupKey} and collect its rows per key. Rows whose group key is null
   * are left out; a key whose last row goes away is deleted.
   */
  private <V> KTable<String, Group<V>> group(
      KTable<String, V> table,
      String name,
      Function<V, String> groupKey,
      Function<V, String> entryId,
      Serde<V> valueSerde,
      Serde<Group<V>> groupSerde) {
    return table
        .filter((key, value) -> groupKey.apply(value) != null, Named.as(name + "-has-key"))
        .groupBy((key, value) -> KeyValue.pair(groupKey.apply(value), value), Grouped.with(name, Serdes.String(), valueSerde))
        .aggregate(
            Group::empty,
            (key, value, agg) -> agg.with(entryId.apply(value), value),
            // Returning null deletes the aggregate (and forwards a delete) once the last row is gone.
            (key, value, agg) -> Group.nullIfEmpty(agg.without(entryId.apply(value))),
            Named.as(name + "-aggregate"),
            store(name, groupSerde));
  }

  private void publish(KStream<String, Map<String, Object>> docs, String name, String topic) {
    String storeName = name + "-published";
    builder.addStateStore(
        Stores.keyValueStoreBuilder(Stores.persistentKeyValueStore(storeName), Serdes.String(), Serdes.ByteArray()));
    docs.processValues(() -> new EmitOnChange<Map<String, Object>>(storeName), Named.as(name + "-emit-on-change"), storeName)
        .to(topic, Produced.with(Serdes.String(), Serdes.ByteArray()).withName(name + "-sink"));
  }

  private static <V> Materialized<String, V, KeyValueStore<Bytes, byte[]>> store(String name, Serde<V> serde) {
    return Materialized.<String, V, KeyValueStore<Bytes, byte[]>>as(name + "-store")
        .withKeySerde(Serdes.String())
        .withValueSerde(serde);
  }

  static String manufacturerProductGroup(String manufacturer, String productGroup) {
    return manufacturer == null || productGroup == null
        ? null
        : Keys.of(MFR_CTL_NO, manufacturer, "PROD_GROUP_NO", productGroup);
  }

  static boolean isOpenWarehouse(Map<String, Object> location) {
    return location != null
        && "W".equalsIgnoreCase(Rows.str(location, "LOCATION_TYPE"))
        && "O".equalsIgnoreCase(Rows.str(location, "OPEN_CLOSED"));
  }
}
