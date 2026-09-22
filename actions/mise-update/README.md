# mise-update

Composite action that proposes updates to a [mise](https://mise.jdx.dev) manifest **and** its lockfile as a single, perpetually-current pull request.

Dependabot does not support mise. Renovate has a native mise manager, but it updates `mise.toml` only and leaves `mise.lock` stale — so if you already run Renovate, what this action adds is the lockfile half. See [Choosing this over Renovate](#choosing-this-over-renovate).

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `client-id` | yes |  | GitHub App client ID used to mint a token. |
| `private-key` | yes |  | GitHub App private key used to mint a token. |
| `working-directory` | no | `.` | Directory mise runs in. Must hold a mise manifest and a `mise.lock`. |
| `branch` | no | _(derived)_ | Pull request branch. See [Branch naming](#branch-naming). |
| `commit-prefix` | no | `chore(deps)` | [Conventional Commits](https://www.conventionalcommits.org/) prefix for the commit and the pull request title. |
| `labels` | no | _(empty)_ | Labels to apply, one per line. Empty by default because a label that doesn't exist in your repository fails the run. |
| `mise-version` | no | _(empty)_ | Version of mise to install. When empty, the newest mise release at least 7 days old is used. |

## Outputs

| Name | Description |
| --- | --- |
| `pull-requests` | JSON array of the pull requests proposed in this run, as `[{"pull-request-number": 42,"pull-request-url": "...","pull-request-operation": "created"}]`. Empty array (`[]`) when nothing was proposed. |

The output is an array, not an object, so that per-tool pull requests can be added later without breaking callers. Today it holds at most one entry.

## Usage

```yaml
on:
  schedule:
    - cron: "30 4 * * 1"
  workflow_dispatch:

permissions: {}

concurrency:
  group: mise-update

jobs:
  mise-update:
    runs-on: ubuntu-latest
    # Holds the app credentials — see "Protecting the credentials" below.
    environment: automation
    permissions:
      contents: read # required for checkout
    steps:
      - uses: actions/checkout@<commit-sha> # v7.0.1
        with:
          persist-credentials: false
      - uses: foo-coders/github-actions/actions/mise-update@<commit-sha> # v1.0.0
        with:
          client-id: ${{ secrets.MISE_UPDATE_CLIENT_ID }}
          private-key: ${{ secrets.MISE_UPDATE_PRIVATE_KEY }}
```

**The `actions/checkout` step is required.** This action reads and rewrites files in your working tree, so without it the workspace is empty and the run fails at the preflight check. `contents: read` is all the job needs — the checkout uses it, and the action mints its own GitHub App token that carries the write permissions.

Add `workflow_dispatch` (as above) if you want to run an urgent bump without waiting for the schedule, and a `concurrency` group so a manual run can't overlap a scheduled one.

You do **not** need a separate mise setup step. This action installs mise itself.

## What lands in the pull request

One pull request per working directory, amended in place as new versions appear, and closed with its branch deleted once there is nothing left to propose.

Its body has up to three sections:

- **Manifest bumps** — tools whose version spec was rewritten in the manifest, with a link to each release's notes. Some backends (notably `npm:`) publish no release URL, so that cell is legitimately blank.
- **Lockfile-only moves** — tools whose declared spec didn't change but which re-resolved to a new version. This is what catches patch-level movement inside a floating spec like `node = "26"`.
- **Not updated** — tools the action could not process, with the reason. These are also emitted as workflow annotations, so you still see them on a run that produces no pull request at all.

A tool bumped in the manifest is listed only under **Manifest bumps**; the title's count is the number of distinct tools that moved either way.

Commits are signed and attributed to your GitHub App, so it is clear at a glance who proposed the change.

## What gets rewritten, and what doesn't

| Version spec | Treatment |
| --- | --- |
| Semver-shaped (`1`, `1.2`, `1.2.3`) | Rewritten in the manifest. |
| `latest`, `lts` | Left alone silently — there is nothing to bump. The lockfile pass still moves them. |
| Anything else (`prefix:`, `ref:`, `path:`, `sub-N:`, arrays, tool-option syntax) | Reported under **Not updated**, never rewritten. |

A tool is also reported rather than rewritten when its manifest isn't tracked by git (an edit there could never reach the pull request), or when mise proposes a value that doesn't look like a version.

Two further things to know:

- **The action does not verify the update.** It writes a manifest and lockfile it never installed, so the CI on the pull request is what proves the new versions work.
- **An inline comment on a rewritten line is lost.** Every other comment survives, so don't rely on an inline comment to explain a pin.

## Holding new versions back

The action exposes no cooldown input. Configure it in your own mise settings instead, so the same policy applies to every mise command your project runs:

```toml
# mise.toml
[settings]
minimum_release_age = "7d"
minimum_release_age_excludes = ["npm:*"]
```

This governs both the manifest and the lockfile path. Two traps:

- **mise applies a 24-hour cooldown even if you configure nothing.** Today's release will not be proposed today.
- **`jdx/mise-action` has an input of the same name, and it does something else.** It selects which _mise binary_ to install; it does not filter tool versions. This action sets it for you — see `mise-version` above.

Adding a `[settings]` block prompts each local developer to trust the config once. The action trusts it automatically.

## Branch naming

A root `working-directory` gives the branch `mise-update`. Any other directory gives `mise-update-<sanitised path>`, so two projects in one repository get one stable branch each and never fight over the same pull request. Override it with `branch` if that collides with something in your repository.

## Failure modes

- The run fails immediately if `working-directory` has no mise manifest or no `mise.lock` — including when the workspace was never checked out. mise itself never errors on a missing lockfile, so without this check a mistyped path would leave you with a green job that had checked nothing.
- The runner's global mise configuration is never in scope: version discovery is restricted to your project's local config, so the action can only ever propose changes to your project.
- A registry that fails mid-run costs its own tools, not the whole run — you get a partial pull request rather than none.

## Choosing this over Renovate

[Renovate](https://docs.renovatebot.com/modules/manager/mise/) has a native mise manager and covers the manifest half of this. It does not update `mise.lock`, which is an acknowledged gap — and the lockfile is what actually determines the versions your CI installs. If you already run Renovate, adopt this action for the lockfile; if you don't, this action needs no third-party GitHub App beyond your own and no self-hosting.

## Generating the GitHub App credentials

This action mints a short-lived installation token from a GitHub App at runtime (via [`actions/create-github-app-token`](https://github.com/actions/create-github-app-token)) instead of using `GITHUB_TOKEN`, because a `GITHUB_TOKEN`-authored pull request cannot trigger further workflow runs — which would leave every update pull request without the CI that is the only thing verifying it.

Use a **dedicated** app rather than one you already use for releases: the permissions differ, and a shared identity would misattribute every update pull request.

1. GitHub → **Settings** → **Developer settings** → **GitHub Apps** → **New GitHub App**.
2. Set repository permissions: **Contents**: Read & write, **Pull requests**: Read & write, **Metadata**: Read-only. Nothing else.
3. Disable the webhook (untick **Active**) — this app doesn't need to receive events.
4. Create the app, then copy the **Client ID** shown on its settings page → use this as `MISE_UPDATE_CLIENT_ID`.
5. On the same page, click **Generate a private key** → downloads a `.pem` file. Its full contents → use this as `MISE_UPDATE_PRIVATE_KEY`.
6. Install the app on the org/repos that need it (App settings → **Install App**).
7. Hold both values as secrets under those names, matching the usage example above — in an environment rather than as repository secrets, for the reason below.

The app's display name is what appears as the author of every update pull request, so pick one you're happy to see in your history.

## Protecting the credentials

`private-key` is a long-lived GitHub App private key: anyone who can read it can mint installation tokens carrying the app's full write access, for as long as the key exists. A repository or organization secret is readable by any workflow run on any branch — including branches nobody has reviewed. Someone with push access can add a workflow triggered on `push` to a branch of their own, or open a same-repo pull request (whose workflow file is taken from the head branch, and does receive secrets), and print the key out. Neither path goes through review.

An environment closes that. Its **deployment branch policy** limits which refs may access its secrets, so restricting the environment to your default branch means the key is only reachable from code that has already passed review on that branch.

Create it under repo → **Settings** → **Environments** → **New environment** (e.g. `automation`), and under **Deployment branches and tags** choose **Selected branches and tags** with a rule matching that branch (e.g. `main`) — an environment without that rule restricts nothing. Hold the two secrets there, and name the environment on the job:

```yaml
jobs:
  mise-update:
    runs-on: ubuntu-latest
    environment: automation
```

Declaring `environment:` needs no addition to the job's `permissions:`.

What it does **not** buy you: the policy restricts the _branch_, not the _workflow_. Any job on an allowed branch can name the same environment and read the secrets. The guarantee comes from whatever protects that branch — required reviews, required checks, no bypass — so the environment is only ever as strong as the branch rule behind it, and an environment with no deployment branch policy is worth nothing at all.

A composite action runs inside the caller's job and cannot declare an environment of its own, so this is always yours to set.

Note the scheduled trigger only ever runs on the default branch, so a deployment branch policy matching it does not get in the update run's way.
