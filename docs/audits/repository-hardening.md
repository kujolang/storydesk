# StoryDesk repository hardening — 2026-09-22

## Repository and scope

- Repository: `kujolang/storydesk`; branch: `main`.
- Starting SHA: `e3707994b564c5b746493393c697424cc8503209` (clean tree).
- Ending implementation SHA: `d354bbde7a22899d5e0c383cc1295bc2b1b1db33` (storage commit `5163cec` plus validation/CLI commit `d354bbd`). The subsequent report commit changes documentation only; use `git log -1 --format=%H -- docs/audits/repository-hardening.md` to resolve that receipt revision.
- Purpose: offline editorial record CLI with immutable JSON records, optional SQLite, append-only creation events, transition policies, packet checkpoints, and optional RSA handoffs.
- Dependencies: Kujo builtins (filesystem, hashing, RSA, SQLite); POSIX launcher; Bash/OpenSSL for verification only. No application package-manager dependencies, hosted providers, network calls, model calls, MCP tools, prompt replay, or background worker service.
- Inspected all 12 source modules, entrypoint, launcher, tests, fixtures, schemas, verification/benchmark scripts, CI, documentation, ignore/release/package metadata. Reviewed actual filesystem builtin semantics in the adjacent Kujo source, including the pinned CI revision. No sibling repository was modified.
- Downstream contract checked: `kujo-workflows/publishing-house-operator/operator.py` uses `init`, `idea add`, `commission create`, explicit IDs/actors/JSON envelopes, and default JSON record paths. These remain supported. Other publishing tools were inspected only for comparison of lock implementations; their existing exclusive publication patterns do not require a coordinated change.

## Baseline

Local runtime reports `kujo 1.4.0`; adjacent source HEAD at inspection was `cf785c0a7953717af16b657cda05b85d628144c5`. This identifies source context, not a reproducible build attestation for the binary. Host: macOS. CI separately pins Kujo commit `5059695d14d6726bc17fef55e0b95511624967cf` and tests contention using release 1.0.1 on three operating systems.

Before edits, `bash scripts/validate.sh` passed: static entrypoint check; 52 assertions across five Kujo suites; generated test-key signing/tamper checks; JSON parsing of all fixtures/schemas; help/version/doctor smoke checks; foreign runtime/ignore/badge checks; whitespace check. Wall time: 54.95 s. No baseline functional failures.

`kujo run scripts/storage_benchmark.kujo -- 1000` completed correct record counts but exited 1 because the existing SQLite admission threshold was not met. Three full scans: JSON 43,427 ms, SQLite 32,882 ms. Its original integer division printed `sqlite_speedup: 1`; the ratio was about 1.32. This is a baseline benchmark failure, not an introduced functional failure. The historic 2x admission is a host-specific decision gate, not CI's runtime correctness gate.

Raw evidence is retained locally under ignored `.audit-evidence/`: baseline/final verification logs, storage measurements, contention receipts, CLI regressions, and finalized canonical baseline security artifacts. These artifacts are not required to operate the application.

## Findings

