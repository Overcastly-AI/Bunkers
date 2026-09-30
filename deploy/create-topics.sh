#!/usr/bin/env bash
# Creates the output topics. Usage: deploy/create-topics.sh <bootstrap> [partitions] [replication]
# Extra kafka-topics.sh flags (e.g. --command-config client.properties) can go in KAFKA_TOPICS_OPTS.
set -euo pipefail
BOOTSTRAP=${1:?bootstrap servers}
PARTITIONS=${2:-12}
REPLICATION=${3:-3}
KT=${KAFKA_TOPICS:-kafka-topics.sh}

create() {
  "$KT" --bootstrap-server "$BOOTSTRAP" ${KAFKA_TOPICS_OPTS:-} --create --if-not-exists \
    --topic "$1" --partitions "$PARTITIONS" --replication-factor "$REPLICATION" "${@:2}"
}

for topic in catalog.item catalog.item-location catalog.item-price; do
  create "$topic" \
    --config cleanup.policy=compact \
    --config min.compaction.lag.ms=0 \
    --config segment.ms=3600000 \
    --config max.message.bytes=4194304
done
create catalog.join.dlt --config cleanup.policy=delete --config retention.ms=1209600000
