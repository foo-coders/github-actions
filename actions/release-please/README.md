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

## Generating the GitHub App credentials

This action mints a short-lived installation token from a GitHub App at runtime (via [`actions/create-github-app-token`](https://github.com/actions/create-github-app-token)) instead of using `GITHUB_TOKEN`, because a `GITHUB_TOKEN`-authored PR cannot trigger further workflow runs, which would leave Release Please's PRs without CI checks.

To create the App and its two secrets:

1. GitHub → **Settings** → **Developer settings** → **GitHub Apps** → **New GitHub App**.
2. Set repository permissions: **Contents**: Read & write, **Issues**: Read & write, **Pull requests**: Read & write, **Metadata**: Read-only.
3. Disable the webhook (untick **Active**) — this app doesn't need to receive events.
4. Create the app, then copy the **App ID** shown on its settings page → use this as `RELEASE_PLEASE_APPLICATION_ID`.
5. On the same page, click **Generate a private key** → downloads a `.pem` file. Its full contents → use this as `RELEASE_PLEASE_PRIVATE_KEY`.
6. Install the app on the org/repos that need it (App settings → **Install App**).
7. Add both values as repo or org secrets with those names, matching the usage example above.
