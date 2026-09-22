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
"$KUJO_RUNTIME" run "$ROOT/tests/signature_versions_test.kujo" -- "$tmp/private.pem" "$tmp/public.pem" "$tmp/versions.json"
printf 'signed export tests passed.\n'

if "$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- export verify --input "$tmp/signed.json" --public-key "$tmp/public.pem" --require-authenticated-time --json >/dev/null 2>&1; then
  printf 'legacy signature unexpectedly met authenticated-time requirement\n' >&2; exit 1
fi
"$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- export --state "$tmp/state" --private-key "$tmp/private.pem" --public-key "$tmp/public.pem" --signature-version 2.0.0 --timestamp 2026-09-22T12:00:00Z --output "$tmp/v2.json" --json >/dev/null
"$KUJO_RUNTIME" run "$ROOT/storydesk.kujo" -- export verify --input "$tmp/v2.json" --public-key "$tmp/public.pem" --require-authenticated-time --json >/dev/null
printf 'authenticated-time CLI policy passed.\n'
