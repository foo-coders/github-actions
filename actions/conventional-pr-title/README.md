# conventional-pr-title

Composite action that checks a pull request title against the [Conventional Commits](https://www.conventionalcommits.org/) specification, so the commit it produces stays machine-readable for changelog and release tooling.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `types` | no | `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert` | Types the PR title may use, one per line. |
| `scopes` | no | _(empty)_ | Scopes the PR title may use, one per line. Empty allows any scope. |
| `require-scope` | no | `false` | When `true`, the PR title must carry a scope. |

This action has no outputs.

## Usage

```yaml
on:
  pull_request:
    types: [opened, edited, reopened, synchronize]

permissions: {}

jobs:
  pr-title:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: read
    steps:
      - uses: foo-coders/github-actions/actions/conventional-pr-title@<commit-sha> # v1.0.0
```

The caller job must declare `pull-requests: read` itself — a composite action runs inside the caller's job and cannot set its own permissions.

Keep `synchronize` in the event list if you make this check required for merging. Branch protection evaluates checks against the head commit, and `opened`/`edited`/`reopened` do not fire when a commit is pushed — without `synchronize` the new head would have no run at all, and the pull request would stay blocked.

## What gets checked

**The pull request title**, and nothing else. This assumes a **squash merge**, where the title becomes the message of the single commit that lands on the target branch. On a repository that merges with merge commits or rebases, this check says nothing about the messages that actually reach the history — validate the commits themselves instead.

One case escapes that assumption: when a pull request contains exactly **one** commit, GitHub prefills the squash message from that commit message rather than from the title. The action always checks that commit message too, which is why the assumption holds in both cases.

## Reporting failures

A failing check reports the reason in the job's log and annotations. It deliberately does not comment on the pull request: commenting needs `pull-requests: write` and the `pull_request_target` event, which are a meaningful cost to impose on every caller. Compose that yourself if you want it.
