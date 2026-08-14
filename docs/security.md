# Security and authority

StoryDesk is local-first. State paths are explicit, record IDs reject traversal, record symlinks are refused, inputs are limited to 1 MiB, artifacts to 64 MiB, writes are atomic, and existing IDs are never overwritten. `--force` cannot bypass evidence, approval, authorization, or safety. Secrets must not enter records. Authority is OBSERVE/PROPOSE; only PressWire effect commands enter ACT with exact approval scope and `--act --yes`.

The optional SQLite adapter is bound in state metadata, uses parameterized queries and atomic record/audit transactions, and fails closed on uniqueness or lock contention. The database is local state, not a security boundary; protect its directory with operating-system access controls just as you would the default JSON records.

Export signing is opt-in. Private and public keys must be explicit regular, non-symlink files no larger than 1 MiB. Keys are never copied into state or output. Signature trust depends on obtaining the public key through a separate trusted channel; `--require-signature` rejects unsigned handoffs.

Transition policy and adapter fixtures are bounded, offline JSON inputs. Secret-shaped fields are rejected. Packet checkpoints bind their state, storage adapter, and type filter, use atomic replacement, and cannot be resumed against a different source.
