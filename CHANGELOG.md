# Changelog

## 0.3.0 - 2026-09-23

- Added an opt-in SQLite storage adapter with transactional immutable records and audit events, configurable editorial transition graphs, and offline integration conformance fixtures.
- Added RSA-signed export bundles and trusted-key verification, including opt-in authenticated signing timestamps while retaining legacy signature compatibility.
- Added resumable multi-page packet generation, bounded query documents and diagnostics, and explicit continuation cursors.
- Added current editorial review queues and audit-history projections while preserving legacy listings.
- Hardened exclusive record publication, concurrent audit integrity, input validation, packet resume, filesystem boundaries, and CLI failure contracts.
- Pinned Kujo source revision `58c087b5d7af2a05d5d9fd2ad26a5a533044c5f6` for bounded directory paging and correct native database closing; removed fixture reference-clearing workarounds.
- Added Linux/macOS/Windows validation and multi-process contention gates, isolated performance/output qualification, and runtime-build caching keyed by platform, source revision, and compiler.
- Standardized repository presentation and kept local engineering evidence out of published source.

Runtime requirement: build the exact Kujo revision documented in `docs/runtime.md`.
Published Kujo 1.5.0 binaries predate the required fixes. Existing record and
legacy signature compatibility is retained; StoryDesk remains an offline,
PROPOSE-only tool without publication authority.

## 0.2.0 - 2026-08-14

- Preserved validation compatibility with immutable 0.1.0 records while emitting 0.2.0 records.
- Prevented audit-history conflicts from leaving partial records and added clean-retry regression coverage.
- Enforced timestamp/date ranges and valid state transitions alongside stronger state compatibility, managed-directory safety, pagination, actor, and immutable-record validation.
- Refactored the runtime into focused Kujo modules under `src/`.
- Added command-specific editorial validation, JSON configuration, bounded pagination, atomic export, structured error codes, and detailed doctor/validate reports.
- Hardened storage with per-record write locks, secret-field rejection, traversal and symlink protection, resource ceilings, and append-only audit events.
- Added domain and security suites, pinned-runtime CI, a one-command validation gate, and production-readiness documentation.

## 0.1.0 - 2026-08-14

- Initial Kujo-native release with working local records, validation, contracts, fixtures, and safety boundaries.
