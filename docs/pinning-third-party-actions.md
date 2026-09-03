# Pinning third-party actions

Every `uses:` step that references an action outside this repo (e.g. `actions/checkout`,
`googleapis/release-please-action`) must be pinned to a full commit SHA, with the released
version as a trailing comment:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

Never pin to a mutable ref (`@v7`, `@v7.0.1`, `@main`) — it can be moved after the fact, a commit SHA
can't.

Resolve the SHA for a release tag with:

```sh
gh api repos/<owner>/<repo>/git/refs/tags/<tag> --jq .object.sha
```

When bumping a pinned action, update the SHA and the version comment together.
