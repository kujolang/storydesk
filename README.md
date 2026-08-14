# StoryDesk

Editorial control desk for ideas, campaigns, commissions, assignments, dependencies, packets, handoffs, and review queues.

StoryDesk 0.1.0 is an independently installable, local-first Kujo tool. It requires no hosted service, Chain of Command, WebOps, or sibling Publishing House tool. The canonical entrypoint is `storydesk.kujo`; `bin/storydesk` contains no product logic.

## CLI

Commands: idea add; idea list; campaign create; commission create; assign; packet daily; packet range; claim; status; block; handoff; review-queue; show; export; doctor; version; init; validate. Run `./bin/storydesk help` for flags. Mutations require `--actor`; JSON input uses `--input`. Common flags include `--json`, `--dry-run`, `--state`, `--output`, `--config`, and `--force`. Exit codes: 0 success, 1 validation/operation failure, 2 usage error.

State defaults to `.storydesk/`. Immutable JSON records and append-only history use atomic writes. IDs reject traversal; symlinks and oversized inputs are rejected. See [contracts](docs/contracts.md), [security](docs/security.md), and [quickstart](examples/quickstart.md).

Test with `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/test.kujo`, then run `./bin/storydesk doctor --json`.

0.1.0 covers the documented local records, fixtures, validation, checksums, deterministic fixed-time IDs, and structured export. It does not manufacture human judgment, consent, rights, approval, or causation. No publication APIs; recurring generation uses deterministic inputs and duplicate rejection.
