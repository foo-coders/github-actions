# Workflow permissions

A job's `permissions:` block governs one thing: the scopes carried by `GITHUB_TOKEN`. It has no effect on any other credential a job uses — a personal access token, a secret, or an installation token minted at runtime all carry their own permissions and ignore the block entirely.

## Rule

Set a job's permissions from what actually reads `GITHUB_TOKEN` inside it, and nothing else. A scope no step consumes grants access to an unreviewed workflow's disposal without buying anything in return.

## Working out the floor

Go through the job's steps and ask, of each, whether it reads `GITHUB_TOKEN`:

- **`actions/checkout`** uses it to fetch, so a job that checks the repository out needs `contents: read`. A job that needs no working tree needs nothing.
- **A `run:` step** only reads it when the workflow passes it in — as `GITHUB_TOKEN`/`GH_TOKEN` in `env:`, or through `${{ github.token }}` or `${{ secrets.GITHUB_TOKEN }}` in the script. A step running local tooling over checked-out files reads nothing.
- **A third-party action** reads it when the workflow passes it, and also when the input defaults to `${{ github.token }}` — check the upstream `action.yml` for the default rather than assuming, and note that an input left at that default still needs the scopes the action exercises.
- **A step authenticating some other way** needs nothing from the block. Both `release-please` and `mise-update` mint an installation token from a GitHub App and pass it to every step that writes, which is why their callers grant no write scope at all.

The same reasoning applies to a composite action in `actions/`. It cannot declare permissions of its own — it runs inside the caller's job — so whatever it consumes becomes a requirement on every caller, and belongs in that action's `README.md`. Requiring a scope the action never reads pushes a cost onto consumers for nothing.

## App permissions are not workflow permissions

An action that mints a GitHub App token deals in two unrelated sets of permissions, easily conflated because they are written in the same vocabulary:

- **The app's** — chosen on the app's settings page and narrowed per run by the `permission-*` inputs of `actions/create-github-app-token`. These are the ones that let the action write.
- **The caller workflow's** — the `permissions:` block, governing `GITHUB_TOKEN` alone.

Copying the first list into the second is the common mistake. It reads plausible, and it grants write access to a token the action never touches. When an action's README documents both, say which is which.

## What the linters do not catch

`zizmor` flags the shape of a permissions block — a missing one, or a workflow-level grant wider than its jobs need. Neither it nor `actionlint` can tell whether a granted scope is ever used, because that would mean knowing what every step does with the token. An unused permission passes `mise run lint` cleanly. This rule is the only check there is.
