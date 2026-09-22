# StoryDesk hardening follow-ups — 2026-09-22

Starting revision: `558582243782ab178f647d7ccb362ed5b92c61cc`, clean `main`.
Ending implementation revision: `bc9025b09f6335a18daf20e0448fcf3dc8fc9aee`; the
closure commit adds only this report, its receipt and runtime documentation.
This report closes the concrete follow-ups in the earlier hardening report;
it does not expand the application into a hosted, distributed, or publishing
service.

## Requirements and implementation

| Requirement | Implementation | Proof / status |
| --- | --- | --- |
| Bound SQLite page documents and measure peak RSS | SQL window budget prevents document materialization above 4 MiB; individual records above 1 MiB become warnings; 64-warning cap with continuation | Multibyte paging tests; paired RSS/latency qualification |
| Bound JSON warning/work accumulation | Native bounded-name paging (1,001 names), 1,000 inspected candidates, 4 MiB documents and 64 warnings per page; expose scan cursor independently of valid records | Corrupt and sparse-page fixtures; prefix-ID/resume regression; native enumeration remains linear per page but memory/sorting are bounded |
| Authenticate signing time compatibly | Opt-in integrity 2.0.0 signs a domain-specific statement; legacy 1.0.0 still verifies; explicit authenticated-time verification policy | Both versions, timestamp/content/version tampering, downgrade and CLI-policy tests |
| Define and implement review/history views | Add `review-queue current` and `history audit`; preserve legacy list commands | Both adapters: latest-event reduction, UTC fraction tie-break, custom states, valid audit, orphan event and missing/changed record tests |
| Repeat performance qualification on an isolated target | Same seeded states, pinned runtime and benchmark source; warmups, three alternating before/after pairs for each workload/adapter | Local evidence recorded; hosted Ubuntu qualification attached to final CI run |
| Verify platform matrix | Full suite plus 24-writer checksum/actor/count contention on Linux/macOS/Windows, same pinned runtime | Hosted run receipt recorded below |

## Change boundaries

| Files | Root cause and change | Regression evidence |
| --- | --- | --- |
| `src/storage_sqlite.kujo`, `src/storage.kujo`, `src/common.kujo` | Count-only pages allowed large document buffers; JSON enumerated/sorted all filenames and accumulated warnings. Bound document bytes, names, candidates and diagnostics, expose continuation, and count UTF-8 bytes rather than characters. | `tests/paging_test.kujo`; paired qualification |
| `src/packets.kujo`, `src/core.kujo` | Last-valid-record cursors cannot represent sparse or corrupt bounded pages. Preserve record cursor and add independent scan continuation, with adapter-specific ordering and progress validation. | Empty filtered pages, prefix IDs, resume and malformed-name CLI paging tests |
| `src/bundles.kujo`, `schemas/export-integrity.schema.json`, CLI/profile code | Legacy signatures omitted signing time from signed bytes. Opt-in v2 authenticates a domain-specific statement and adds a strict verifier policy while retaining v1. | `tests/signature_versions_test.kujo`, `tests/signing_test.sh` |
| `src/projections.kujo`, `schemas/review-queue.schema.json`, CLI/profile code | Generic listings did not define a current review queue or reconcile record/history integrity. Add explicit bounded read models and verify actual record checksums. | `tests/projections_test.kujo`, both adapters |
| `.github/workflows/validate.yml`, `scripts/qualification*.kujo`, `scripts/qualification.sh`, `scripts/query_benchmark.kujo` | Shared-host timing did not establish isolated behavior/RSS, and the old runtime lacked native bounded directory paging. Pin the capable runtime and run full platform gates with retained receipts. | Hosted matrix, 12 paired equivalence/budget checks; timings remain evidence rather than admission thresholds |
| `README.md`, `docs/contracts.md`, `docs/runtime.md`, `docs/security.md` | New runtime, cursor and signing semantics need an explicit consumer contract. Document compatibility, installation and authority limits. | Checked against implemented commands and tests |

## Compatibility and runtime decision

Record/event schemas and versions are unchanged. Integrity v2 is opt-in; v1
signatures and the original signing helper remain supported. Existing generic
list commands remain available; new read models are explicit commands. Lists
may return fewer records than `--limit` due to their byte/work budget. Continue
with `next_after`, not the last valid record. Packet checkpoints add an optional
`scan_after`; old checkpoints still read from `after`. JSON filename and SQLite
ID ordering are preserved, including prefix-ID edge cases.

The existing Kujo bounded-directory primitive is newer than the previously
pinned runtime. CI and installation docs now pin the already-published source
revision `cf785c0a7953717af16b657cda05b85d628144c5`; no sibling modification or
new primitive is required. Released 1.4.0 binaries are not sufficient. This
explicit runtime upgrade avoids an unbounded fallback and does not migrate
user data. The upload-artifact action is also pinned to its verified v4 commit.

