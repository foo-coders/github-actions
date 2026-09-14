# conventional-pr-title

Composite action that checks a pull request title against the [Conventional Commits](https://www.conventionalcommits.org/) specification, so the commit it produces stays machine-readable for changelog and release tooling.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `types` | no | the 11 [conventional commit types](https://github.com/commitizen/conventional-commit-types) | Types the PR title may use, one per line. |
| `scopes` | no | _(empty)_ | Scopes the PR title may use, one per line. Empty allows any scope. |
| `require-scope` | no | `false` | When `true`, the PR title must carry a scope. |
| `validate-single-commit` | no | `true` | When `true`, also check the commit message of a PR that has a single commit. See [What gets checked](#what-gets-checked). |

This action has no outputs.

## Usage

```yaml
name: PR title

on:
  pull_request:
    types: [opened, edited, reopened, synchronize]

permissions:
  contents: read

jobs:
  pr-title:
    name: Validate PR title
    runs-on: ubuntu-latest
    permissions:
      pull-requests: read
    steps:
      - uses: foo-coders/github-actions/actions/conventional-pr-title@<commit-sha> # v1.0.0
```

No `actions/checkout` step is needed — the action reads the pull request from the API, not from a checkout.

The caller job must declare `pull-requests: read` itself — a composite action runs inside the caller's job and cannot set its own permissions.

Keep `synchronize` in the event list if you make this check required for merging. Branch protection evaluates checks against the head commit, and `opened`/`edited`/`reopened` do not fire when a commit is pushed — without `synchronize` the new head would have no run at all, and the pull request would stay blocked.

## What gets checked

**The pull request title**, and nothing else. This assumes a **squash merge**, where the title becomes the message of the single commit that lands on the target branch. On a repository that merges with merge commits or rebases, this check says nothing about the messages that actually reach the history — validate the commits themselves instead.

One case escapes that assumption: when a pull request contains exactly **one** commit, GitHub prefills the squash message from that commit message rather than from the title. `validate-single-commit` defaults to `true` so the commit message is checked too, which is why the assumption holds in both cases.

## Reporting failures

A failing check reports the reason in the job's log and annotations. It deliberately does not comment on the pull request: commenting needs `pull-requests: write` and the `pull_request_target` event, which are a meaningful cost to impose on every caller. Compose that yourself if you want it.
