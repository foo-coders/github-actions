# Referencing this repository's own actions

A workflow here that uses an action of this repository writes `uses: $/actions/<name>`, with no `@ref`. `$/` resolves to this repository at the exact commit running, so the workflow and the action it calls never drift apart, and no checkout is needed to find the action.

`$/` only locates the action's code. It does not populate the workspace: a job whose action reads or rewrites the repository's files still needs `actions/checkout`, as [`mise-update`](../actions/mise-update/README.md) does.

## actionlint

actionlint does not know `$/` yet and reports it as `ref is missing` ([rhysd/actionlint#711](https://github.com/rhysd/actionlint/issues/711)). `.github/actionlint.yaml` ignores that one message so the rest of the linting stays intact. Keep `$/` rather than adding an `@ref` to satisfy it.

Once the fix ([rhysd/actionlint#732](https://github.com/rhysd/actionlint/pull/732)) ships in the actionlint version pinned in `mise.toml`, delete `.github/actionlint.yaml` and run `mise run lint` to confirm it passes without.
