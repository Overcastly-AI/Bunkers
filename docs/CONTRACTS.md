# Catalog Join — Topics, Keys and Contracts

One Kafka Streams application reads the catalog CDC topics, joins them, and publishes three
**log-compacted** topics. Nothing else is involved: no database, no outbox, no schedulers.

Every name and code below is a default from `src/main/resources/catalog-join.properties` (the one
configuration file; `catalog-join print-config` shows the effective values). Topic names also get
`catalog.topic-prefix` in front.

```
15 CDC topics ──► decode + canonical key ──► table per source ──► joins ──► catalog.item            (ITEM_NO)
                                                                        ──► catalog.item-location   (ITEM_NO, MI_LOC)
                                  ITEM_PRICE_CACHE (normalized, 1:1)    ──► catalog.item-price      (ITEM_NO, MI_LOC, CUSTOMER_NO)
                                  undecodable records                   ──► catalog.join.dlt
```

---

## 1. Inputs

Each table's topic and key columns are `catalog.source.<table>.topic` and
`catalog.source.<table>.key`.

| Topic | Table | Key columns (primary key) | Used for |
|---|---|---|---|
| `topic.brop.item_profile-json` | BROP.ITEM_PROFILE | `ITEM_NO` | root of `catalog.item` |
| `topic.brop.mfr_profile-json` | BROP.MFR_PROFILE | `MFR_CTL_NO` | item → manufacturer |
| `topic.misearch.mfr_name-json` | MISEARCH.MFR_NAME | `MFR_NAME_ID` | manufacturer → name |
| `topic.branch.item_restrict_rule-json` | BRANCH.ITEM_RESTRICT_RULE | `CTL_NO` | restrictions |
| `topic.brop.item_balance-json` | BROP.ITEM_BALANCE | `ITEM_NO, MI_LOC, STOREROOM_NO` | DC stock; item-location |
| `topic.brop.location_profile-json` | BROP.LOCATION_PROFILE | `MI_LOC` | DC filter; item-location |
| `topic.brop.item_cost-json` | BROP.ITEM_COST | `ITEM_NO, CORP_MI_LOC` | item costs |
| `topic.brop.non_cos_item_balance-json` | BROP.NON_COS_ITEM_BALANCE | `MI_LOC, ITEM_NO` | item-location |
| `topic.brop.local_cost-json` | BROP.LOCAL_COST | `MI_LOC, ITEM_NO, EFFECTIVE_DATE, EXPIRATION_DATE` | item-location |
| `topic.fsdb.step_product_values-json` | FSDB.STEP_PRODUCT_VALUES | `STEP_PRODUCT_ID, STEP_ATTRIBUTE_ID, STEP_UNIT_ID, VALUE` | STEP attributes |
| `topic.fsdb.step_unit-json` | FSDB.STEP_UNIT | `STEP_UNIT_ID` | attribute units |
| `topic.fsdb.step_product-json` | FSDB.STEP_PRODUCT | `STEP_PRODUCT_ID` | STEP product row |
| `topic.fsdb.step_product_classification-json` | FSDB.STEP_PRODUCT_CLASSIFICATION | `STEP_PRODUCT_ID, STEP_CLASSIFICATION_ID` | product → classification |
| `topic.fsdb.step_classification-json` | FSDB.STEP_CLASSIFICATION | `STEP_CLASSIFICATION_ID` | hierarchy paths |
| `topic.item.item_price_cache-json` | ITEM.ITEM_PRICE_CACHE | `ITEM_NO, MI_LOC, CUSTOMER_NO` | `catalog.item-price` |

### 1.1 Accepted message formats

Key and value are read as raw bytes. `catalog.payload-format` = `AVRO_OR_JSON` (default),
`AVRO_ONLY` or `JSON_ONLY`.

| Value | Meaning |
|---|---|
| Avro IBM CDC envelope (`src/main/resources/avro/cdc-envelope.avsc`), raw or Confluent-framed (`0x00` + 4-byte schema id) | `op` `I`/`U` → row = `after`; `D` → delete (key from `before` and/or the message key) |
| JSON envelope: string `op` plus an `after` and/or `before` field (field names in any case) | `I`/`U` → row = `after`; `D` → delete (key from `before` and/or the message key) |
| Flat JSON object (KCOP) | the object is the row |
| `null`, empty, or the text `null` | delete (tombstone); the key must identify the row |

