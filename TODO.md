# TODO

## Tooling for GitHub Actions workflows / composite actions

- [ ] Add [actionlint](https://github.com/rhysd/actionlint) as the linter (catches invalid syntax, undefined
      contexts/secrets, bad `runs-on`, shellcheck on `run:` steps, expression type-checking). Wire up via
      pre-commit hook and/or a CI workflow (`rhysd/actionlint` action / `reviewdog` wrapper).
- [ ] Add [Prettier](https://prettier.io/) (with YAML support) as the formatter for workflow/action YAML files.
      Alternative: `yamlfmt` if avoiding Node-based tooling.
- [ ] Add [zizmor](https://github.com/woodruffw/zizmor) as a security-focused linter (unsanitized `${{ }}`
      injection in `run:`, overly broad permissions, `pull_request_target` misuse) alongside actionlint in CI.
