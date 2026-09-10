# Release Please configuration

How `release-please-config.json` and `.release-please-manifest.json` are set up, and what to do when adding a new action.

## Adding a new action

Each action is released independently (see the root [README](../README.md#versioning)). When adding `actions/<name>/`, register it in both files:

`release-please-config.json`:

```json
"actions/<name>": {
  "component": "<name>"
}
```

`.release-please-manifest.json`:

```json
"actions/<name>": "0.0.0"
```

`0.0.0` is just a placeholder meaning "nothing released yet" — release-please overwrites it with the real version once the first release lands. Top-level defaults (below) apply to the new package automatically.

## Top-level defaults

- `release-type: simple` — actions have no language-specific manifest to bump; they just need a release, changelog, and tag.
- `separate-pull-requests: true` — each action gets its own release PR and version stream, matching the per-action versioning convention.
- `tag-separator: "/"` + `include-v-in-tag: true` — together produce the `<name>/v<semver>` tag shape documented in the root README.
- `initial-version: "1.0.0"` — the version proposed for a package's **first ever** release (i.e. while it has no prior release/tag). This only applies once and automatically stops mattering afterward: once a release exists, normal Conventional Commits bump rules take over from the latest release and `initial-version` is never consulted again. This is why it's preferred over `release-as`, which pins _every_ subsequent release until manually removed from the config.

## Floating major tag

Release-please does not move rolling major tags itself — [`actions/release-please`](../actions/release-please) does it, when called with `major-rolling-tag: true` (as `.github/workflows/release.yml` does), for every package that released in that run — not just one hardcoded package, so this keeps working as more packages get registered above. This is why the action exposes a generic `released` output (one `{"path": ..., "tag": ...}` entry per package released) instead of package-specific outputs. See [`actions/release-please`'s README](../actions/release-please#floating-major-tag) for the tag-shape assumptions and limitations this relies on — it depends on this config's `tag-separator`, `include-v-in-tag`, and each package's `component`.

## Publishing

Releases auto-publish (as a real GitHub Release, not a draft) as soon as their release PR is merged.