- **Key**: a JSON object of the key columns. For single-column keys a JSON string or integer, or
  plain printable text, is also accepted. Anything else (binary keys such as Avro, `null`, arrays,
  decimals) is ignored, so the key columns must then be present in the value. The key is merged
  into the row first; value columns overwrite it.
- **Key changes**: an update whose `before` image has a different key than its `after` image is
  applied as a delete of the old key plus an upsert of the new one.
- **Column names** are case-insensitive (upper-cased on read).
- **Avro-JSON union wrappers** (`{"string":"ABC"}`, also `map`/`array`) are unwrapped recursively,
  and a named-record wrapper around `before`/`after` (`{"com.ibm.cdc.Row": {...}}`) is removed.
- **Rows are flat**: a column whose value is an object or array makes the record invalid.
- **Decimals** are kept exact (`BigDecimal`); NUL characters (escaped or raw) are stripped from
  strings; the columns in `catalog.ingest.dropped-columns` (`LAST_EVENT_AT`) are dropped. All other
  columns pass through untouched.
- **Avro schema**: the envelope is decoded with the bundled schema; the Confluent schema id is
  skipped, not looked up, so producers must write exactly this envelope schema.
- **Invalid records** (not decodable, or a key column missing) go to `catalog.join.dlt` with the
  original key/value bytes and headers `catalog.error`, `catalog.source.topic`,
  `catalog.source.partition`, `catalog.source.offset`. Processing continues.

### 1.2 What the producers must guarantee

| Requirement | Why |
|---|---|
| Messages keyed by primary key; one partition per key | per-row ordering |
| **Topics compacted** (or retaining full history) | a new deployment, or a reset after an incompatible change, rebuilds every table by replaying from offset 0; anything already deleted by retention is missing from the joins |
| Deletes sent (tombstone or `op=D`) | otherwise rows never leave the output |

---

## 2. Keys

Every key — internal and published — is the **canonical key**: a compact JSON object of the key
columns, names upper-cased and sorted, values as trimmed strings (numbers without trailing zeros).

```
{"ITEM_NO":"123"}
{"ITEM_NO":"123","MI_LOC":"0042"}
{"CUSTOMER_NO":"C1","ITEM_NO":"123","MI_LOC":"0042"}
```

The same function builds every foreign key, so `"123  "`, `123` and `123.0` all join. Columns
listed in `catalog.source.<table>.exact-key` keep their whitespace (default: `STEP_PRODUCT_VALUES.VALUE`,
a VARCHAR where `"x"` and `"x "` are different rows). After decoding, every source is repartitioned
by canonical key, so all tables are partitioned by the same bytes whatever the producers' key
formatting.

---

## 3. Join keys

Every join is a table-to-table join and **recomputes when either side changes**. There are no
scheduled rebuilds.

