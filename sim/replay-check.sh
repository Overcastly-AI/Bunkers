# Sourced by sim/run-local.sh --replay after the load simulation verified: exercises republish,
# deliver, replay-client and dlt-replay against the running broker and app. Uses run-local.sh's
# KAFKA_HOME, KAFKA_BOOTSTRAP_SERVERS, WORK, CONFIG, PIDS, MOCK_PORT and catalog_join.

B=$KAFKA_BOOTSTRAP_SERVERS
setting() { catalog_join print-config "${CONFIG[@]}" 2>/dev/null | sed -n "s/^$1=//p"; }
PREFIX=$(setting catalog.topic-prefix)
GROUP=$(setting application.id)-deliver-sim
ITEM_TOPIC=$PREFIX$(setting catalog.output.item)
DLT_TOPIC=$PREFIX$(setting catalog.output.dead-letter)
SOURCE_TOPIC=$PREFIX$(setting catalog.source.item_profile.topic)
CLIENT_TOPIC=${PREFIX}catalog.client.sim
FAILED=0
check() { if eval "$2"; then echo "  ok   $1"; else echo "  FAIL $1"; FAILED=1; fi; }
end_offset() { "$KAFKA_HOME/bin/kafka-get-offsets.sh" --bootstrap-server "$B" --topic "$1" 2>/dev/null | awk -F: '{s+=$3} END {print s+0}'; }
lag() { "$KAFKA_HOME/bin/kafka-consumer-groups.sh" --bootstrap-server "$B" --describe --group "$GROUP" 2>/dev/null \
  | awk '$1=="'$GROUP'" && $6 ~ /^[0-9]+$/ {s+=$6} END {print s+0}'; }
posted() { [[ -f $WORK/mock.log ]] && python3 -c 'import json,sys; print(sum(json.loads(l)["n"] for l in open(sys.argv[1])))' "$WORK/mock.log" || echo 0; }
wait_for() { for _ in $(seq 180); do eval "$1" && return 0; sleep 1; done; return 1; }
start_deliver() {
  catalog_join deliver "${CONFIG[@]}" --client sim >> "$WORK/deliver.log" 2>&1 &
  DELIVER=$!; PIDS+=($DELIVER)
}
stop_deliver() { kill "$DELIVER"; wait "$DELIVER" 2>/dev/null || true; }

echo "== replay checks"
python3 "$(dirname "${BASH_SOURCE[0]}")/mock-endpoint.py" "$MOCK_PORT" "$WORK/mock.log" 1 &
PIDS+=($!)

# 1. republish: unchanged documents are sent again, to every output or only the one asked for.
ITEM_END=$(end_offset $ITEM_TOPIC); CLIENT_END=$(end_offset $CLIENT_TOPIC)
catalog_join republish "${CONFIG[@]}" --key ITEM_NO=00000001 --key ITEM_NO=00000002 --key ITEM_NO=00000003 | sed 's/^/  /'
check "republish: 3 records on $ITEM_TOPIC" "wait_for '[[ \$(end_offset $ITEM_TOPIC) -eq $((ITEM_END + 3)) ]]'"
check "republish: 3 records on $CLIENT_TOPIC" "wait_for '[[ \$(end_offset $CLIENT_TOPIC) -eq $((CLIENT_END + 3)) ]]'"
ITEM_END=$(end_offset $ITEM_TOPIC); CLIENT_END=$(end_offset $CLIENT_TOPIC)
catalog_join republish "${CONFIG[@]}" --key ITEM_NO=00000004 --only sim > /dev/null
check "republish --only sim: client topic only" \
  "wait_for '[[ \$(end_offset $CLIENT_TOPIC) -eq $((CLIENT_END + 1)) ]]' && sleep 3 && [[ \$(end_offset $ITEM_TOPIC) -eq $ITEM_END ]]"

# 2. deliver: the endpoint rejects the first batch (dead-lettered), then accepts the rest.
start_deliver
check "deliver: caught up" "wait_for '[[ \$(lag) -eq 0 && \$(posted) -gt 0 ]]'"
check "deliver: rejected batch dead-lettered" "[[ \$(end_offset $CLIENT_TOPIC.dlt) -eq 1 ]]"
FIRST=$(posted)

# 3. dlt-replay --client: the rejected batch's keys are republished with current values and delivered.
CLIENT_END=$(end_offset $CLIENT_TOPIC)
catalog_join dlt-replay "${CONFIG[@]}" --client sim | sed 's/^/  /'
check "dlt-replay --client: keys republished and delivered" \
  "wait_for '[[ \$(end_offset $CLIENT_TOPIC) -gt $CLIENT_END && \$(lag) -eq 0 && \$(posted) -gt $FIRST ]]'"
check "dlt-replay --client: nothing left on a second run" \
  "catalog_join dlt-replay \"\${CONFIG[@]}\" --client sim | grep -q 'Replaying 0 rejected'"

# 4. replay-client: refused while deliver runs; then everything is re-posted from the beginning.
check "replay-client: refused while deliver runs" "! catalog_join replay-client \"\${CONFIG[@]}\" --client sim --from earliest > /dev/null 2>&1"
stop_deliver
BEFORE=$(posted)
catalog_join replay-client "${CONFIG[@]}" --client sim --from earliest | tail -1 | sed 's/^/  /'
start_deliver
KEYS=$("$KAFKA_HOME/bin/kafka-console-consumer.sh" --bootstrap-server "$B" --topic $CLIENT_TOPIC --from-beginning \
  --property print.key=true --timeout-ms 10000 2>/dev/null | cut -f1 | sort -u | wc -l)
check "replay-client: every key re-posted ($KEYS keys)" "wait_for '[[ \$(lag) -eq 0 && \$(posted) -ge $((BEFORE + KEYS)) ]]'"
stop_deliver

# 5. dlt-replay (sources): of two undecodable records for key A, only the newer is replayed.
DLT_END=$(end_offset $DLT_TOPIC)
printf '%s\n' '{"ITEM_NO":"POISON-A"}|not json 1' '{"ITEM_NO":"POISON-B"}|not json 2' '{"ITEM_NO":"POISON-A"}|not json 3' \
  | "$KAFKA_HOME/bin/kafka-console-producer.sh" --bootstrap-server "$B" --topic "$SOURCE_TOPIC" \
      --property parse.key=true --property key.separator='|' 2>/dev/null
check "undecodable records dead-lettered" "wait_for '[[ \$(end_offset $DLT_TOPIC) -eq $((DLT_END + 3)) ]]'"
catalog_join dlt-replay "${CONFIG[@]}" --dry-run | tail -1 | sed 's/^/  /'
OUT=$(catalog_join dlt-replay "${CONFIG[@]}")
echo "$OUT" | sed 's/^/  /'
check "dlt-replay: older duplicate skipped as superseded" "echo \"\$OUT\" | grep -q 'SUPERSEDED=1'"
check "dlt-replay: the rest replayed (and, still undecodable, dead-lettered again)" \
  "echo \"\$OUT\" | grep -q 'REPLAY=' && wait_for '[[ \$(end_offset $DLT_TOPIC) -gt $((DLT_END + 3)) ]]'"

[[ $FAILED == 0 ]] && echo "replay checks: ALL OK" || echo "replay checks: FAILED"
STATUS=$(( STATUS | FAILED ))
