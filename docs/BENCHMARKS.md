# Storage and contention benchmarks

## SQLite admission decision

The adapter admission rule is a minimum 2x improvement over immutable JSON for three complete, cursor-paginated scans. On 2026-08-14, the checked-in Kujo 1.0.1 release runtime on the macOS launch environment produced:

| Records | Full scans | JSON | SQLite | Speedup | Decision |
| ---: | ---: | ---: | ---: | ---: | --- |
| 1,000 | 3 | 22,510 ms | 6,608 ms | 3x | admit as opt-in |

The benchmark creates equivalent immutable record documents in isolated state roots and exercises the production adapter listing paths. Run it with the large-house target size before choosing an adapter:

```bash
kujo run scripts/storage_benchmark.kujo -- 5000
```

The script exits nonzero unless counts match and the measured speedup meets the 2x threshold. JSON remains the default because it is maximally portable and directly inspectable.

## Multi-process contention

`scripts/contention_benchmark.sh` launches concurrent processes against one immutable ID and a second wave against independent IDs for both adapters. Exactly one colliding writer and every independent writer must succeed; all losing writes must fail closed and the resulting state must validate.

The local macOS launch run passed with 16 workers for JSON and SQLite. The required GitHub Actions matrix repeats the benchmark with 24 workers on `ubuntu-latest`, `macos-latest`, and `windows-latest` using checksum-verified Kujo 1.0.1 release binaries, and retains one JSON artifact per launch environment. A failure in any environment fails CI.
