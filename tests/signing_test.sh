#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
tmp="$(mktemp -d)"
trap 'find "$tmp" -depth -delete' EXIT
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$tmp/private.pem" >/dev/null 2>&1
openssl pkey -in "$tmp/private.pem" -pubout -out "$tmp/public.pem" >/dev/null 2>&1
"$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- idea add --state "$tmp/state" --input "$ROOT/fixtures/core.json" --actor fixture --timestamp 2026-08-14T10:03:00Z --json >/dev/null
"$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- export --state "$tmp/state" --private-key "$tmp/private.pem" --public-key "$tmp/public.pem" --timestamp 2026-08-14T10:04:00Z --output "$tmp/signed.json" --json >/dev/null
"$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- export verify --input "$tmp/signed.json" --public-key "$tmp/public.pem" --require-signature --json >/dev/null
sed 's/Portable editorial workflow/Tampered editorial workflow/' "$tmp/signed.json" > "$tmp/tampered.json"
if "$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- export verify --input "$tmp/tampered.json" --public-key "$tmp/public.pem" --require-signature --json >/dev/null 2>&1; then
  printf 'tampered signed export unexpectedly verified\n' >&2
  exit 1
fi
printf 'signed export tests passed.\n'
