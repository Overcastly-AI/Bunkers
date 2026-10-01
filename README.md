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
bin/catalog-join help                        # = java -jar, plus the Datadog agent when enabled
java -jar target/catalog-join.jar create-topics deploy/production/catalog-join.properties
java -jar target/catalog-join.jar run deploy/production/catalog-join.properties
java -jar target/catalog-join.jar print-config deploy/production/catalog-join.properties
```

`GET :8080/health/live` returns 200 unless processing has failed. `/health/ready` returns 200 while
running. The process exits non-zero if Kafka Streams fails, so the pod restarts.

## Downstream clients

Each client (Qdrant, a Postgres team, ...) selects only the fields it wants, in configuration:

```properties
catalog.client.qdrant.fields=itemNo, positive(sum(dcStock[].balance.QTY_ON_HAND)) as inStock
catalog.client.qdrant.http.url=https://qdrant-team/api/stock
catalog.client.qdrant.http.header.Authorization=Bearer ${QDRANT_TOKEN}
```

- The app publishes that view to `catalog.client.<name>`, a compacted topic keyed like the
  source document. It publishes **only when one of the selected fields changes**, so a stock
  quantity moving from 40 to 39 sends nothing to a client that only selects `inStock`.
- Fields are paths into the published document (`item.DESCR`, `dcStock[].balance.MI_LOC`),
  optionally renamed with `as`. The functions `sum`, `min`, `max`, `count`, `first`, `distinct`
  and `positive` are available. The full syntax is in the "downstream clients" section of
  `catalog-join.properties`.
- `catalog-join deliver --client <name>` POSTs the topic to `http.url` (to re-send, see Replay):
  - each POST is a JSON array of `{"key": {...}, "value": {...}}`, with `"value": null` for a delete;
  - batches carry the latest change per key;
  - 5xx, 408, 429 and connection errors are retried with backoff until they succeed;
  - other 4xx go to `catalog.client.<name>.dlt`.
  
  Offsets are committed only after the endpoint accepts a batch. To resend everything, run with a
  new consumer group. Deployment: `deploy/production/deliver-qdrant.yaml`.
- Clients that consume Kafka directly (e.g. a Kafka Connect JDBC sink into Postgres) just read
  their topic; leave `http.url` unset.

## Replay

| Need | How |
|---|---|
| A new consumer or sink needs everything | Read the compacted topic from offset 0 |
| Re-send a few items (to every output, or one client) | `catalog-join republish --key ITEM_NO=123 [--key …] [--keys-file F] [--only qdrant]`; `--doc item-location --key ITEM_NO=123,MI_LOC=0042` for item-location documents |
| A client lost data: re-post everything, or everything since a time | Stop its `deliver`, run `catalog-join replay-client --client qdrant --from earliest` (or `--from 2026-10-01T00:00:00Z`; `--dry-run` shows the counts), then start `deliver` again |
| Fixed the cause of dead letters | `catalog-join dlt-replay` for source records; `catalog-join dlt-replay --client qdrant` for batches a client rejected (`--dry-run` to preview) |
| Rebuild everything after a join fix | New `application.id` with versioned output topics, then switch consumers (see Operating notes) |

**What each command guarantees:**

- **`republish` goes through the running app.** It writes requests to
  `catalog.join.republish.<doc>`, and the app looks up the current document when it processes each
  one. So a republish can never overtake a newer update.
  - A key with no document publishes a tombstone, so a client that missed a delete catches up.
  - A document whose lookups are still in flight is skipped; it publishes as soon as it is consistent.
  - `item-price` documents are a 1:1 copy of `ITEM_PRICE_CACHE`; re-produce the source row instead.
- **`replay-client` re-sends the latest value of every key**, not each intermediate change, because
  client topics are compacted. It refuses to run while that client's `deliver` is running.
- **`dlt-replay` won't overwrite newer data with older data.**
  - **Source dead letters** go back to their original topic and partition. One is skipped when the
    same key has a newer record on that partition, or when it has no key to check; `--force` replays
    those too. A record that still fails is dead-lettered again.
  - **Client dead letters** are not re-posted as the stale batch. Their keys are republished, so the
    client gets each key's current value.
  - Progress is kept per dead-letter topic, so each letter is handled once; `--from-beginning`
    reconsiders them all.
- **Not available: point-in-time history.** Compacted topics keep only the latest value per key.

`sim/run-local.sh --replay` exercises all of this against a real broker and a mock client endpoint.

## Observability (Datadog)

`bin/catalog-join` (the image entrypoint) attaches the Datadog Java agent when the merged
configuration has `dd.trace.enabled=true` (on in the production and sim overlays). It hands the
agent the merged `dd.*` settings, so they live in the same files as everything else.

- **Traces**: the agent's Kafka Streams and Kafka client instrumentation opens a span per record
  processed. The app tags these spans with `catalog.source.table`, `catalog.key`,
  `catalog.dead_letter` and `error.message` for undecodable input, and with `catalog.output` and
  `catalog.published` (`false` = unchanged document suppressed) for each output document.
- **Data Streams Monitoring** (`dd.data.streams.enabled`): pathway context travels in record
  headers, so DSM shows latency from the CDC topics through the internal topics to the outputs,
  and on into the consumers.
- **Logs** carry `dd.trace_id`/`dd.span_id` (`dd.logs.injection`), and the pod annotation tags
  them `source:java`.
- **GKE**: needs the Datadog Agent DaemonSet with APM on (port 8126). `DD_AGENT_HOST` is the node
  IP; `DD_ENV`/`DD_VERSION` come from the pod's `tags.datadoghq.com/*` labels, which the overlays set.
- **Locally**: `sim/run-local.sh --datadog` prints spans to the app logs, with no Datadog agent
  needed.

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
| `Tracing`, `bin/catalog-join` | Datadog span tags; agent attach from the merged `dd.*` settings |
| `sim/*` | load simulator: deterministic model, generator, exact verifier |

## Parity with the old service

[docs/SPEC-PARITY.md](docs/SPEC-PARITY.md) checks every requirement of the original Motion Catalog
Build spec against this implementation: topics and keys, payload rules, joins, triggers and the
old output contract. The "Migrating consumers of the old service" section of
[docs/CONTRACTS.md](docs/CONTRACTS.md) lists what changed for downstream readers.

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
- **All 15 source topics must exist before `run`.** A missing or misspelled topic makes the process
  exit non-zero and restart; there is no silent "bound to zero topics" mode. Settings still set to
  `CHANGE-ME` stop `run`, `create-topics` and `deliver` at startup.
- **Consumer group = `application.id`** (`catalog-join`; it replaces `gmc-cdc-consumer` for lag
  monitoring and ACLs). A new `application.id` is a new group, and it replays the sources from the
  beginning.
- **Failures:** undecodable input goes to the dead-letter topic (with the source topic, partition
  and offset in headers; re-produce it to that topic to replay). Any other processing or produce
  error, such as a record above `producer.max.request.size`, stops the instance with a non-zero
  exit, and it restarts from its last commit. There are no in-process retries, and no data is skipped.
- **ACLs:**
  - source topics: READ, DESCRIBE;
  - group `<application.id>`: READ;
  - topic prefix `<application.id>-`: CREATE, DELETE, DESCRIBE, DESCRIBE_CONFIGS, READ, WRITE;
  - TransactionalId prefix `<application.id>`: WRITE, DESCRIBE;
  - output, client and dead-letter topics: WRITE, DESCRIBE (plus CREATE for `create-topics`);
  - `catalog.join.republish.*`: READ for the app, WRITE for whoever runs `republish` and `dlt-replay --client`.
- **Internal topics** (`<application.id>-*`) are created by Kafka Streams; their names are pinned in
  `src/test/resources/topology.txt`, and `TopologySnapshotTest` fails on any change so it is always
  deliberate. Incompatible changes (renamed operators, new joins, a different `catalog.partitions`)
  need a new `application.id` or an application reset.
- **Adding a STEP attribute** changes only configuration, but values already filtered out are not
  replayed. Reset, or redeploy under a new `application.id`, to backfill.
- **Memory**: heap is `MaxRAMPercentage` of the pod limit; RocksDB uses `catalog.rocksdb.memory-bytes`
  off heap. Size the pod limit to cover heap, RocksDB and about 25% headroom.
