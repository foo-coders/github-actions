# Code comments

A comment says **why**, never **what**. Write one only when the reason, constraint or gotcha behind a line can't be recovered from the code itself — the kind of line a reader would otherwise "fix" and break.

- **One line by preference.** A comment that needs a paragraph is usually telling a story; tell it in the commit message or pull request instead, where `git blame` finds it, and keep only the warning inline.
- **Don't duplicate the docs.** When `docs/`, an action's `README.md`, `CONTEXT.md` or an ADR already explains something, the code carries no comment about it — not even a pointer to the doc. Docs are found through `AGENTS.md` and the READMEs, and a pointer in code goes stale when the doc moves.
- **Functions get a one-line description.** The one "what" allowed: a single line above each shell function saying what it does.
- **Repeated across files, still one line.** A reason that applies in several workflows is repeated in each, since a workflow is often read on its own, but kept to a single line.

## Required comments

These are mandated elsewhere and are not subject to the rules above:

- The trailing version comment on a SHA-pinned `uses:` — see [pinning-third-party-actions.md](pinning-third-party-actions.md).
- The same-line comment on every granted `permissions:` scope — see [workflow-permissions.md](workflow-permissions.md).

Tool directives (`# zizmor: ignore[...]`) and section dividers in long test files (`# --- Classification ---`) are fine as they are.
