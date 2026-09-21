# AGENTS.md

## Agent skills

### Issue tracker

Issues and specs live in this repo's GitHub Issues, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Multi-context layout: [CONTEXT-MAP.md](CONTEXT-MAP.md) at the repo root, with each action carrying its own `CONTEXT.md` + `docs/adr/`. See `docs/agents/domain.md`.

## Third-party actions

When adding or editing a `uses:` step that references an action outside this repo, pin it to a commit SHA — see [docs/pinning-third-party-actions.md](docs/pinning-third-party-actions.md).

Wrapping a third-party action rather than referencing it directly has rules of its own — see [docs/wrapping-third-party-actions.md](docs/wrapping-third-party-actions.md) before adding a wrapper, or changing one's inputs or defaults.

## Secrets

Workflow secrets live in the `main-automation` GitHub environment rather than as repository secrets, and every job that reads one declares that environment. See [docs/secrets-environment.md](docs/secrets-environment.md) before adding a workflow or an action that consumes a secret.

## Release Please

Releases are managed by Release Please, configured across `release-please-config.json` and `.release-please-manifest.json` at the repo root. See [docs/release-please-config.md](docs/release-please-config.md) for the file-naming requirements and what to do when adding a new action.

## Dependabot

Dependabot bumps the pinned `uses:` SHAs weekly. Before editing `.github/dependabot.yml`, or when a bump PR's grouping or commit prefix looks wrong, see [docs/dependabot.md](docs/dependabot.md).

## Naming style

In workflow and action YAML:

- **Identifiers** — kebab-case: job ids, step `id`s, `inputs`, `outputs` (e.g. `release-please:`, `id: get-token`, `target-branch`).
- **`name`** — every workflow, job, step, and action carries one, in sentence case: short, descriptive, natural language (e.g. `Get token`, `Build released output`).

This governs the YAML that runs in this repository. The usage examples in `README.md` files go the other way: they leave `name:` out of the workflow, the job and the steps. An example shows a caller the keys they must set for the action to work, and what they call their own workflow, job and steps is theirs to choose — shipping our names in an example pushes a preference dressed as a requirement, and invites a reader to copy it without deciding.

## Documentation audience

`README.md` files (root and each `actions/<name>/`) are consumer-facing: only what a caller of the action needs — usage, inputs/outputs, setup. Contributor-facing material (repo conventions, config internals, why something is built the way it is) belongs under `docs/` instead, linked from the relevant README or from this file. Keep each explanation in one of the two places and link to it from the other, rather than duplicating it.
