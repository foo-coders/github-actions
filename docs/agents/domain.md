# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root, or
- **`CONTEXT-MAP.md`** at the repo root if it exists — it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`docs/adr/`** — read ADRs that touch the area you're about to work in. In multi-context repos, also check that context's own `docs/adr/` directory for context-scoped decisions.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

## File structure

Multi-context repo (this repo) — signalled by `CONTEXT-MAP.md` at the root. Each action is its own context and carries its own `CONTEXT.md` and `docs/adr/` alongside its code; the root `docs/adr/` is for decisions that span the whole repo:

```
/
├── CONTEXT-MAP.md
├── docs/adr/                          ← system-wide decisions
└── actions/
    ├── mise-update/
    │   ├── CONTEXT.md
    │   └── docs/adr/                  ← context-specific decisions
    ├── release-please/
    └── conventional-pr-title/
```

Not every action has a context yet, and the root `docs/adr/` doesn't exist. That's expected — see the note above about proceeding silently.

Single-context repo, for contrast — one `CONTEXT.md` and one `docs/adr/`, both at the root, and no `CONTEXT-MAP.md`:

```
/
├── CONTEXT.md
└── docs/adr/
    ├── 0001-event-sourced-orders.md
    └── 0002-postgres-for-write-model.md
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in the `CONTEXT.md` of the context you're working in. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_
