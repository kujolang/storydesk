#!/usr/bin/env bash
# Same workload and runtime, separate processes, alternating revision order.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
OUT="${1:?qualification output directory required}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
work="$(mktemp -d)"
trap 'find "$work" -depth -delete' EXIT
mkdir -p "$work/before/scripts" "$work/after/scripts"
git -C "$ROOT" archive 558582243782ab178f647d7ccb362ed5b92c61cc src | tar -xf - -C "$work/before"
cp -R "$ROOT/src" "$work/after/src"
cp "$ROOT/scripts/query_benchmark.kujo" "$work/before/scripts/query_benchmark.kujo"
cp "$ROOT/scripts/query_benchmark.kujo" "$work/after/scripts/query_benchmark.kujo"
for adapter in json sqlite; do
  for size in small large; do
    count=1000; bytes=256
    if [[ "$size" == large ]]; then count=64; bytes=524288; fi
    state="$work/$adapter-$size"
    "$KUJO_RUNTIME" run "$ROOT/scripts/query_benchmark.kujo" -- seed "$state" "$count" "$bytes" "$adapter" > "$OUT/seed-$adapter-$size.json"
    # Warm each revision independently before timed samples.
    for revision in before after; do
      (cd "$work/$revision" && "$KUJO_RUNTIME" run scripts/query_benchmark.kujo -- scan "$state" "$count" "$bytes" "$adapter") > /dev/null
    done
    for sample in 1 2 3; do
      order='before after'; if [[ "$sample" == 2 ]]; then order='after before'; fi
      for revision in $order; do
        receipt="$OUT/$adapter-$size-$revision-$sample"
        if [[ "$(uname -s)" == Darwin ]]; then
          (cd "$work/$revision" && /usr/bin/time -l "$KUJO_RUNTIME" run scripts/query_benchmark.kujo -- scan "$state" "$count" "$bytes" "$adapter") > "$receipt.json" 2> "$receipt.time"
        else
          (cd "$work/$revision" && /usr/bin/time -v "$KUJO_RUNTIME" run scripts/query_benchmark.kujo -- scan "$state" "$count" "$bytes" "$adapter") > "$receipt.json" 2> "$receipt.time"
        fi
      done
    done
  done
done
"$KUJO_RUNTIME" run "$ROOT/scripts/qualification_verify.kujo" -- "$OUT"
printf 'Qualification evidence: %s\n' "$OUT"