| ID | Priority | Area | Finding / evidence | Action | Status |
| --- | --- | --- | --- | --- | --- |
| SD-01 | P0 | Data integrity | `storage.acquire_lock` used check-then-idempotent `create_dir`; record/history writes allowed replacement. Kujo implements directory creation using `create_dir_all`. | Exclusive atomic owner file plus no-replace metadata/record/history publication; contention verifies audit winner and cleanup. | Fixed |
| SD-02 | P1 | Side effects | Record creation initialized state before input checks and dry-run return. | Validate first; read-only state checks; initialize only immediately before persistence. | Fixed |
| SD-03 | P1 | Validation | `validate` inspected only the first 1,000 records and could report valid despite later invalid records. | Traverse bounded pages; stop with failure on storage warnings. Test invalid record at position 1,006. | Fixed |
| SD-04 | P1 | Packet progress | Corrupt SQLite pages could be truncated with zero valid records, causing repeated queries/checkpoint growth. | Fail on source warnings/no progress; preserve the prior checkpoint. | Fixed |
| SD-05 | P1 | Resume | Completed checkpoint bypassed maximum; page type, ordered IDs and cursor consistency were unchecked. | Validate resume shape/order/filter/count/cursor before reuse. | Fixed |
| SD-06 | P1 | Storage errors | SQLite reads could create a missing DB; all failed transactions were labeled duplicate; list/export could succeed on database read failures. | Read paths require existing DB; fail storage errors; confirm duplicate IDs separately. | Fixed |
| SD-07 | P2 | Input/CLI | Missing flag values silently defaulted, huge integer conversion could overflow, config path types reached native functions, `--version` discarded `--json`. | Boundary checks, structured native failure envelope, preserve version arguments. | Fixed |
| SD-08 | P2 | Dates | Regex accepted impossible calendar dates; lexical timestamps mishandled optional UTC fractions. | Gregorian leap/day checks and normalized fractional comparison. | Fixed |
| SD-09 | P2 | Handoff trust | Signature 1.0.0 never authenticated `signed_at`, contrary to docs; arbitrary unsigned objects verified successfully. | Preserve signed bytes/version; clarify timestamp trust, add verification indicator, require basic bundle shape. | Contract corrected; authenticated timestamp protocol deferred |
| SD-10 | P2 | Output | Export existence precheck followed by replacement allowed racing output creation to be overwritten; stdout bypassed the output ceiling. | Atomic no-replace unless explicit force; 8 MiB applies to stdout and file exports. | Fixed |
| SD-11 | P2 | Efficiency | Mutation loaded/canonicalized the same policy twice; JSON listing recalculated unused checksums and rechecked the same state for every record; dead private helper/import. | Reuse loaded policy; validate listing root once, retain per-record safety/shape checks, hash only point reads; remove proven dead helper/import. | Implemented; no latency improvement claimed |
| SD-12 | P2 | Test resources | Kujo suites left UUID-scoped temporary state behind. | Shared recursive cleanup scoped to each test's exact UUID family, unlinking symlinks before traversal. | Fixed |
| SD-13 | P2 | Memory | SQLite query materializes up to 1,001 documents before packet byte budgeting; JSON listing sorts all filenames and can accumulate many warnings. | Add packet accumulation guard; preserve query contract. Measure and design byte-bounded query work separately. | Partial; open resource investigation |
| SD-14 | Needs evidence | Domain projections | `review-queue` currently shares generic listing; `history` lists records rather than an independently reconciled event projection. | Preserve established outputs. Define desired current-state/review semantics and downstream consumers before redesign. | Deferred contract question |

## Implemented changes and proof

### Immutable writes and publication

`src/storage.kujo` retains lock directories, including fail-closed behavior for stale directories, and publishes an exclusive `owner` file. A losing racer never releases another writer's lock. Metadata publication now checks a race winner for compatibility rather than replacing it. Record and history files refuse replacement at atomic publication. Ordinary history-write failure still rolls back this writer's record. `src/core.kujo` similarly respects export no-overwrite at publication; first packet checkpoint creation refuses replacement in `src/packets.kujo`.

`tests/contention_verify.kujo` extends the existing cross-platform contention gate with exact record/event counts, matching checksums/actors, and JSON lock cleanup. Final local 24-worker run: each adapter had one same-ID winner and 24 independent winners; all audits matched. No public record, event, ID, or storage layout change; lock directories gain an internal owner file.

### Validation and failure semantics

`src/core.kujo`, `src/args.kujo`, `src/common.kujo`, `src/storage_adapter.kujo`, and `src/storage_sqlite.kujo` implement SD-02/03/06/07. Record validation also rejects read-command records, incorrect ID prefixes, incompatible payload schema types, and secret-shaped payload fields. Existing legacy record fixture validation remains enabled. Native CLI failures retain their actual diagnostic inside the stable error envelope rather than reporting an unstructured VM exception.

`tests/hardening_test.kujo` covers side-effect-free successful/invalid dry runs on both adapters, unsafe dry-run paths, flag values, integer overflow, malformed config types, nonexistent SQLite reads, corrupt packet progress, invalid resume shape/cursor/count, invalid unsigned bundles, calendar dates and fractional UTC comparison. `tests/enhancements_test.kujo` reuses its existing 1,005-record fixture to prove validation reaches the later invalid record. `tests/cli_test.sh` checks JSON version output and exact usage/operational exit codes. `scripts/validate.sh` runs the new suites and exports its resolved Kujo runtime so child signing/CLI tests use the same executable.

