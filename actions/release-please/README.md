# release-please

Composite action that runs [Release Please](https://github.com/googleapis/release-please) as a GitHub App, so releases are attributed to the app instead of `github-actions[bot]`.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `client-id` | yes |  | GitHub App client ID used to mint a token. |
| `private-key` | yes |  | GitHub App private key used to mint a token. |
| `target-branch` | no |  | Branch Release Please should track. Defaults to `github.ref_name` when left unset. |
| `major-rolling-tag` | no | `false` | When `true`, move each released package's rolling major tag to the release commit. See [Floating major tag](#floating-major-tag) below for the tag-shape assumptions and limitations this relies on. |

## Outputs

| Name | Description |
| --- | --- |
| `released` | JSON array of packages released in this run, as `{"path": ..., "tag": ...}` per package (e.g. `[{"path": "actions/release-please","tag":" release-please/v1.2.3"},...]`). Empty array (`[]`) if nothing released. |

## Usage

```yaml
permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    # Environment holding the two secrets below, restricted to the release
    # branch. See "Protecting the credentials".
    environment: release
    steps:
      - uses: foo-coders/github-actions/actions/release-please@<commit-sha> # v1.0.0
        with:
          client-id: ${{ secrets.RELEASE_PLEASE_CLIENT_ID }}
          private-key: ${{ secrets.RELEASE_PLEASE_PRIVATE_KEY }}
          major-rolling-tag: true
```

The caller job must declare `contents: write`, `issues: write`, and `pull-requests: write` permissions itself, as well as the `environment:` holding the credentials — a composite action runs inside the caller's job and can set neither.

## Floating major tag

With `major-rolling-tag: true`, this action moves each released package's rolling major tag to point at the release commit, for every package that released in that run.

The release tag's shape is whatever your `release-please-config.json`'s `tag-separator`, `include-v-in-tag`, and each package's `component` produce:

| `tag-separator` | `include-v-in-tag` | `component` | Release tag | Major tag |
| --- | --- | --- | --- | --- |
| `/` | `true` | `release-please` | `release-please/v1.2.3` | `release-please/v1` |
| _(empty)_ | `false` | _(none)_ | `1.2.3` | `1` |

**Limitation:** the major tag is derived by stripping the release tag from its first `.` onward, so this only works when the release tag's only `.` characters separate `major.minor.patch`. If a `component` name or `tag-separator` contains a literal `.`, the derivation truncates too early — e.g. component `my.action` or `tag-separator: "."` would wrongly derive major tag. Avoid dots in `component` names and `tag-separator` for any package that uses `major-rolling-tag`.

## Generating the GitHub App credentials

This action mints a short-lived installation token from a GitHub App at runtime (via [`actions/create-github-app-token`](https://github.com/actions/create-github-app-token)) instead of using `GITHUB_TOKEN`, because a `GITHUB_TOKEN`-authored PR cannot trigger further workflow runs, which would leave Release Please's PRs without CI checks.

To create the App and its two secrets:

1. GitHub → **Settings** → **Developer settings** → **GitHub Apps** → **New GitHub App**.
2. Set repository permissions: **Contents**: Read & write, **Issues**: Read & write, **Pull requests**: Read & write, **Metadata**: Read-only.
3. Disable the webhook (untick **Active**) — this app doesn't need to receive events.
4. Create the app, then copy the **Client ID** shown on its settings page → use this as `RELEASE_PLEASE_CLIENT_ID`.
5. On the same page, click **Generate a private key** → downloads a `.pem` file. Its full contents → use this as `RELEASE_PLEASE_PRIVATE_KEY`.
6. Install the app on the org/repos that need it (App settings → **Install App**).
7. Add both values as environment secrets with those names, matching the usage example above — see [Protecting the credentials](#protecting-the-credentials) for the environment to put them in. Repository or organization secrets work too, but leave the private key readable from every branch.

## Protecting the credentials

`private-key` is a long-lived GitHub App private key: anyone who can read it can mint installation tokens carrying the app's full write access, for as long as the key exists. A repository or organization secret is readable by any workflow run on any branch — including branches nobody has reviewed. Someone with push access can add a workflow triggered on `push` to a branch of their own, or open a same-repo pull request (whose workflow file is taken from the head branch, and does receive secrets), and print the key out. Neither path goes through review.

An environment closes that. Its **deployment branch policy** limits which refs may access its secrets, so restricting the environment to your release branch means the key is only reachable from code that has already passed review on that branch.

Create it under repo → **Settings** → **Environments** → **New environment** (e.g. `release`), and under **Deployment branches and tags** choose **Selected branches and tags** with a rule matching your release branch (e.g. `main`) — an environment without that rule restricts nothing. Hold the two secrets there, and name the environment on the job:

```yaml
jobs:
  release-please:
    runs-on: ubuntu-latest
    environment: release
```

Declaring `environment:` needs no addition to the job's `permissions:`.

What it does **not** buy you: the policy restricts the _branch_, not the _workflow_. Any job on an allowed branch can name the same environment and read the secrets. The guarantee comes from whatever protects that branch — required reviews, required checks, no bypass — so the environment is only ever as strong as the branch rule behind it, and an environment with no deployment branch policy is worth nothing at all.

If you point this action at a maintenance branch with `target-branch`, that branch must be allowed by the deployment branch policy too. Otherwise the job never starts: it fails with a _not allowed to deploy due to environment protection rules_ error.