| Output part | Join | Kind |
|---|---|---|
| item | `ITEM_PROFILE` (root) | — |
| manufacturer | `ITEM_PROFILE.MFR_CTL_NO = MFR_PROFILE.MFR_CTL_NO`, then `MFR_PROFILE.MFR_NAME_ID = MFR_NAME.MFR_NAME_ID` | foreign key ×2 |
| restrictions.item | `ITEM_RESTRICT_RULE.ITEM_NO = ITEM_NO` (non-blank) | re-key + aggregate |
| restrictions.manufacturer | `ITEM_RESTRICT_RULE.MFR_CTL_NO = ITEM_PROFILE.MFR_CTL_NO` where rule `PROD_GROUP_NO` is blank | aggregate + foreign key |
| restrictions.manufacturerProductGroup | `(MFR_CTL_NO, PROD_GROUP_NO) = (ITEM_PROFILE.MFR_CTL_NO, ITEM_PROFILE.PRODUCT_GROUP_NO)`, both non-blank | aggregate + foreign key |
| dcStock | `ITEM_BALANCE.MI_LOC = LOCATION_PROFILE.MI_LOC` where `LOCATION_TYPE` ∈ `catalog.dc-stock.location-types` (`W`) and `OPEN_CLOSED` ∈ `catalog.dc-stock.location-statuses` (`O`), grouped by `ITEM_NO`; empty when the manufacturer's `SELLABLE` ∈ `catalog.dc-stock.exclude-sellable` (`N`) | foreign key + aggregate |
| costs | `ITEM_COST` grouped by `ITEM_NO` | aggregate |
| stepProducts | `STEP_PRODUCT_VALUES` value of the `ITEM_NUMBER` attribute `= ITEM_NO` (the STEP → BROP bridge) | aggregate by `STEP_PRODUCT_ID`, then by item number |
| stepProducts[].attributes | `STEP_PRODUCT_VALUES.STEP_UNIT_ID = STEP_UNIT.STEP_UNIT_ID`, grouped by `STEP_PRODUCT_ID`, configured attributes only | foreign key + aggregate |
| stepProducts[].product | `STEP_PRODUCT.STEP_PRODUCT_ID` | primary key |
| stepProducts[].classifications | `STEP_PRODUCT_CLASSIFICATION.STEP_CLASSIFICATION_ID` → classification path | foreign key + aggregate |
| classification path | `child.PARENT_STEP_CLASSIFICATION_ID = parent.STEP_CLASSIFICATION_ID`, walked up until the parent is the root (`catalog.step.classification-root`, `Motion`); the root row and anything above it are never part of a path | single-partition processor (replaces the recursive CTE) |
| item-location | `ITEM_BALANCE` ⟗ `NON_COS_ITEM_BALANCE` ⟗ `LOCAL_COST` on `(ITEM_NO, MI_LOC)`, + `LOCATION_PROFILE` on `MI_LOC` | aggregate + outer join + foreign key |

### Timing and completeness

Table joins have **no time window and no timeout**. Every side is kept as a table for as long as
the row exists, and a document is recomputed whenever any side changes, whether that is a second or
a month later:

- An item whose manufacturer, rules, balances, STEP product or classification has not arrived is
  published **immediately**, with that part `null` or `[]`. When the missing row arrives, an hour
  or a week later, the item is re-published with it filled in. Nothing expires and nothing is lost.
- A row that points at something missing (a STEP product whose item number has no `ITEM_PROFILE`,
  a balance at an unknown location) is kept in state and joins as soon as its partner appears.
- Consumers therefore see a document **converge**: a compacted topic always ends with the complete,
  latest version. A consumer that must not act on a partial document checks the parts it needs
  (e.g. `manufacturer != null`).
- What is never published is an *inconsistent* document: when an item's `MFR_CTL_NO` or
  `PRODUCT_GROUP_NO` changes, the manufacturer and rule lookups take a round trip to catch up, and
  the intermediate version (new item row, old manufacturer) is held back. Only the caught-up version
  is published.

Things that were broken or slow before and are not any more:

- **STEP_UNIT changes refresh shipping weight** (and every other attribute's unit).
- **A STEP_PRODUCT_VALUES edit** (delete old key + insert new key, possibly on different partitions)
  converges regardless of arrival order: aggregates add/remove by row id.
- **Restrictions and DC stock** update immediately on `ITEM_PROFILE`, `MFR_PROFILE`,
  `LOCATION_PROFILE` or rule changes, not every 15 minutes.
- **Hierarchy paths** update for the whole subtree when an ancestor changes.

---

## 4. Outputs

All output topics: key = canonical key (UTF-8 JSON string), value = UTF-8 JSON, **tombstone** when
the entity goes away. The app writes with exactly-once semantics; consumers should read with
`isolation.level=read_committed`. `catalog.item` and `catalog.item-location` documents are
re-published **only when their bytes change**; object keys are sorted and arrays are in key order,
so the same content always serializes identically. `catalog.item-price` mirrors its source 1:1.

With Datadog tracing on, records also carry the agent's headers (`x-datadog-trace-id`,
`x-datadog-parent-id`, `x-datadog-sampling-priority`, `dd-pathway-ctx-base64`); consumers can
ignore them, or continue the trace with their own Datadog instrumentation.

Create the topics before the first start with `catalog-join create-topics <config>`:
`cleanup.policy=compact` for the three catalog topics, `delete` for the dead-letter topic, sized by
`catalog.output.*`.

### 4.1 `catalog.item` — key `{"ITEM_NO":"…"}`

