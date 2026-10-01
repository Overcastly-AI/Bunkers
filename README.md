# catalog-join

A Kafka Streams application (Java 21) that joins the 15 catalog CDC topics into three
**log-compacted** topics: `catalog.item` (per `ITEM_NO`), `catalog.item-location` (per
`ITEM_NO` + `MI_LOC`) and `catalog.item-price` (per price-cache row). Every join is a table-to-table
join that recomputes when **either** side changes. There are no cron rebuilds and no pending-key
queues, documents are re-published only when they change, and deletes become tombstones.

**[docs/CONTRACTS.md](docs/CONTRACTS.md) is the contract**: input formats, canonical keys, every
join key, document shapes, and what happens when a join partner arrives late.

## Configuration

All settings live in one file with their defaults:
[`src/main/resources/catalog-join.properties`](src/main/resources/catalog-join.properties). This
covers topics and key columns, STEP attribute ids, DC codes, the hierarchy root, Kafka Streams, the
RocksDB memory budget, the health port and the simulator. Each environment adds one overlay file
containing only what differs:

| Overlay | Used by |
|---|---|
| `deploy/production/catalog-join.properties` | GKE production (`kubectl apply -k deploy/production`) |
| `deploy/sim/catalog-join.properties` | load simulation: GKE (`deploy/sim`), `sim/run-local.sh`, `SimulationTest` |
| `deploy/local/catalog-join.properties` | local single-broker runs, layered after `deploy/sim` |
| `src/test/resources/test.properties` | in-process tests |

Files are layered in order (later wins), then `--set key=value` overrides. Values can use
`${ENV}` / `${ENV:default}`. `catalog-join print-config <files>` shows the merged result, with
secrets masked.

## Commands

One jar; the container runs `run` by default.

```bash
mvn verify                                   # tests (no Kafka needed)
java -jar target/catalog-join.jar help
java -jar target/catalog-join.jar create-topics deploy/production/catalog-join.properties
java -jar target/catalog-join.jar run deploy/production/catalog-join.properties
java -jar target/catalog-join.jar print-config deploy/production/catalog-join.properties
```

`GET :8080/health/live` returns 200 unless processing has failed. `/health/ready` returns 200 while
running. The process exits non-zero if Kafka Streams fails, so the pod restarts.

## Code map

| Path | What |
|---|---|
| `CatalogConfig` | the layered configuration |
| `ingest/CdcDecoder`, `ingest/CdcEnvelope` | message formats → rows with canonical keys |
| `ingest/Sources` | one decode/repartition/table per source topic; dead-lettering |
| `topology/CatalogTopology` | every join, in one file, building documents in their published shape |
| `topology/ClassificationPaths` | the hierarchy walk (replaces the recursive CTE) |
| `topology/EmitOnChange` | suppresses unchanged documents before each output topic |
| `BoundedRocksDb` | one off-heap memory budget for all state stores |
| `sim/*` | load simulator: deterministic model, generator, exact verifier |

## Load simulation

The simulator produces a synthetic catalog at any scale and checks the app's output against it
exactly. Each row's state after churn round N is a pure function of (seed, items, round), so the
checker can compute what every document must contain without replaying anything.

The generated traffic covers:
- every message format, padded keys and deletes;
- key-changing edits, with the delete and the insert arriving in both orders;
- foreign keys that change, and hierarchy moves.

Each item generates about 30 source records at round 0, plus about 10% per churn round.

| Where | How |
|---|---|
| In-process | `mvn test -Dtest='SimulationTest#scaled' -Dsim.items=20000` (correctness only; the test driver is slow) |
| Local Kafka | `KAFKA_HOME=/path/to/kafka_2.13-4.3.1 sim/run-local.sh --items 100000 --instances 2` |
| GKE | `kubectl apply -k deploy/sim`: the app on `sim.*` topics, plus the generate and verify Jobs |

## Operating notes

- **Source topics must be compacted** (or keep full history): rebuilding state replays them from
  the start.
- **Internal topics** (`<application.id>-*`) are created by Kafka Streams; their names are pinned in
  `src/test/resources/topology.txt`, and `TopologySnapshotTest` fails on any change so it is always
  deliberate. Incompatible changes (renamed operators, new joins, a different `catalog.partitions`)
  need a new `application.id` or an application reset.
- **Adding a STEP attribute** changes only configuration, but values already filtered out are not
  replayed. Reset, or redeploy under a new `application.id`, to backfill.
- **Memory**: heap is `MaxRAMPercentage` of the pod limit; RocksDB uses `catalog.rocksdb.memory-bytes`
  off heap. Size the pod limit to cover heap, RocksDB and about 25% headroom.