`src/domain.kujo` shares calendar validation with `src/common.kujo`; `src/integrations.kujo` compares normalized UTC timestamps. Valid input representations remain unchanged. Invalid historical calendar dates now fail validation intentionally.

### Packet and signature contracts

`src/packets.kujo` rejects corrupt pages and malformed checkpoints before advancing persistent state. It checks accumulated serialized record bytes before adding more records, retaining the final complete-checkpoint size check. Checkpoints remain trusted snapshots; their records are not authenticated against source state on resume, and concurrent writers to the same existing checkpoint remain an operator coordination responsibility.

`src/bundles.kujo` validates the minimal StoryDesk bundle shape and reports `signed_at_authenticated: false` for existing signatures. Record content/key verification remains unchanged. `docs/contracts.md`, `docs/security.md`, and README now describe these guarantees precisely. `schemas/record.schema.json` requires the contract version already emitted and checked by runtime; `SECURITY.md` names the current 0.3.x maintenance line.

## Performance and efficiency

| Dimension | Before | After / interpretation |
| --- | --- | --- |
| Three scans, 1,000 JSON records | 43,427 ms | 66,706 ms in exploratory run |
| Three scans, 1,000 SQLite records | 32,882 ms | 18,360 ms in exploratory run |
| SQLite ratio display | Integer-truncated 1 | Accurate floating ratio 3.6332 in after run |
| Policy loading per mutation | 2 | 1; source-established elimination of duplicate parsing/hash work |
| JSON checksum calculations during list | Every successfully parsed candidate | None; listing never returned these checksums. Point reads still hash. |
| Full-state validation coverage | At most 1,000 records | All pages until completion or explicit storage failure; regression checks 1,006 |
| Normal completed test state | Left behind | UUID-scoped cleanup |
| Application dependencies | Kujo only | Unchanged |
| Agent instructions | 432 bytes | Unchanged; no prompt/MCP/provider surfaces requiring token budgets |

Timing samples were collected on a shared, actively loaded development host; other repository workloads were observed. They do **not** establish a speedup or statistically attributable regression. The JSON elapsed increase is disclosed rather than hidden. No cache, safety bypass, wall-clock CI budget, or dependency substitution was added. Retained listing changes remove demonstrably redundant operations without changing returned records. Peak RSS and tokenizer-specific token counts were not measured; no such savings are claimed.

Output remains the established envelope and pretty JSON. File exports provide concise path/byte/hash receipts while preserving full evidence. Stdout export now obeys the same 8 MiB limit. Full listing/query memory is not constrained by that serialized-output limit; SD-13 remains open. Test/benchmark logs remain artifacts instead of agent context.

## Security and state review

Reviewed explicit input/config/policy/key/artifact/bundle/checkpoint boundaries, schema and secret-key validation, path/ID/symlink guards, SQL parameter binding, immutable triggers, transaction ownership, atomic files, error cleanup, actor attribution, and OBSERVE/PROPOSE authority. No production shell execution or network publication path exists. RSA keys remain explicit trusted files; test keys are ephemeral. CI uses read-only repository permissions and pinned checkout/toolchain/runtime sources; contention release binaries are checksum checked. The upload-artifact action remains on its upstream major tag; no new dependency was introduced.

Independent baseline source audit and architecture review completed. Canonical baseline security artifact reports one low-severity unauthenticated-signing-time contract issue, now disclosed accurately without breaking existing signatures. Its source-only/dependency coverage limits remain explicit; it is not a claim of post-fix exploit certification. Daybreak advisory: granted, Daybreak Blue.

JSON record/history writes are individually atomic, not a single crash-atomic transaction. A killed process may leave an orphan record or stale lock; do not auto-retry by deleting evidence blindly. SQLite supplies the stronger record/history transaction. State and parent paths are operator-controlled, not a tenant sandbox; ancestor replacement/TOCTOU and OS aliases are not solved by leaf checks. This pass does not claim hostile shared-directory confinement, remote identity, or distributed scheduling.

## Compatibility