Exists while the `ITEM_PROFILE` row exists. Row objects (`item`, `profile`, `name`, `balance`,
`location`, `value`, …) are the source rows with all columns, upper-cased.

```jsonc
{
  "itemNo": "123",
  "item": { "ITEM_NO": "123", "MFR_CTL_NO": "AB", "PRODUCT_GROUP_NO": "G1", ... },
  "manufacturer": {                       // null when MFR_CTL_NO matches no MFR_PROFILE
    "profile": { "MFR_CTL_NO": "AB", "MFR_NAME_ID": "N1", "SELLABLE": "Y", ... },
    "name":    { "MFR_NAME_ID": "N1", ... }            // null when no MFR_NAME
  },
  "restrictions": {
    "item":                     [ { "CTL_NO": "R1", ... } ],
    "manufacturer":             [ { "CTL_NO": "R2", ... } ],
    "manufacturerProductGroup": [ { "CTL_NO": "R3", ... } ]
  },
  "dcStock": [                           // open warehouse locations only
    { "balance": { "ITEM_NO": "123", "MI_LOC": "DC1", "STOREROOM_NO": "1", ... },
      "location": { "MI_LOC": "DC1", "LOCATION_TYPE": "W", "OPEN_CLOSED": "O", ... } }
  ],
  "costs": [ { "ITEM_NO": "123", "CORP_MI_LOC": "01", ... } ],
  "stepProducts": [
    {
      "stepProductId": "P1",
      "product": { "STEP_PRODUCT_ID": "P1", ... },        // null until STEP_PRODUCT arrives
      "attributes": {                                     // names from catalog.step.attribute.*
        "ITEM_NUMBER":     [ { "value": "123", "stepUnitId": null, "unit": null } ],
        "SHIPPING_WEIGHT": [ { "value": "2.5", "stepUnitId": "LB", "unit": { "STEP_UNIT_ID": "LB", ... } } ]
      },
      "classifications": [
        { "stepClassificationId": "C3",
          "link": { "STEP_PRODUCT_ID": "P1", "STEP_CLASSIFICATION_ID": "C3", ... },
          "inWebHierarchy": true,                         // chain reaches the configured root
          "path": [ { "STEP_CLASSIFICATION_ID": "C1", ... }, { ... "C2" }, { ... "C3" } ] }
      ]
    }
  ]
}
```

Notes:
- Attribute values are arrays; normally one entry. With several `ITEM_NUMBER` values (briefly,
  during an edit) the product attaches to the smallest.
- A rule's blank or missing `PROD_GROUP_NO` counts as blank (the `' '` branch of the old UNION).

### 4.2 `catalog.item-location` — key `{"ITEM_NO":"…","MI_LOC":"…"}`

Exists while any of `ITEM_BALANCE`, `NON_COS_ITEM_BALANCE` or `LOCAL_COST` has a row for the pair.

```jsonc
{
  "itemNo": "123",
  "miLoc": "0042",
  "location": { "MI_LOC": "0042", ... },          // null when unknown
  "balances": [ { "STOREROOM_NO": "1", ... } ],    // one per storeroom
  "nonCosBalance": { ... },                        // null when none
  "localCosts": [ { "EFFECTIVE_DATE": "...", "EXPIRATION_DATE": "...", ... } ]   // all rows, not date-filtered
}
```

### 4.3 `catalog.item-price` — key `{"CUSTOMER_NO":"…","ITEM_NO":"…","MI_LOC":"…"}`

The `ITEM_PRICE_CACHE` row, normalized (upper-case columns, unwrapped unions, exact decimals). One
output record per input record; tombstone on delete. Kept separate because customer-level prices
are too many per item to embed.

### 4.4 `catalog.join.dlt`

Original key and value bytes of undecodable input, with the headers listed in §1.1.

---

## 5. Not covered

- **Sales** (`sales__mi_sales_detail__agg`, `mi_sales__num_customers`) is not on Kafka. To include
  it, have the nightly job publish `{"ITEM_NO":…} → {num_customers…}` to a compacted topic; it joins
  onto `catalog.item` like any other item-keyed table.
- **STEP products whose item number matches no `ITEM_PROFILE`** are not published (the item is the
  root). They appear as soon as the item arrives.
