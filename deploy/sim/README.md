# Load simulation on GKE

Runs a separate catalog-join instance (`application.id=catalog-join-sim`) against `sim.`-prefixed
topics, so it never touches the real CDC or catalog topics. Same image as the app.

1. **Topics + data** (the generator creates the `sim.*` topics):
   edit `KAFKA_BOOTSTRAP_SERVERS`, `--items`, `--partitions`, `--replication` in `generator-job.yaml`, then
   `kubectl apply -f deploy/sim/generator-job.yaml`.
   About 30 source records per item at round 0 plus ~10% per churn round:
   `--items 1000000` ≈ 30M+ records.
2. **App under test**: `kubectl apply -f deploy/sim/app.yaml` (can run at the same time as the generator).
3. **Verify** once the generator Job has completed: `kubectl apply -f deploy/sim/verify-job.yaml`.
   It waits until the app has consumed everything, prints the catch-up progress (lag, consumed/s),
   then checks a sample of items (`--sample-every 100` = 1%) against the model. Exit code 0 = all match.
   `kubectl logs job/catalog-join-sim-verify -f`

Generator and verifier must use the same `--seed`, `--items`, `--locations`, `--prices-per-item`
and `--topic-prefix`, and the verifier's `--rounds` must equal the last round generated.

More churn later: run the generator again with `--from-round 4 --rounds 6` and verify with
`--rounds 6`.

For secured clusters put client settings (SASL, etc.) in a Secret mounted as a file and pass
`--client-config /etc/sim/client.properties`; add the same settings to the app ConfigMap.

Clean up: delete the Jobs and StatefulSet, then the `sim.*` topics and the
`catalog-join-sim-*` internal topics.
