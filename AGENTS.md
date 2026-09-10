# AGENTS.md

## Third-party actions

When adding or editing a `uses:` step that references an action outside this repo, pin it to a commit SHA — see [docs/pinning-third-party-actions.md](docs/pinning-third-party-actions.md).

## Release Please

Releases are managed by Release Please, configured across `release-please-config.json` and `.release-please-manifest.json` at the repo root. See [docs/release-please-config.md](docs/release-please-config.md) for the file-naming requirements and what to do when adding a new action.

## Naming style

Use kebab-case for names in workflow/action YAML — step `id`s, `inputs`, and `outputs` (e.g. `id: get-token`, `target-branch`). Do not use snake_case or camelCase.

## Documentation audience

`README.md` files (root and each `actions/<name>/`) are consumer-facing: only what a caller of the action needs — usage, inputs/outputs, setup. Contributor-facing material (repo conventions, config internals, why something is built the way it is) belongs under `docs/` instead, linked from the relevant README or from this file. Keep each explanation in one of the two places and link to it from the other, rather than duplicating it.
