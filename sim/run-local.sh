#!/usr/bin/env bash
# Load simulation against a real local Kafka: starts a single-node KRaft broker and N app instances,
# runs sim-generate (initial load + churn), then sim-verify (wait for catch-up, check every item).
# Settings: deploy/sim + deploy/local overlays; flags below only override sizes.
#
#   KAFKA_HOME=/path/to/kafka_2.13-4.x sim/run-local.sh --items 100000 --rounds 3 --instances 2
#
# --datadog attaches the Datadog agent to the app instances with spans printed to their logs (no
# Datadog agent needed) and reports how many were traced.
#
# Needs Java 21 and a built jar plus agent (mvn -DskipTests package). Work files go to a temp dir that is
# removed afterwards unless --keep is given.
set -euo pipefail

ITEMS=20000 ROUNDS=3 INSTANCES=2 THREADS=2 HEAP=1g KEEP=false DATADOG=false
PORT=${KAFKA_PORT:-29092} HEALTH_BASE=${HEALTH_BASE:-18080}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --items) ITEMS=$2; shift 2 ;;
    --rounds) ROUNDS=$2; shift 2 ;;
    --instances) INSTANCES=$2; shift 2 ;;
    --threads) THREADS=$2; shift 2 ;;
    --heap) HEAP=$2; shift 2 ;;
    --keep) KEEP=true; shift ;;
    --datadog) DATADOG=true; shift ;;
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

catalog_join() {
  JDK_JAVA_OPTIONS="-Xmx$HEAP" CATALOG_JOIN_JAR="$JAR" DD_JAVA_AGENT_JAR="$ROOT/target/dd-java-agent.jar" "$ROOT/bin/catalog-join" "$@"
}
TRACING=()
if [[ $DATADOG == true ]]; then
  TRACING=(--set dd.trace.enabled=true --set dd.writer.type=PrintingWriter --set dd.env=local-sim)
fi

echo "== topics"
catalog_join sim-generate "${CONFIG[@]}" "${SIZE[@]}" --create-topics --set sim.from-round=1 --set sim.rounds=0 > "$WORK/topics.log"

echo "== $INSTANCES app instance(s)"
for n in $(seq "$INSTANCES"); do
  catalog_join run "${CONFIG[@]}" ${TRACING[@]+"${TRACING[@]}"} --set "state.dir=$WORK/state$n" \
    --set "catalog.health-port=$((HEALTH_BASE + n))" --set "num.stream.threads=$THREADS" > "$WORK/app$n.log" 2>&1 &
  PIDS+=($!)
done

echo "== waiting for the app instance(s) to start"
for n in $(seq "$INSTANCES"); do
  for _ in $(seq 120); do
    curl -sf "localhost:$((HEALTH_BASE + n))/health/live" > /dev/null && break
    kill -0 "${PIDS[$n]}" 2>/dev/null || { echo "app$n exited:" >&2; tail -20 "$WORK/app$n.log" >&2; exit 1; }
    sleep 1
  done
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
  if [[ $DATADOG == true ]]; then
    echo "app$n traced: $(grep -o '"catalog.published"' "$WORK/app$n.log" | wc -l) published-step spans," \
      "$(grep -o '"catalog.source.table"' "$WORK/app$n.log" | wc -l) decode spans," \
      "$(grep -o '"catalog.dead_letter"' "$WORK/app$n.log" | wc -l) dead-letter spans"
  fi
done
exit "$STATUS"
