# CLAUDE.md

See [AGENTS.md](AGENTS.md) for repo conventions.

## Worktrees

Pass a worktree `name` of `<type>/<task-slug>`, where `<type>` is the conventional-commit type of the commits the work will produce (e.g. `fix/release-please-pin`).

Creating the worktree derives the branch from that name — prefixing `worktree-` and replacing `/` with `+` — so rename the branch to the name you passed, before the first commit:

```sh
git branch -m <type>/<task-slug>
```