- Public command names, supported 0.1.0/0.2.0/0.3.0 record versions, IDs, payload serialization, database schema, and signature payload format are preserved.
- CLI fixes: missing/empty flag values exit 2; `--version --json` actually emits JSON; validated/native operational failures exit 1. Valid record dry runs no longer create state. Invalid calendar dates and malformed checkpoints/config/bundles fail intentionally.
- `validate` scans beyond the old page cap. Corrupt packet sources and failed SQLite listings/exports return failure instead of incomplete success. Non-duplicate SQLite transaction failures use `write_failed`.
- Verification output adds `signed_at_authenticated: false`; no existing field is removed. Existing signatures still verify. This is not timestamp authentication.
- Record schema now requires existing `contract_version`. No config key, environment variable, public record/event/checkpoint format, or runtime minimum is changed. Optional imported helper additions are additive.
- Export stdout shares the existing file-output byte ceiling. Consumers depending on previously unbounded stdout must page exports or lower packet size.
- Known Publishing House operator calls and file reads remain compatible; no coordinated migration required. Other uninspected consumers may need to handle the corrected failure codes and stricter invalid-input rejection.

## Remaining work

- P0/P1: no known introduced defect; no unresolved externally exploitable P0/P1 finding established.
- P2: measure large-record peak RSS and design byte-bounded SQLite paging; bound pathological JSON warning/work accumulation without silently losing diagnostics. SignalBox capture `cap_30f6f4e7-a1d2-4cd2-8bc8-a77d469fafd4` preserves this source-backed resource question (not a measured allocation claim).
- P2: a future, explicitly versioned signature statement could authenticate signing time if consumers require freshness. Existing metadata must not be treated as authenticated.
- Needs more evidence: review/history projection semantics; repeat performance qualification on an isolated target host; verify full platform matrix in hosted CI. The local run does not assert Windows/Linux results.
- Not worth changing in this pass: broad stylistic rewrites, CLI/profile abstractions used by established contracts, dependency-free architecture, existing pretty-output format, trusted-root filesystem aliases.
- Cross-repository follow-ups: none required for these changes. Any future streaming primitive proposal must first establish a measured need and compatibility contract; no sibling implementation was silently assumed.

## Verification receipt

Commands ran from the repository root unless specified. Detailed outputs are in `.audit-evidence/`.

| Command | Result |
| --- | --- |
| `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/test.kujo` | Passed, 13 assertions (also part of full gate) |
| `bash scripts/validate.sh` before edits | Passed; 52 assertions plus signing/JSON/CLI checks |
| `../kujo/target/release/kujo run scripts/storage_benchmark.kujo -- 1000` before edits | Exit 1: correct counts, existing 2x admission unmet |
| Same storage benchmark after listing changes | Passed admission, ratio 3.6332; uncontrolled timings, no causal speed claim |
| `../kujo/target/release/kujo check storydesk.kujo` | Passed after implementation |
| `../kujo/target/release/kujo run tests/hardening_test.kujo` | Passed, 20 assertions |
| `bash tests/cli_test.sh` | Passed JSON and exit-code contracts |
| `bash scripts/contention_benchmark.sh 24` | Passed both adapters; checksum/actor/count/lock checks included |
| `bash -n scripts/*.sh tests/signing_test.sh`; `sh -n bin/storydesk` | Passed shell parsing |
| `git diff --check` | Passed |
| Final `bash scripts/validate.sh` | Passed on committed implementation: 74 assertions, signing/tamper, JSON fixtures/schemas, CLI contracts and existing repository gates; 75.88 s wall time |

The early exploratory edited run caught a missing-path error from calling `path_is_symlink` without an existence guard. It was corrected before verification; the failed exploratory contention log is retained. An overlapping intermediate full run was stopped to avoid wasting resources; it is not counted as a passing receipt. No test was disabled, assertion weakened, timeout increased, or failure marked expected to pass the gate.

## Durable handoff

Strata CONSOLIDATE saved one project-scoped handoff/state-timeline milestone in Agent Notes: `6460500e-4535-4a87-b078-9fd2140c1f12`. It contains implementation commits, verification evidence references, compatibility/security caveats, and the next investigation. Exact-ID and conceptual retrieval passed; prior release/worklist memories were linked, not duplicated or overwritten.

SignalBox saved one unresolved resource investigation: Capture `cap_30f6f4e7-a1d2-4cd2-8bc8-a77d469fafd4` (StoryDesk SQLite packet buffering). No Signals were created. Exact-ID and concept retrieval passed. The existing, corrected lock finding was skipped as resolved; routine implementation summaries and test results were rejected as captures and kept in this report/Strata.
