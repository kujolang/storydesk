# Security and authority

StoryDesk is local-first. State paths are explicit, record IDs reject traversal, record symlinks are refused, inputs are limited to 1 MiB, artifacts to 64 MiB, writes are atomic, and existing IDs are never overwritten. `--force` cannot bypass evidence, approval, authorization, or safety. Secrets must not enter records. Authority is OBSERVE/PROPOSE; only PressWire effect commands enter ACT with exact approval scope and `--act --yes`.

The optional SQLite adapter is bound in state metadata, uses parameterized queries and atomic record/audit transactions, and fails closed on uniqueness or lock contention. The database is local state, not a security boundary; protect its directory with operating-system access controls just as you would the default JSON records.

Export signing is opt-in. Private and public keys must be explicit regular, non-symlink files no larger than 1 MiB. Keys are never copied into state or output. Signature trust depends on obtaining the public key through a separate trusted channel; `--require-signature` rejects unsigned handoffs.

Transition policy and adapter fixtures are bounded, offline JSON inputs. Secret-shaped fields are rejected. Packet checkpoints bind their state, storage adapter, and type filter, use atomic replacement, and cannot be resumed against a different source.

JSON lock ownership uses atomic exclusive file publication inside the per-record lock directory; directory creation alone is not exclusive in Kujo. Record and audit publication also refuse replacement atomically. A process crash can leave a stale lock or a record without its history event: inspect state before manually removing a stale lock. Use SQLite when record/history crash atomicity is required. Protect state, output and checkpoint parent directories from concurrent hostile mutation; component checks do not provide a filesystem sandbox. System aliases such as macOS `/tmp` remain supported.

Version 1.0.0 signatures authenticate bundle contents, not the informational `integrity.signed_at`. No freshness or timestamp authority is granted by signature verification. Checkpoints are trusted local snapshots, not signed evidence; resume does not reauthenticate their accumulated records.

Integrity version 2 authenticates a domain-specific statement binding the
payload digest, key identity, algorithm, version, and exact signing time.
Require it explicitly with `--require-authenticated-time` when consuming time
claims. Version 1 compatibility remains available and clearly unauthenticated
for time. Current review projections are attributed status reports; neither
they nor successful history reconciliation confer ACT/publication authority.

Byte-bounded SQLite results prevent a 1,000-record page from materializing
1,000 near-1-MiB strings in Kujo. JSON directory enumeration uses the pinned
runtime's bounded heap, with bounded per-page parsing and diagnostic counts.
These are resource bounds for supported records, not a process-wide RSS cap
or hostile shared-directory isolation.
