# github-actions

A collection of **GitHub Actions**, maintained in a single repository.

## Conventions

**Layout** — each action lives under `actions/`, in its own directory with no further nesting. A component's name is its directory name, not its full path (`actions/` isn't repeated in the name). Each directory has at least 3 files:

```
actions/<name>/
├── action.yml    # the action's definition
├── version.txt   # current version, bumped by Release Please
└── README.md     # usage docs for this action
```

**Versioning** — releases are managed by [Release Please](https://github.com/googleapis/release-please) from [Conventional Commits](https://www.conventionalcommits.org/) merged to `main`. Merging a Release Please pull request cuts a release tagged `<name>/v<semver>` (e.g. `foo/v1.2.3`) and moves a rolling `<name>/v<major>` tag (e.g. `foo/v1`) to point at it.

**Consuming an action** — reference it with `owner/repo/actions/name@ref`. Pinning to a commit SHA is preferred, since it can't be moved after the fact; the rolling major tag is a convenience for staying on the latest compatible release.

```yaml
# Preferred: pinned to a commit SHA
- uses: PierreJeanjacquot/github-actions/actions/foo@<commit-sha> # v1.2.3

# Convenience: floats on the latest 1.x release
- uses: PierreJeanjacquot/github-actions/actions/foo@foo/v1
```

## Development

Workflows YAML is linted with [actionlint](https://github.com/rhysd/actionlint) and formatted with [Prettier](https://prettier.io/), both wired up in `.github/workflows/lint.yml`. Set up both locally with:

```sh
npm run install-dev-tools
```

Then:

```sh
npm run format:check # or `npm run format` to write fixes
npm run lint
```

## Available Actions

| Component | Description |
| --- | --- |
| [`release-please`](actions/release-please) | Run Release Please as a GitHub App. |

## License

[MIT](LICENSE)
