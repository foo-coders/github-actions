# AGENTS.md

## Third-party actions

When adding or editing a `uses:` step that references an action outside this repo, pin it to
a commit SHA — see [docs/pinning-third-party-actions.md](docs/pinning-third-party-actions.md).

## Naming style

Use kebab-case for names in workflow/action YAML — step `id`s, `inputs`, and `outputs`
(e.g. `id: get-token`, `target-branch`). Do not use snake_case or camelCase.