UTF-8 byte ceilings now use `byte_length`; the old string `len` counted Unicode
characters. Emoji fixtures prove oversized serialized records are rejected and
pages stay inside their byte budget. Actual SQLite content is hashed on point
reads rather than trusting its stored checksum, which makes reconciliation
independent of altered database metadata.

## Local evidence

`tests/paging_test.kujo`: 28 checks. `tests/projections_test.kujo`: 24 checks.
`tests/signature_versions_test.kujo`: 12 checks plus CLI authenticated-time
policy. The preexisting 74 assertions remain enabled.

Paired qualification uses 1,000 small records (256-byte payload) and 64 large
records (512-KiB payload), both JSON and SQLite. Separate processes use the
same seeded state, binary and benchmark driver; order alternates across three
samples after warmup. Every pair checks total records, payload bytes and the
ordered ID digest. Runtime timings are evidence, not a flaky CI gate; byte
budgets and equivalence are hard assertions.

Exploratory local large-SQLite median RSS: 83,496,960 → 57,237,504 bytes; scan
latency 437 → 1,008 ms. Large-JSON median RSS: 51,089,408 → 50,892,800 bytes;
latency 597 → 690 ms. Maximum large page document bytes: 33,561,408 → 3,670,779
for both adapters. These local samples were collected on a shared host and
are not marketed as an isolated speedup. The memory/round-trip tradeoff is
explicit; hosted qualification supplies the isolated result.

Local raw evidence: `.audit-evidence/followups/qualification/` (24 process
measurements and resource receipts). `scripts/qualification_verify.kujo`
verified all 12 pairs. Temporary benchmark states are cleaned on exit.

## Isolated hosted qualification

