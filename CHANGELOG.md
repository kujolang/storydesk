# Changelog

## Unreleased

- Refactored the runtime into focused Kujo modules under `src/`.
- Added command-specific editorial validation, JSON configuration, bounded pagination, atomic export, structured error codes, and detailed doctor/validate reports.
- Hardened storage with per-record write locks, secret-field rejection, traversal and symlink protection, resource ceilings, and append-only audit events.
- Added domain and security suites, pinned-runtime CI, a one-command validation gate, and production-readiness documentation.

## 0.1.0 - 2026-08-14

- Initial Kujo-native release with working local records, validation, contracts, fixtures, and safety boundaries.
