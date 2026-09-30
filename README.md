# catalog-join

A Kafka Streams application (Java 21) that joins the catalog CDC topics into three **log-compacted**
topics:

| Topic | Key | One record per |
|---|---|---|
| `catalog.item` | `{"ITEM_NO":…}` | item: profile, manufacturer, restrictions, DC stock, costs, STEP products with attributes and classification paths |
| `catalog.item-location` | `{"ITEM_NO":…,"MI_LOC":…}` | item at a location: balances, non-COS balance, local costs, location |
| `catalog.item-price` | `{"CUSTOMER_NO":…,"ITEM_NO":…,"MI_LOC":…}` | price-cache row, normalized |

Every join is a table-to-table join that recomputes when **either** side changes, so there are no
cron rebuilds, no pending-key queues and no stale derived rows. Documents are re-published only when
their content changes, and deletes become tombstones.

**Start with [docs/CONTRACTS.md](docs/CONTRACTS.md)**: input topics and formats, canonical keys,
every join key, and the published document shapes.

## How it works

```
source topic ─► decode (Avro | JSON envelope | flat JSON | tombstone) ─► canonical key ─► repartition ─► table
                        └─ undecodable ─► catalog.join.dlt

ITEM_PROFILE ─┬─ fk MFR_CTL_NO ─► MFR_PROFILE ─ fk MFR_NAME_ID ─► MFR_NAME
              ├─ fk MFR_CTL_NO ─► rules grouped by MFR_CTL_NO            (PROD_GROUP_NO blank)
              ├─ fk MFR_CTL_NO+PRODUCT_GROUP_NO ─► rules grouped by MFR+GROUP
              ├─ rules grouped by ITEM_NO
              ├─ ITEM_BALANCE ─ fk MI_LOC ─► LOCATION_PROFILE, open warehouses, grouped by ITEM_NO
              ├─ ITEM_COST grouped by ITEM_NO
              └─ STEP products grouped by their ITEM_NUMBER attribute
                    STEP_PRODUCT_VALUES ─ fk STEP_UNIT_ID ─► STEP_UNIT, grouped by STEP_PRODUCT_ID
                    STEP_PRODUCT_CLASSIFICATION ─ fk ─► classification paths, grouped by STEP_PRODUCT_ID
                    STEP_PRODUCT
                                                        ─► emit-on-change ─► catalog.item
```

Code map:

| Path | What |
|---|---|
| `ingest/CdcDecoder` | message formats → row + canonical key |
| `ingest/Sources` | one decode/repartition/table per source topic; dead-lettering |
| `topology/CatalogTopology` | every join, in one file |
| `topology/ClassificationPaths` | the hierarchy walk (replaces the recursive CTE) |
| `topology/EmitOnChange` | suppresses unchanged documents before each output topic |
| `topology/Views` | published document shapes |

## Build and test

```bash
mvn verify                  # unit + end-to-end topology tests (TopologyTestDriver, no Kafka needed)
mvn test -Dtopology.update=true   # accept an intentional topology change (see below)
docker build -t catalog-join .
```

## Run

1. Create the output topics: `deploy/create-topics.sh <bootstrap> [partitions] [replication]`.
2. Configure `deploy/application.properties` (or mount your own and point `CATALOG_CONFIG` at it).
   Required: `bootstrap.servers` and `catalog.step.attribute.ITEM_NUMBER` (the `STEP_ATTRIBUTE_ID`
   that holds the item number). Values can use `${ENV_VAR}` / `${ENV_VAR:default}`.
3. Run `java -jar target/catalog-join.jar application.properties`, or the container, or
   `deploy/kubernetes.yaml` (StatefulSet, so local state survives restarts).

`GET :8080/health` returns 200 while running. The process exits non-zero if Kafka Streams fails.

## Operating notes

- **Source topics must be compacted** (or keep full history). Rebuilding state means replaying the
  sources from the beginning.
- **Scale** by adding instances (up to the partition count of the source topics).
- **Internal topics** (`catalog-join-*-repartition`, `*-changelog`, `*-subscription-*`) are created
  by Kafka Streams. The app needs ACLs to create them; the names are pinned in
  `src/test/resources/topology.txt`.
- **Changing the topology** (a new join, a renamed operator) can make existing state incompatible.
  `TopologySnapshotTest` fails on any change so it is always deliberate. For an incompatible
  change, deploy under a new `application.id` (it rebuilds from the sources and then catches up)
  and switch over, or stop the app and run `kafka-streams-application-reset`.
- **Adding a STEP attribute** changes only configuration, but values already filtered out are not
  replayed. Reset or redeploy under a new `application.id` to backfill.
- Output consumers should read with `isolation.level=read_committed` (the app uses exactly-once).
