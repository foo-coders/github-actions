# Pinning third-party actions

Every `uses:` step that references an action outside this repo (e.g. `actions/checkout`, `googleapis/release-please-action`) must be pinned to a full commit SHA, with the released version as a trailing comment:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

Never pin to a mutable ref (`@v7`, `@v7.0.1`, `@main`) — it can be moved after the fact, a commit SHA can't.

Resolve the SHA for a release tag with:

```sh
gh api repos/<owner>/<repo>/git/refs/tags/<tag> --jq .object.sha
```

When bumping a pinned action, update the SHA and the version comment together.

## Wrapping rather than referencing

Some actions here are thin wrappers around a third-party action — [`conventional-pr-title`](../actions/conventional-pr-title) around `amannn/action-semantic-pull-request`, for instance. The wrapper exists for reasons a copy-pasted `uses:` snippet cannot provide:

- **One place to bump.** The upstream pin lives here, not in every consuming repo. A caller tracking the rolling `<name>/v<major>` tag picks the bump up with no change at all; a caller pinning our SHA bumps a single dependency instead of following upstream itself. This is also why a major bump upstream must not ship as a patch — see [dependabot.md](dependabot.md#reviewing-a-bump).
- **Defaults we control.** Every input whose upstream default matters is passed explicitly, even when the value matches upstream's. An upstream change to a default then reaches nobody until we choose it.
- **An API in our own shape.** Upstream inputs are translated to this repo's kebab-case [naming style](../AGENTS.md#naming-style), and only the inputs we intend to support are exposed. Adding one later is not a breaking change; removing one is.
- **Room to replace the implementation.** The wrapper's contract is the behavior, not the dependency, so upstream can be swapped or reimplemented without callers changing a line.

A wrapper that passes every input straight through and sets no default of its own buys none of this, and should be documentation instead.
