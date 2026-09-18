# Context Map

Each action in this repository is its own context: it has its own vocabulary, its own decisions, and no shared model with the others. Repo-wide conventions live in [AGENTS.md](AGENTS.md) and `docs/`, not here.

## Contexts

- [mise update](./actions/mise-update/CONTEXT.md) — proposes mise manifest and lockfile updates as a pull request
- `actions/conventional-pr-title` — checks a pull request title against Conventional Commits. No `CONTEXT.md` yet; add one when there is something to write.
- `actions/release-please` — runs Release Please as a GitHub App. No `CONTEXT.md` yet; add one when there is something to write.

## Relationships

The contexts do not talk to each other. Each is published and versioned independently, and a consumer adopts them one at a time.

Two repo-wide mechanisms cut across all of them, and are documented under `docs/` rather than in any context:

- **Release Please** releases every action from the same commit history — see [docs/release-please-config.md](docs/release-please-config.md).
- **Dependabot** bumps the third-party `uses:` pins inside every action — see [docs/dependabot.md](docs/dependabot.md).
