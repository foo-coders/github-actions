# TODO

## Tooling for GitHub Actions workflows / composite actions

- [x] Add [actionlint](https://github.com/rhysd/actionlint) as the linter (catches invalid syntax, undefined contexts/secrets, bad `runs-on`, shellcheck on `run:` steps, expression type-checking). Wired up via the `reviewdog/action-actionlint` wrapper in `.github/workflows/lint.yml`.
- [x] Add [Prettier](https://prettier.io/) (with YAML support) as the formatter for workflow/action YAML files. Wired up via `npm run format` / `format:check` and checked in `.github/workflows/lint.yml`.
- [ ] Add [zizmor](https://github.com/woodruffw/zizmor) as a security-focused linter (unsanitized `${{ }}` injection in `run:`, overly broad permissions, `pull_request_target` misuse) alongside actionlint in CI.
