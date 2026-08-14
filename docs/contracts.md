# Contracts

Contract 1.0.0. StoryDesk owns: House Profile; Campaign; Idea; Editorial Brief; Assignment; Dependency; Status Event; Handoff Record; Daily Packet; Review Queue Entry. Records carry schema/tool versions, stable IDs, actor, timestamp, provenance, command, and payload. Consumers accept compatible 1.x, preserve safe unknown payload metadata, and reject incompatible majors. JSON uses `ok/data/error/error_code/tool_version/contract_version`. Offline upstream fixtures identify repository, tag, schema, and checksum.

Storage adapters preserve the same immutable record document and checksum contract. State metadata binds a state directory to exactly one adapter. JSON is the portable baseline; SQLite is optional and uses a transaction to commit the immutable record and its unique append-only audit event together.

Transition policy 1.0.0 contains `policy_id` and a complete `transitions` object. Every destination must name another declared state, self-edges are invalid, and the active edge is enforced before persistence. Status records retain policy provenance.

Signed export integrity 1.0.0 signs the canonical JSON bundle without its `integrity` member using RSA-SHA256. The envelope binds the key ID, signing time, payload digest, and signature. Unsigned exports remain valid unless the consumer passes `--require-signature`.

Packet checkpoint 1.0.0 binds `state`, `storage_adapter`, `type`, the last record ID, page count, accumulated records, warnings, and completion state. Checkpoints are atomic and limited to 64 MiB; record traversal remains page-bounded to 1,000.

Identity and scheduling adapter fixtures use schema 1.0.0 and carry no credentials. Identity entries normalize subject, display name, provider, and roles. Scheduling entries normalize event/record IDs, ordered UTC times, and source timezone.
