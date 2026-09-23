# Native database lifetime follow-up — 2026-09-23

Repository: `kujolang/storydesk`, branch `main`.
Starting SHA: `ad98ef50c3aa6e3c4fc05cc6dfb6fc74fcef169a`.
Ending implementation SHA: `d3bd1e97bcc90bce2ab2b5838c96b54dadac63ef`.
The audit receipt is committed separately. This completes the upstream resource
ownership follow-up from the September 22 hardening report.

## Why the mitigation existed

Kujo's `db_close` returned true without closing its native connection. A retained
fixture variable therefore kept SQLite open. Windows correctly rejected cleanup
of that file with OS error 32. StoryDesk temporarily cleared those references
because the original audit's write scope excluded sibling repositories.

The user explicitly authorized fixing Kujo itself. Its shared handles now close
native resources, invalidate all aliases, roll back uncommitted work, and reject
use after close. Returned pool leases cannot affect later borrowers. Related live
provider checks also corrected MySQL executor lifetime and transaction protocol,
async PostgreSQL initialization, and the type checker's missing registration for
an existing database builtin. See [Kujo's detailed audit](https://github.com/kujolang/kujo/blob/main/docs/audits/database-lifecycle-2026-09-22.md)
and [the pinned lifetime contract](https://github.com/kujolang/kujo/blob/58c087b5d7af2a05d5d9fd2ad26a5a533044c5f6/docs/DATABASE_LIFECYCLE.md).

## Changes

| ID | Priority | Evidence / finding | Action | Status |
|---|---|---|---|---|
| SD-DB-01 | P1 | Retained aliases prevented native release on the old runtime. | Pin Kujo `58c087b5d7af2a05d5d9fd2ad26a5a533044c5f6`; remove every `db = null` fixture workaround. | Implemented |
| SD-DB-02 | P1 | Application tests previously exercised reference clearing rather than native close. | Keep immutable aliases alive, require query rejection and repeated-close success, and delete SQLite immediately. Four regression checks. | Implemented |
| SD-DB-03 | P2 | Runtime documentation and CLI receipts still advertised the old revision. | Update README, runtime guide, CI pin and version/doctor metadata together. | Implemented |

Affected fixtures: enhancements, hardening, paging, projections and contention;
shared cleanup no longer instructs callers to clear database references. Native
close is used directly, with no fallback, alternate adapter or suppressed cleanup
error. Production storage logic did not need a workaround or rewrite.

## Compatibility and measured impact

No StoryDesk command, exit-code, schema, file format, configuration, environment
variable, signing contract, record, checkpoint or database migration changed.
`minimum_kujo` now reports `1.5.0`, and `required_runtime_revision` reports the
pinned source revision. Published 1.5.0 binaries predate the fix; the version
string alone is insufficient. The documented source build is required.

The retained-descriptor reproduction changed from descriptor present after close
to absent, without dropping aliases. The new hardening test fails on the original
runtime with **23 passes / 1 failure** and passes on the fixed runtime with
**24 passes / zero failures**. This is a behavioral resource-release measurement,
not a claimed percentage latency or memory improvement. Dependency surface and
application data formats are unchanged.

The original application baseline was 138 checks on Linux/macOS and 136 on
Windows, plus CLI/signing/schema/launcher gates, 24-writer contention on both
adapters and twelve paired qualification cases. Two existing symlink checks are
conditional on platform link capability; none was disabled by this work.

## Verification

Local verification on the final runtime source:

- `KUJO_BIN=../kujo/target/debug/kujo bash scripts/validate.sh`: passed, including
  142 numbered checks and the CLI/signing/schema/launcher gates.
- `KUJO_BIN=../kujo/target/debug/kujo bash scripts/contention_benchmark.sh 24`:
  passed for JSON and SQLite; 24 independent writers, exactly one collision
  winner, immutable winner retained for each adapter.
- `../kujo/target/release/kujo run tests/test.kujo`: 13 passed, zero failed.
- `bash scripts/validate.sh` with the rebuilt release runtime selected by the
  default launcher: passed all 142 checks and all validation gates.
- `git diff --check`: passed.
- Original-runtime regression probe: intentionally failed the retained-alias
  check, confirming it detects the underlying defect.

The first native-close adoption commit passed the complete hosted Linux/macOS/
Windows matrix in [run 35798247590](https://github.com/kujolang/storydesk/actions/runs/35798247590).
The final provider-complete runtime pin passed the complete matrix in
[run 35903383436](https://github.com/kujolang/storydesk/actions/runs/35903383436):

| Platform | Validation | Contention |
|---|---|---|
| Linux | 142 checks and all CLI/signing/schema/launcher gates passed | Both adapters: 24 writers, one collision winner, immutable winner |
| macOS | 142 checks and all CLI/signing/schema/launcher gates passed | Both adapters: 24 writers, one collision winner, immutable winner |
| Windows | 140 checks and all CLI/signing/schema/launcher gates passed | Both adapters: 24 writers, one collision winner, immutable winner |

Linux qualification also passed all **12 paired equivalence cases**, retaining the
4 MiB page-output budget. These are functional/output equivalence measurements;
this follow-up makes no comparative runtime-speed claim. Hosted evidence was
retrieved from artifacts `10771106084` (Linux), `10770758747` (macOS), and
`10771371373` (Windows). Windows' two-check difference remains the pre-existing
conditional symlink behavior.

Verbose local evidence is retained in ignored `.audit-evidence/followups/` under
`native-close-*`, `integrated-close-*` and `completed-close-*` filenames.

## Remaining work and cross-repository status

The previously reported Kujo handle-lifetime dependency has been implemented
upstream and adopted here. No application workaround remains. Local release
validation and the final hosted three-platform matrix passed. No remaining
StoryDesk implementation work or cross-repository dependency is required for this
fix. Kujo's separate report records the upstream language/provider verification.
