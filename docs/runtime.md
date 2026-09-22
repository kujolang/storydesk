# Runtime requirement

The bounded-directory follow-up requires Kujo source revision
`cf785c0a7953717af16b657cda05b85d628144c5` (version 1.4.0 development line).
The released 1.4.0 binaries predate `list_dir_page` and are insufficient.
CI builds this exact revision with its lockfile on Linux, macOS and Windows.

Build a separate runtime checkout, then point the launcher at it:

```bash
git clone https://github.com/kujolang/kujo.git /your/runtime/kujo
git -C /your/runtime/kujo checkout cf785c0a7953717af16b657cda05b85d628144c5
cargo build --locked --release --manifest-path /your/runtime/kujo/Cargo.toml
export KUJO_BIN=/your/runtime/kujo/target/release/kujo
bash scripts/validate.sh
```

Use `kujo.exe` on Windows. The runtime upgrade does not migrate or rewrite
StoryDesk records, metadata, checkpoints, or databases. It supplies native
bounded directory enumeration and byte accounting; StoryDesk does not fall
back to an unbounded directory listing. Earlier StoryDesk commits retain their
original runtime requirement. Do not assume a version string alone proves the
required capability; use the pinned build and repository verification gate.
