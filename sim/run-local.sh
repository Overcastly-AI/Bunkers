#!/usr/bin/env bash
# Load simulation against a real local Kafka: starts a single-node KRaft broker and N app instances,
# runs sim-generate (initial load + churn), then sim-verify (wait for catch-up, check every item).
# Settings: deploy/sim + deploy/local overlays; flags below only override sizes.
#
#   KAFKA_HOME=/path/to/kafka_2.13-4.x sim/run-local.sh --items 100000 --rounds 3 --instances 2
#
# Needs Java 21 and a built jar (mvn -DskipTests package). Work files go to a temp dir that is
# removed afterwards unless --keep is given.
set -euo pipefail

ITEMS=20000 ROUNDS=3 INSTANCES=2 THREADS=2 HEAP=1g KEEP=false
PORT=${KAFKA_PORT:-29092} HEALTH_BASE=18080
while [[ $# -gt 0 ]]; do
  case "$1" in
    --items) ITEMS=$2; shift 2 ;;
    --rounds) ROUNDS=$2; shift 2 ;;
    --instances) INSTANCES=$2; shift 2 ;;
    --threads) THREADS=$2; shift 2 ;;
    --heap) HEAP=$2; shift 2 ;;
    --keep) KEEP=true; shift ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=$ROOT/target/catalog-join.jar
CONFIG=("$ROOT/deploy/sim/catalog-join.properties" "$ROOT/deploy/local/catalog-join.properties")
SIZE=(--set "sim.items=$ITEMS" --set "sim.rounds=$ROUNDS")
: "${KAFKA_HOME:?set KAFKA_HOME to an unpacked Kafka 4.x}"
[[ -f $JAR ]] || { echo "build first: mvn -DskipTests package" >&2; exit 2; }

WORK=$(mktemp -d -t catalog-sim-XXXX)
export KAFKA_BOOTSTRAP_SERVERS=localhost:$PORT
PIDS=()
cleanup() {
  for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
  wait 2>/dev/null || true
  if [[ $KEEP == false ]]; then rm -rf "$WORK"; else echo "kept $WORK"; fi
}
trap cleanup EXIT

echo "== Kafka (KRaft, single node) on $KAFKA_BOOTSTRAP_SERVERS, work dir $WORK"
cat > "$WORK/server.properties" <<PROPS
process.roles=broker,controller
node.id=1
controller.quorum.bootstrap.servers=localhost:$((PORT + 1))
listeners=PLAINTEXT://localhost:$PORT,CONTROLLER://localhost:$((PORT + 1))
advertised.listeners=PLAINTEXT://localhost:$PORT
controller.listener.names=CONTROLLER
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
log.dirs=$WORK/kafka-data
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
group.initial.rebalance.delay.ms=0
PROPS
"$KAFKA_HOME/bin/kafka-storage.sh" format --standalone -t "$("$KAFKA_HOME/bin/kafka-storage.sh" random-uuid)" \
  -c "$WORK/server.properties" > "$WORK/format.log"
KAFKA_HEAP_OPTS="-Xmx1g" "$KAFKA_HOME/bin/kafka-server-start.sh" "$WORK/server.properties" > "$WORK/kafka.log" 2>&1 &
PIDS+=($!)
for _ in $(seq 60); do
  "$KAFKA_HOME/bin/kafka-topics.sh" --bootstrap-server "$KAFKA_BOOTSTRAP_SERVERS" --list > /dev/null 2>&1 && break
  sleep 1
done

catalog_join() { java -Xmx"$HEAP" -jar "$JAR" "$@"; }

echo "== topics"
catalog_join sim-generate "${CONFIG[@]}" "${SIZE[@]}" --create-topics --set sim.from-round=1 --set sim.rounds=0 > "$WORK/topics.log"

echo "== $INSTANCES app instance(s)"
for n in $(seq "$INSTANCES"); do
  catalog_join run "${CONFIG[@]}" --set "state.dir=$WORK/state$n" --set "catalog.health-port=$((HEALTH_BASE + n))" \
    --set "num.stream.threads=$THREADS" > "$WORK/app$n.log" 2>&1 &
  PIDS+=($!)
done

echo "== generate $ITEMS items, rounds 0..$ROUNDS"
START=$(date +%s)
catalog_join sim-generate "${CONFIG[@]}" "${SIZE[@]}" | tee "$WORK/generate.log"

echo "== verify"
set +e
catalog_join sim-verify "${CONFIG[@]}" "${SIZE[@]}" | tee "$WORK/verify.log"
STATUS=${PIPESTATUS[0]}
set -e
END=$(date +%s)

echo "== summary"
echo "end-to-end (generate + process + verify): $((END - START))s"
du -sh "$WORK"/state* 2>/dev/null | sed 's/^/state: /'
du -sh "$WORK/kafka-data" | sed 's/^/kafka log: /'
for n in $(seq "$INSTANCES"); do
  echo "app$n ready: $(curl -s "localhost:$((HEALTH_BASE + n))/health/ready")"
  echo "app$n error lines: $(grep -c ' ERROR ' "$WORK/app$n.log" || true)"
done
exit "$STATUS"
