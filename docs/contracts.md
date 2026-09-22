# Contracts

Contract 1.0.0. StoryDesk currently creates Campaign, Idea, Editorial Brief, Assignment, Status Event, Handoff Record, and Daily Packet records. House Profile, Dependency, and a derived Review Queue Entry have no dedicated creation commands. `history` and `review-queue` are record listings, not reconstructed current-state or audit-event projections. Records carry schema/tool versions, stable IDs, actor, timestamp, provenance, command, and payload. Consumers accept compatible 1.x, preserve safe unknown payload metadata, and reject incompatible majors. JSON uses `ok/data/error/error_code/tool_version/contract_version`. Offline upstream fixtures identify repository, tag, schema, and checksum.

Storage adapters preserve the same immutable record document and checksum contract. State metadata binds a state directory to exactly one adapter. JSON is the portable baseline; SQLite is optional and uses a transaction to commit the immutable record and its unique append-only audit event together.

Transition policy 1.0.0 contains `policy_id` and a complete `transitions` object. Every destination must name another declared state, self-edges are invalid, and the active edge is enforced before persistence. Status records retain policy provenance.

Signed export integrity 1.0.0 signs the canonical JSON bundle without its `integrity` member using RSA-SHA256. The verifier checks key ID, algorithm and payload digest against the signed payload and trusted key. The legacy 1.0.0 `signed_at` field is unauthenticated informational metadata; never use it as proof of signing time or freshness. Verification reports `signed_at_authenticated: false`. Unsigned exports remain valid unless the consumer passes `--require-signature`.

Packet checkpoint 1.0.0 binds `state`, `storage_adapter`, `type`, the last record ID, page count, accumulated records, warnings, and completion state. Checkpoints are atomic and limited to 64 MiB; record traversal remains page-bounded to 1,000.

Identity and scheduling adapter fixtures use schema 1.0.0 and carry no credentials. Identity entries normalize subject, display name, provider, and roles. Scheduling entries normalize event/record IDs, ordered UTC times, and source timezone.

Full-state `validate` traverses every bounded query page; `doctor` remains a first-page diagnostic. Packet generation fails on storage warnings instead of saving an incomplete packet as complete. Resume validates ordered unique IDs, cursor consistency, page types, and the requested record ceiling.

Dry-run record commands validate and construct records without initializing or changing state. Missing/empty flag values are usage errors (exit 2). Native I/O failures at the CLI boundary emit `operation_failed` (exit 1); SQLite transaction failures are `write_failed` unless an existing record confirms `duplicate_id`.

## Bounded pages

Record list results retain `records`, `warnings`, and `truncated` and add
`next_after`, `document_bytes`, and `scanned`. Always pass `next_after` back as
`--after` when `truncated` is true, including empty filtered pages or pages of
warnings. A limit is an upper bound, not a promised page length. Query pages
retain at most 4 MiB of serialized documents, scan at most 1,000 candidates,
and emit at most 64 warnings. SQLite's one-row lookahead also stays inside the
same 4 MiB document budget. JSON retains at most 1,001 directory names at a
time; enumeration remains O(directory size), while parsing work and retained
names are bounded. JSON exposes `directory_entries_examined` and
`buffered_names` for inspection.

JSON preserves its filename ordering; SQLite uses record-ID ordering. These
differ for IDs such as `idea-a` and `idea-a-b`. Cursors are adapter-specific;
do not compare or transfer them between adapters. Packet checkpoints now carry
an additive `scan_after` cursor separate from the last retained record ID.
Older checkpoints without that field still resume from `after`.

The 1 MiB record and 8/64 MiB output/checkpoint ceilings count UTF-8 bytes,
not Unicode characters. Corrupt rows are reported and are never silently
skipped. Clients can page through warning-heavy listings; packet generation
and validation fail explicitly on unreadable source data.

## Authenticated signing time (integrity 2.0.0)

`export --signature-version 2.0.0` signs the canonical JSON statement:

```json
{
  "purpose": "storydesk.export",
  "schema_version": "2.0.0",
  "algorithm": "RSA-SHA256",
  "key_id": "<public-key identifier>",
  "signed_at": "<exact UTC timestamp>",
  "payload_sha256": "<SHA-256 of canonical bundle without integrity>"
}
```

Verification reports the version, signing time, and
`signed_at_authenticated: true`. It rejects timestamp edits, missing/invalid
time, unknown versions, content edits, and v2-to-v1 downgrade attempts. Use
`export verify --require-authenticated-time` to require this property;
`--require-signature` alone still permits v1 signatures. Existing API
`sign_export_bundle` and CLI exports default to v1 for legacy consumers.

An authenticated time is the signer's statement, not a trusted timestamp
service or proof of clock accuracy. Consumers decide acceptable age using the
verified timestamp and their own clock; StoryDesk does not grant publication
or approval authority from a signature.

## Explicit derived views

`review-queue current` projects status events by subject `record_id`. Greatest
normalized UTC timestamp wins, with event ID as a deterministic tie-breaker.
`block` reports `blocked`. Default review states are `technical_review`,
`editorial_review`, and `ready_for_review`; `--review-status` accepts a
comma-separated custom set. Results expose `reported_status`, the source event
ID/time, and subject-ID pagination. They describe operator-attributed reports,
not external approval. Out-of-order insertion is handled by event time; equal
timestamps do not imply causal precedence. Subjects may be external references.
The full reduction is bounded to 100,000 status events and 8 MiB of summary
metadata and fails explicitly if either ceiling is exceeded.

`history audit --id ID` returns the verified creation event for that record.
`history audit` reconciles every record with its deterministic event, actual
content checksum, actor and timestamp, then checks the event count to detect
orphan events. Missing/changed records, missing events, malformed events and
orphans fail explicitly. Run reconciliation against quiescent local state;
concurrent writers may cause a transient mismatch, so stop writers and repeat
rather than treating failure as permission to delete evidence. The command
is read-only and never repairs or fabricates history.

Legacy `review-queue` and `history` retain their original generic record
listings. The new commands are additive, and record/event storage schemas
remain unchanged.
