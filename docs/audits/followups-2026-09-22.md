# StoryDesk hardening follow-ups — 2026-09-22

Starting revision: `558582243782ab178f647d7ccb362ed5b92c61cc`, clean `main`.
This report closes the concrete follow-ups in the earlier hardening report;
it does not expand the application into a hosted, distributed, or publishing
service.

## Requirements and implementation

| Requirement | Implementation | Proof / status |
| --- | --- | --- |
| Bound SQLite page documents and measure peak RSS | SQL window budget prevents document materialization above 4 MiB; individual records above 1 MiB become warnings; 64-warning cap with continuation | Multibyte paging tests; paired RSS/latency qualification |
| Bound JSON warning/work accumulation | Native bounded-name paging (1,001 names), 1,000 inspected candidates, 4 MiB documents and 64 warnings per page; expose scan cursor independently of valid records | Corrupt and sparse-page fixtures; prefix-ID/resume regression; native enumeration remains linear but memory/sorting are bounded |
| Authenticate signing time compatibly | Opt-in integrity 2.0.0 signs a domain-specific statement; legacy 1.0.0 still verifies; explicit authenticated-time verification policy | Both versions, timestamp/content/version tampering, downgrade and CLI-policy tests |
| Define and implement review/history views | Add `review-queue current` and `history audit`; preserve legacy list commands | Both adapters: latest-event reduction, UTC fraction tie-break, custom states, valid audit, orphan event and missing/changed record tests |
| Repeat performance qualification on an isolated target | Same seeded states, pinned runtime and benchmark source; warmups, three alternating before/after pairs for each workload/adapter | Local evidence recorded; hosted Ubuntu qualification attached to final CI run |
| Verify platform matrix | Full suite plus 24-writer checksum/actor/count contention on Linux/macOS/Windows, same pinned runtime | Hosted run receipt recorded below |

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

`tests/paging_test.kujo`: 26 checks. `tests/projections_test.kujo`: 24 checks.
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

## Final verification and closure

Pending final committed-source/platform receipts; no completion claim until
those are inspected. Architectural limits remain explicit: JSON files are
individually atomic, parent paths are operator-controlled, audit reconciliation
requires quiescent state, signing time is the signer's statement rather than a
trusted timestamp service, and review reports do not grant publication authority.
