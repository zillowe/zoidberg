`app`
===

Rename me.

## Next Steps

`zoi create` copies template files verbatim and performs no placeholder
substitution, so the crate is still named `app`. Rename it before writing any
code:

```shell
# Rename the crate directory.
mv crates/app crates/myproject

# Update the package name and binary name in crates/myproject/Cargo.toml.
# Both are called "app"; the first is the package, the second the binary.

# Update the workspace URLs in Cargo.toml.
# homepage, repository, documentation and description all still say "app".
```

Then check that the conventions are in place:

```shell
cargo +nightly fmt --all
cargo check --workspace --all-targets --all-features
just lint
just test
```

## What This Template Sets Up

- `rustfmt.toml` with the Zillowe configuration: 80-column wrapping, comment
  wrapping, module-granular imports, and `StdExternalCrate` grouping. Requires
  nightly rustfmt.
- `.editorconfig` so editors match the formatter on indentation, line width,
  and final newlines.
- A workspace `Cargo.toml` carrying the shared lint policy, inherited by every
  crate through `[lints] workspace = true`.
- A `Justfile` with `fmt`, `fmt-check`, `check`, `lint`, `lint-fix`, `test`,
  `deps`, and `clean` recipes, all running with `RUSTFLAGS=-Dwarnings`.
- `.gitlab-ci.yml` running format, clippy, and tests on every branch and merge
  request.
- `renovate.json` configured for Cargo with the git sign-off extension.
- `Apache-2.0` licensing.

## Lint Policy

The shared policy is strict, and it is deliberate. Expect to fix these rather
than suppress them:

- `missing_docs` is `deny`, as is `missing_docs_in_private_items`. Every item
  needs a doc comment, including private fields and test helpers.
- `unwrap_used` is `deny`. Use `.expect("why this cannot fail")` instead.
- `pedantic` is `warn` and `RUSTFLAGS` is `-Dwarnings`, so pedantic lints fail
  the build. The common ones are `doc_markdown` (wrap `SemVer` in backticks),
  `print_literal`, and `bool_assert_comparison`.
- `indexing_slicing` is `warn`. Use `.get()` and handle the `None`, or a
  `let ... else` after an explicit length check.

## Adding a Crate

Add it under `crates/`, then declare shared dependencies in
`[workspace.dependencies]` at the root and reference them as
`dependency.workspace = true`. Never pin a version in a member crate.

```shell
cargo new crates/mycrate --lib
```

License
-------

Licensed under the [Apache 2.0 License](./LICENSE)
