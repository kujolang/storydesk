# Runtime requirement

StoryDesk requires Kujo source revision
`5356b247a7bb3322874c6a2e11af17783fe5c8fd` (version 1.5.0 development line).
The released 1.5.0 binaries predate these native database-lifetime fixes.
CI builds this exact revision with its lockfile on Linux, macOS and Windows.

Build a separate runtime checkout, then point the launcher at it:

```bash
git clone https://github.com/kujolang/kujo.git /your/runtime/kujo
git -C /your/runtime/kujo checkout 5356b247a7bb3322874c6a2e11af17783fe5c8fd
cargo build --locked --release --manifest-path /your/runtime/kujo/Cargo.toml
export KUJO_BIN=/your/runtime/kujo/target/release/kujo
bash scripts/validate.sh
```

Use `kujo.exe` on Windows. The runtime upgrade does not migrate or rewrite
StoryDesk records, metadata, checkpoints, or databases. It supplies native
bounded directory enumeration, byte accounting and native database close; StoryDesk does not fall
back to an unbounded directory listing. Earlier StoryDesk commits retain their
original runtime requirement. Do not assume a version string alone proves the
required capability; use the pinned build and repository verification gate.

CI caches only the successfully built executable, keyed by operating system,
architecture, exact Kujo source revision and Rust compiler fingerprint. There
are no partial restore keys; a changed source or compiler rebuilds the runtime.
All StoryDesk tests still run on cache hits. Increment the `kujo-runtime-v1`
cache namespace when changing build flags or platform ABI assumptions; a miss
rebuilds from the pinned source and lockfile.

`db_close` releases native resources and invalidates every retained alias. Repeated
close remains successful. StoryDesk fixtures use that runtime contract directly;
no reference-clearing workaround is needed. A regression test keeps aliases alive,
checks use-after-close rejection, and deletes the SQLite file immediately. CI runs
this test on Linux, macOS and Windows. See the [upstream contract](https://github.com/kujolang/kujo/blob/5356b247a7bb3322874c6a2e11af17783fe5c8fd/docs/DATABASE_LIFECYCLE.md).
