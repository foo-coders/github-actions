# github-actions

A collection of GitHub reusable **Composite Actions** and **Reusable Workflows**, maintained in a single repository.

## Conventions

**Layout** — composite actions live under `action/`, reusable workflows live under `workflow/`. Each component gets its own directory.

**Naming** — a component's name is its path from the repo root with `/` replaced by `-`. For example:

| Path              | Component name    |
| ----------------- | ----------------- |
| `action/foo`      | `action-foo`      |
| `action/bar/init` | `action-bar-init` |
| `workflow/baz`    | `workflow-baz`    |

**Versioning** — releases are managed by [Release Please](https://github.com/googleapis/release-please) from [Conventional Commits](https://www.conventionalcommits.org/) merged to `main`. Merging a Release Please pull request cuts a release tagged `<component-name>/v<semver>` (e.g. `action-foo/v1.2.3`) and moves a rolling `<component-name>/v<major>` tag (e.g. `action-foo/v1`) to point at it.

**Consuming a component** — reference it with `owner/repo/path@ref`. Pinning to a commit SHA is preferred, since it can't be moved after the fact; the rolling major tag is a convenience for staying on the latest compatible release.

```yaml
# Preferred: pinned to a commit SHA
- uses: PierreJeanjacquot/github-actions/action/foo@<commit-sha> # v1.2.3

# Convenience: floats on the latest 1.x release
- uses: PierreJeanjacquot/github-actions/action/foo@action-foo/v1
```

## Available Actions

_None yet._

## Available Workflows

_None yet._

## License

[MIT](LICENSE)
