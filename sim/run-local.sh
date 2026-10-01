#!/usr/bin/env bash
# Load simulation against a real (local) Kafka: starts a single-node KRaft broker, N app instances,
# produces the simulated catalog (initial load + churn), waits for the app to catch up, and verifies
# the published documents against the model.
#
#   sim/run-local.sh --items 100000 --rounds 3 --instances 2 --partitions 6
#
# Needs: KAFKA_HOME pointing at an unpacked Kafka 4.x (bin/kafka-server-start.sh), Java 21, and a
# built jar (mvn -DskipTests package). Everything runs under a temp dir that is removed afterwards
# unless --keep is given.
set -euo pipefail

ITEMS=20000 ROUNDS=3 INSTANCES=2 PARTITIONS=6 SAMPLE_EVERY=1 KEEP=false THREADS=2 HEAP=1g
while [[ $# -gt 0 ]]; do
  case "$1" in
    --items) ITEMS=$2; shift 2 ;;
    --rounds) ROUNDS=$2; shift 2 ;;
    --instances) INSTANCES=$2; shift 2 ;;
    --partitions) PARTITIONS=$2; shift 2 ;;
    --sample-every) SAMPLE_EVERY=$2; shift 2 ;;
    --threads) THREADS=$2; shift 2 ;;
    --heap) HEAP=$2; shift 2 ;;
    --keep) KEEP=true; shift ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=$ROOT/target/catalog-join.jar
: "${KAFKA_HOME:?set KAFKA_HOME to an unpacked Kafka 4.x}"
[[ -f $JAR ]] || { echo "build first: mvn -DskipTests package" >&2; exit 2; }

WORK=$(mktemp -d -t catalog-sim-XXXX)
PORT=${KAFKA_PORT:-29092}
BOOTSTRAP=localhost:$PORT
PIDS=()
cleanup() {
  for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
  wait 2>/dev/null || true
  if [[ $KEEP == false ]]; then rm -rf "$WORK"; else echo "kept $WORK"; fi
}
trap cleanup EXIT

echo "== Kafka (KRaft, single node) on $BOOTSTRAP, work dir $WORK"
cat > "$WORK/server.properties" <<PROPS
process.roles=broker,controller
node.id=1
controller.quorum.bootstrap.servers=localhost:$((PORT + 1))
listeners=PLAINTEXT://localhost:$PORT,CONTROLLER://localhost:$((PORT + 1))
advertised.listeners=PLAINTEXT://localhost:$PORT
controller.listener.names=CONTROLLER
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
log.dirs=$WORK/kafka-data
num.partitions=$PARTITIONS
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
group.initial.rebalance.delay.ms=0
log.cleaner.enable=true
PROPS
"$KAFKA_HOME/bin/kafka-storage.sh" format --standalone -t "$("$KAFKA_HOME/bin/kafka-storage.sh" random-uuid)" \
  -c "$WORK/server.properties" > "$WORK/format.log"
KAFKA_HEAP_OPTS="-Xmx1g" "$KAFKA_HOME/bin/kafka-server-start.sh" "$WORK/server.properties" > "$WORK/kafka.log" 2>&1 &
PIDS+=($!)
for _ in $(seq 60); do
  "$KAFKA_HOME/bin/kafka-topics.sh" --bootstrap-server "$BOOTSTRAP" --list > /dev/null 2>&1 && break
  sleep 1
done

SIM=(java -cp "$JAR" com.motion.catalogjoin.sim.SimMain)
COMMON=(--bootstrap "$BOOTSTRAP" --items "$ITEMS")

echo "== topics"
"${SIM[@]}" generate "${COMMON[@]}" --create-topics --partitions "$PARTITIONS" --from-round 1 --rounds 0 > "$WORK/topics.log"

echo "== $INSTANCES app instance(s)"
"${SIM[@]}" app-config > "$WORK/sim-app.properties"
for n in $(seq "$INSTANCES"); do
  cat > "$WORK/app$n.properties" <<PROPS
application.id=catalog-join
bootstrap.servers=$BOOTSTRAP
processing.guarantee=exactly_once_v2
replication.factor=1
num.stream.threads=$THREADS
commit.interval.ms=1000
statestore.cache.max.bytes=67108864
state.dir=$WORK/state$n
catalog.health-port=$((18080 + n))
PROPS
  cat "$WORK/sim-app.properties" >> "$WORK/app$n.properties"
  java -Xmx"$HEAP" -jar "$JAR" "$WORK/app$n.properties" > "$WORK/app$n.log" 2>&1 &
  PIDS+=($!)
done

echo "== generate $ITEMS items, rounds 0..$ROUNDS"
START=$(date +%s)
"${SIM[@]}" generate "${COMMON[@]}" --rounds "$ROUNDS" | tee "$WORK/generate.log"

echo "== verify"
set +e
"${SIM[@]}" verify "${COMMON[@]}" --rounds "$ROUNDS" --sample-every "$SAMPLE_EVERY" | tee "$WORK/verify.log"
STATUS=${PIPESTATUS[0]}
set -e
END=$(date +%s)

echo "== summary"
echo "end-to-end (generate + process + verify): $((END - START))s"
du -sh "$WORK"/state* 2>/dev/null | sed 's/^/state: /'
du -sh "$WORK/kafka-data" | sed 's/^/kafka log: /'
for n in $(seq "$INSTANCES"); do
  curl -s "localhost:$((18080 + n))/health" | sed "s/^/app$n health: /"; echo
  grep -cE ' ERROR ' "$WORK/app$n.log" | sed "s/^/app$n error lines: /"
done
exit "$STATUS"
