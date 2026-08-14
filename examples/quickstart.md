# Quickstart

`./bin/storydesk init --state /tmp/storydesk-demo --json`

`./bin/storydesk idea add --state /tmp/storydesk-demo --input fixtures/core.json --actor operator --timestamp 2026-08-14T00:00:00Z --json`

The fixed timestamp makes fixture IDs deterministic; repeating the command is rejected.
