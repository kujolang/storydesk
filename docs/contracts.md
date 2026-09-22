# Contracts

Contract 1.0.0. StoryDesk owns: House Profile; Campaign; Idea; Editorial Brief; Assignment; Dependency; Status Event; Handoff Record; Daily Packet; Review Queue Entry. Records carry schema/tool versions, stable IDs, actor, timestamp, provenance, command, and payload. Consumers accept compatible 1.x, preserve safe unknown payload metadata, and reject incompatible majors. JSON uses `ok/data/error/error_code/tool_version/contract_version`. Offline upstream fixtures identify repository, tag, schema, and checksum.

Storage adapters preserve the same immutable record document and checksum contract. State metadata binds a state directory to exactly one adapter. JSON is the portable baseline; SQLite is optional and uses a transaction to commit the immutable record and its unique append-only audit event together.

Transition policy 1.0.0 contains `policy_id` and a complete `transitions` object. Every destination must name another declared state, self-edges are invalid, and the active edge is enforced before persistence. Status records retain policy provenance.

Signed export integrity 1.0.0 signs the canonical JSON bundle without its `integrity` member using RSA-SHA256. The verifier checks key ID, algorithm and payload digest against the signed payload and trusted key. The legacy 1.0.0 `signed_at` field is unauthenticated informational metadata; never use it as proof of signing time or freshness. Verification reports `signed_at_authenticated: false`. Unsigned exports remain valid unless the consumer passes `--require-signature`.

Packet checkpoint 1.0.0 binds `state`, `storage_adapter`, `type`, the last record ID, page count, accumulated records, warnings, and completion state. Checkpoints are atomic and limited to 64 MiB; record traversal remains page-bounded to 1,000.

Identity and scheduling adapter fixtures use schema 1.0.0 and carry no credentials. Identity entries normalize subject, display name, provider, and roles. Scheduling entries normalize event/record IDs, ordered UTC times, and source timezone.

Full-state `validate` traverses every bounded query page; `doctor` remains a first-page diagnostic. Packet generation fails on storage warnings instead of saving an incomplete packet as complete. Resume validates ordered unique IDs, cursor consistency, page types, and the requested record ceiling.

Dry-run record commands validate and construct records without initializing or changing state. Missing/empty flag values are usage errors (exit 2). Native I/O failures at the CLI boundary emit `operation_failed` (exit 1); SQLite transaction failures are `write_failed` unless an existing record confirms `duplicate_id`.
