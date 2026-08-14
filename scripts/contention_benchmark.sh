#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
workers="${1:-16}"
tmp="$(mktemp -d)"
trap 'find "$tmp" -depth -delete' EXIT
run_adapter() {
  local adapter="$1" state="$tmp/$1" successes=0 independent=0
  "$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- init --state "$state" --storage-adapter "$adapter" --json >/dev/null
  local pids=()
  for ((i=0; i<workers; i++)); do
    "$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- idea add --state "$state" --storage-adapter "$adapter" --input "$ROOT/fixtures/core.json" --actor "worker-$i" --id idea-contention --timestamp 2026-08-14T12:00:00Z --json >"$tmp/$adapter-$i.json" 2>/dev/null &
    pids+=("$!")
  done
  for pid in "${pids[@]}"; do if wait "$pid"; then successes=$((successes + 1)); fi; done
  if [[ "$successes" -ne 1 ]]; then printf '%s adapter produced %s winners under contention\n' "$adapter" "$successes" >&2; return 1; fi
  pids=()
  for ((i=0; i<workers; i++)); do
    "$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- idea add --state "$state" --storage-adapter "$adapter" --input "$ROOT/fixtures/core.json" --actor "worker-$i" --id "idea-independent-$i" --timestamp 2026-08-14T12:00:01Z --json >"$tmp/$adapter-independent-$i.json" 2>/dev/null &
    pids+=("$!")
  done
  for pid in "${pids[@]}"; do if wait "$pid"; then independent=$((independent + 1)); fi; done
  if [[ "$independent" -ne "$workers" ]]; then printf '%s adapter persisted only %s/%s independent writers\n' "$adapter" "$independent" "$workers" >&2; return 1; fi
  "$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- validate --state "$state" --storage-adapter "$adapter" --json >/dev/null
  printf '{"adapter":"%s","workers":%s,"collision_winners":%s,"independent_writers":%s,"immutable_winner":true}\n' "$adapter" "$workers" "$successes" "$independent"
}
printf '{"platform":"%s","results":[' "$(uname -s)"
run_adapter json
printf ','
run_adapter sqlite
printf ']}\n'