Ubuntu run [35774362268](https://github.com/kujolang/storydesk/actions/runs/35774362268),
implementation `8a2382f8031cbae3f34e7975913ee60c819ce5f5`, Linux artifact
`10716321064`. Three-sample medians; RSS is measured per process, converted
from Linux `time -v` KiB to bytes. Source baseline and runtime are pinned in
the [machine-readable receipt](followups-2026-09-22.receipt.json), which retains
all latency/RSS samples. Later fixture/cache changes at `bc9025b` preserve
application tree `dbbf75f2424240812cd14b4f669ca970d4d55ad9` and all benchmark
scripts, so these measurements apply to the final application source.
The runner is isolated from the development host;
shared physical-host effects in hosted infrastructure are not controlled.

| Adapter / workload | Scan latency ms, before → after | Peak RSS bytes, before → after | Maximum page document bytes, before → after |
| --- | ---: | ---: | ---: |
| json / small | 962 → 955 | 35,549,184 → 35,803,136 | 365,000 → 365,000 |
| json / large | 105 → 121 | 58,888,192 → 58,732,544 | 33,561,408 → 3,670,779 |
| sqlite / small | 716 → 792 | 36,884,480 → 37,883,904 | 365,000 → 365,000 |
| sqlite / large | 114 → 233 | 92,721,152 → 66,695,168 | 33,561,408 → 3,670,779 |

All 12 pairs preserved record count, payload byte count and ordered ID digest.
Large pages fell from 33,561,408 to 3,670,779 serialized bytes. The largest
measured memory improvement is SQLite's large-record workload; JSON peak RSS
is effectively unchanged. Bounded pages require more queries/reads, and the
SQLite latency increase is an accepted, measured resource-bound tradeoff.
No general runtime speedup, token saving, or dependency-count reduction is claimed.
JSON continuation re-enumerates the directory per page; it bounds retained names
and parsed candidates, not total directory enumeration work. No cache or index
with an unproven invalidation contract was introduced.

## Verification commands

- `bash scripts/validate.sh`: passed on implementation revision `13f3859c2da4c419643be040e705e6184f498116`; 137 checks plus signing, authenticated-time CLI policy, CLI contracts and fixture/schema gates. Evidence: `.audit-evidence/followups/final-validation.log`.
- `bash scripts/contention_benchmark.sh 24`: passed locally for JSON and SQLite, including record/event checksums, one shared-ID winner and 24 independent records. Evidence: `.audit-evidence/followups/contention.log`.
- `bash scripts/qualification.sh .audit-evidence/followups/qualification`: passed all 12 paired behavior and page-byte assertions; measurements above.
- `bash scripts/validate.sh` after the handle-release fix: passed all 138 local checks and supporting gates; `.audit-evidence/followups/handle-release-validation.log`.
- `kujo run .audit-evidence/followups/db-close-fd-repro.kujo`: confirmed native descriptor retention after close and release after dropping the reference. The error-path variant repeats this after a rejected immutable-record update.
- `git diff --check`: passed.
- Hosted matrix executes the full validation and 24-writer contention commands on all three operating systems, plus `bash scripts/qualification.sh qualification` on Ubuntu. Runtime build: `cargo build --locked --release --manifest-path .runtime/kujo/Cargo.toml`.

The subsequent test-only commit `8a2382f8031cbae3f34e7975913ee60c819ce5f5`
replaces the tab-containing filename fixture with a portable space-containing
filename and separately asserts control-character cursor acceptance. Its
28 paging checks pass locally, bringing the full suite total to 138; no
assertion or application behavior was removed.

## CI diagnostics retained

The first expanded matrix (`35773079541`) passed on Ubuntu and macOS but
failed before StoryDesk tests on Windows: Git Bash selected an incomplete
MSYS Perl for vendored OpenSSL. The Windows build now uses PowerShell,
selects native Strawberry Perl, and explicitly checks `IPC::Cmd` before the
unchanged locked runtime build. Superseded runs `35773336751` and
`35773571157` were cancelled after their replacement was pushed; they are not
counted as passing evidence. The portable filename fixture is a separate test
correction, not an expected-failure marker or disabled assertion.

## Cross-repository finding: Kujo database lifetime

Kujo `cf785c0a7953717af16b657cda05b85d628144c5`,
`src/interpreter/native_functions/database.rs:655–665`, returns true from
`db_close` without closing or invalidating retained values. The minimal local
reproduction reports `close_acknowledged=true` and
`query_after_close_succeeded=true`. A separate local `lsof` check confirmed
an open file descriptor after `db_close` and no open descriptor after assigning
the fixture reference to `null`; evidence is
`.audit-evidence/followups/db-close-fd-repro.json`. Windows run `35774362268`, job
`106903671177`, compiled successfully, then failed removing the enhancements
SQLite fixture with OS error 32. Linux and macOS passed that revision because
they permit unlinking open files; this was not proof of connection release.

StoryDesk commit `5b0d5b7` explicitly drops raw fixture references after close,
including paging, projection, hardening and contention fixtures. It keeps
cleanup strict and adds no sleeps, retries or expected failures. Production
storage connections already have function-scoped lifetimes. The upstream
recommendation is to define shared-alias close semantics, implement deterministic
release or document the actual lifetime contract, and test use-after-close and
Windows deletion. No sibling modification is required for the local mitigation.
Compatibility review belongs in Kujo before changing retained-alias behavior.

SignalBox: one new `kujo` Capture
`cap_577d2146-0936-4914-81c4-dcf148932afc` and human-review Signal
`sig_04137ebf-47a7-4785-b7f8-caf45906699c`. Exact-ID and retained-handle concept
retrieval passed. No duplicate close finding existed. Completed paging work,
routine validation and cancelled-run status were rejected as Captures; the
prior resource Capture is referenced as resolved in the Strata handoff without
automatically dispositioning SignalBox history.

CI now caches successful pinned runtime builds independently of test outcome.
Keys include OS, architecture, source SHA and compiler fingerprint; no partial
restores or test skipping are used. This follows a measured 25m29s cold Windows
runtime build, not a speculative optimization. The cache action is pinned to
verified Node 24 revision `caa296126883cff596d87d8935842f9db880ef25`.

## Final verification and closure

Hosted run [35777519206](https://github.com/kujolang/storydesk/actions/runs/35777519206)
completed successfully for ending implementation revision `bc9025b`:

| Platform | Full suite | Contention | Artifact |
| --- | --- | --- | --- |
| Linux | 138 checks plus signing, CLI and schema gates | 24 workers, both adapters, one collision winner, verified immutable records/events | `10717536985` |
| macOS | 138 checks plus supporting gates | Same checks passed | `10717222287` |
| Windows | 136 checks plus supporting gates | Same checks passed | `10717409627` |

The two-count Windows difference comes from existing symlink tests conditioned
on successful native link creation. No assertion was weakened or removed.
Linux also passed all 12 paired qualification cases again. All three successful
runtime builds were cached; subsequent runs still execute the complete suite.
Raw final artifacts are retained in `.audit-evidence/followups/hosted-*-handles/`.
The checked-in receipt preserves platform/job/artifact IDs, contention results,
source hashes and measurement samples. Its JSON validation and `git diff --check`
passed before the closure commit.

Remaining work: no known introduced StoryDesk regression or repository blocker.
The sole new P2 cross-repository item is Kujo's retained-handle close contract,
recorded above; the tested local mitigation does not depend on an upstream fix.
The earlier byte-bounding, authenticated-time, projection, isolated-measurement
and platform-verification follow-ups are complete. Broad cosmetic rewrites
remain not worth changing.

Architectural limits remain explicit: JSON files are
individually atomic, parent paths are operator-controlled, audit reconciliation
requires quiescent state, signing time is the signer's statement rather than a
trusted timestamp service, and review reports do not grant publication authority.
