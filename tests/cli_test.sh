#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
tmp="$(mktemp -d)"
trap 'find "$tmp" -depth -delete' EXIT
"$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- --version --json > "$tmp/version.json"
"$KUJO_RUNTIME" run "$ROOT/scripts/validate_json.kujo" -- "$tmp/version.json"
expect_exit() {
  local expected="$1" actual=0
  shift
  "$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- "$@" > "$tmp/stdout" 2> "$tmp/stderr" || actual=$?
  if [[ "$actual" -ne "$expected" ]]; then printf 'expected exit %s, got %s\n' "$expected" "$actual" >&2; exit 1; fi
}
expect_exit 2 idea list --state
expect_exit 2 idea list --limit=
expect_exit 1 show --state "$tmp/state" --id idea-missing --json
"$KUJO_RUNTIME" run "$ROOT/scripts/validate_json.kujo" -- "$tmp/stdout"
printf 'CLI contract tests passed.\n'
