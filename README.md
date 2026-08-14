# StoryDesk

[![Version](https://img.shields.io/badge/version-0.1.0-black)](VERSION)
[![CI](https://github.com/kujolang/storydesk/actions/workflows/validate.yml/badge.svg)](https://github.com/kujolang/storydesk/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)

StoryDesk is a local-first editorial control desk for ideas, campaigns,
commissions, assignments, dependencies, packets, handoffs, and human review
queues. It is implemented in [Kujo](https://github.com/kujolang/kujo) and works
without a hosted service, database server, model key, or sibling Publishing
House tool.

## Readiness posture

StoryDesk is ready for serious standalone editorial operations with immutable
records, append-only audit events, atomic writes, per-record concurrency locks,
bounded queries, deterministic fixtures, structured errors, and explicit
authority boundaries. “Enterprise grade” is treated as a continuously verified
standard—not a marketing label. It does not claim distributed multi-host
coordination, hosted identity, or publication authority.

See the evidence-backed [production review](docs/PRODUCTION_READINESS_REVIEW.md)
and [next-session worklist](docs/NEXT_SESSION.md).

## Quick install

StoryDesk requires Kujo 1.0.1 or newer.

```bash
git clone https://github.com/kujolang/storydesk.git
cd storydesk
export KUJO_BIN=/absolute/path/to/kujo
export PATH="$PWD/bin:$PATH"
storydesk --version --json
storydesk doctor --json
```

The launcher prefers `KUJO_BIN` and otherwise uses the verified ecosystem
runtime path. Direct invocation remains available:

```bash
kujo run storydesk.kujo -- doctor --json
```

## Quick start

```bash
storydesk init --state .storydesk --json
storydesk idea add \
  --input fixtures/core.json \
  --actor commissioning-editor \
  --timestamp 2026-08-14T12:00:00Z \
  --json
storydesk idea list --limit 25 --json
storydesk validate --json
```

Use a small JSON config when stable automation defaults are useful:

```json
{
  "state": ".storydesk",
  "actor": "managing-editor",
  "limit": 100
}
```

```bash
storydesk idea list --config storydesk.json --after idea-previous --json
```

## Commands

| Command | Purpose |
| --- | --- |
| `init` | Initialize portable local state. |
| `idea add`, `idea list` | Capture and query the idea queue. |
| `campaign create` | Record a campaign and objective. |
| `commission create` | Create a validated editorial brief. |
| `assign`, `claim` | Assign and claim bounded work. |
| `status`, `block` | Append validated status or blocking-evidence events. |
| `handoff` | Record explicit ownership transfer and next action. |
| `packet daily`, `packet range` | Create deterministic work-packet records. |
| `review-queue` | Query work awaiting human review. |
| `show`, `history` | Inspect immutable records and audit-oriented listings. |
| `export` | Emit or atomically write a bounded portable JSON bundle. |
| `validate`, `doctor`, `version` | Verify records, environment health, and compatibility. |

## Common flags

| Flag | Behavior |
| --- | --- |
| `--state PATH` | Explicit local state directory. Traversal and symlinks are rejected. |
| `--config FILE` | JSON defaults for `state`, `actor`, and `limit`. |
| `--input FILE` | Command payload, limited to 1 MiB. |
| `--actor ID` | Required identity for every mutation. |
| `--timestamp UTC` | RFC 3339 UTC time; enables deterministic fixture IDs. |
| `--id ID` | Explicit stable, type-prefixed record ID. |
| `--type`, `--after`, `--limit` | Bounded filtering and cursor pagination. |
| `--output FILE` | Atomic JSON export, never implicit overwrite. |
| `--force` | Permits only explicitly named safe export replacement. |
| `--dry-run` | Run validation and record construction without writes. |
| `--json` | Stable `ok/data/error/error_code/tool_version/contract_version` envelope. |

Exit codes are `0` for success, `1` for validated operational failure, and `2`
for CLI usage errors.

## Storage and security

State defaults to `.storydesk/`. Records are immutable JSON objects under
`records/`; audit events are append-only under `history/`; short-lived
per-record lock directories prevent concurrent duplicate writes. Inputs,
artifacts, list results, and exports have hard resource ceilings. Secret-shaped
fields, traversal, symlink records, malformed JSON, incompatible schema majors,
duplicate IDs, and unsafe overwrites fail closed.

StoryDesk operates under OBSERVE and PROPOSE. It never manufactures approval,
silently resolves evidence failures, calls publication APIs, or marks work
published because a file exists. See [contracts](docs/contracts.md) and the
[security model](docs/security.md).

## Project structure

```text
storydesk.kujo        canonical entrypoint
src/                  CLI, domain, contracts, storage, and shared Kujo modules
tests/                Kujo regression, domain, and security suites
schemas/              public JSON contracts
fixtures/             deterministic offline inputs
scripts/              validation and release-development gates
docs/                 architecture, security, review, and future work
bin/storydesk         logic-free POSIX launcher
```

## Verification

```bash
bash scripts/validate.sh
```

The gate pins the tested runtime in CI, runs every Kujo suite, validates JSON
artifacts and CLI smoke paths, rejects foreign runtime dependencies, and checks
the Git diff. Hosted providers are optional; none are required for the core.
