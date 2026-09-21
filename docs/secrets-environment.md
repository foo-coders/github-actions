# Secrets environment

Every secret this repository's workflows consume lives in the `main-automation` GitHub environment, never as a repository or organization secret.

## Why

The secrets here are GitHub App credentials: `RELEASE_PLEASE_CLIENT_ID` / `RELEASE_PLEASE_PRIVATE_KEY`, and `MISE_UPDATE_CLIENT_ID` / `MISE_UPDATE_PRIVATE_KEY` for the workflow in [#13](https://github.com/foo-coders/github-actions/issues/13). A private key mints installation tokens carrying the app's full write access to this repo, and stays valid until someone revokes it.

A repository secret is readable from any branch. Anyone with push access could add a workflow under `.github/workflows/`, trigger it on `push` to a branch of their own, and print the key — or open a same-repo pull request, whose workflow file is taken from the head branch and does receive secrets. Neither path goes through review.

`main-automation` carries a deployment branch policy limiting it to `main`, which admins cannot bypass. `main` in turn is covered by the `protect-default-and-v*` ruleset, which requires a reviewed pull request to land anything — see the repository's rulesets for its current parameters. The key is therefore only reachable from reviewed code.

## What this does not cover

The policy restricts the branch, not the workflow: any job running on `main` may declare `environment: main-automation` and read the secrets. The protection is the review on `main`, not isolation between workflows. Treat a change that adds this environment to a new job as a change that hands that job the App's write access, and review it on those terms.

## Rule

Any workflow in this repository that reads a secret declares the environment on the job that reads it:

```yaml
jobs:
  <job>:
    environment: main-automation
```

This needs no addition to the job's `permissions:`. Secrets for new automation go into this environment, not into repository or organization secrets.

## Adding an action that requires secrets

A composite action runs inside the caller's job and cannot declare an environment of its own, so this is always the caller's responsibility. An action whose inputs take secrets documents the practice in its own `README.md`, consumer-facing and generic — an external caller needs the pattern, not this repo's environment name, which means nothing outside it. See [`actions/release-please/README.md`](../actions/release-please/README.md#protecting-the-credentials) for wording to reuse.
