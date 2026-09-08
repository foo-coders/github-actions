# release-please

Composite action that runs [Release Please](https://github.com/googleapis/release-please) as a GitHub App, so releases are attributed to the app instead of `github-actions[bot]`.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `app-id` | yes |  | GitHub App client ID used to mint a token. |
| `private-key` | yes |  | GitHub App private key used to mint a token. |
| `target-branch` | no |  | Branch Release Please should track. Defaults to `github.ref_name` when left unset. |

## Usage

```yaml
permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: foo-coders/github-actions/actions/release-please@<commit-sha> # v1.0.0
        with:
          app-id: ${{ secrets.RELEASE_PLEASE_APPLICATION_ID }}
          private-key: ${{ secrets.RELEASE_PLEASE_PRIVATE_KEY }}
```

The caller job must declare `contents: write`, `issues: write`, and `pull-requests: write` permissions itself — a composite action runs inside the caller's job and cannot set its own permissions.
