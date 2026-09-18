# Drive mise per file instead of `mise upgrade --bump`

`mise upgrade --bump` does in one command almost exactly what this action needs — rewrite outdated version specs in the manifest — and we deliberately do not use it. Instead the action runs its own sequence: discover with `mise outdated --bump --json --local`, decide, then one `mise config set` per tool, then `mise lock --bump --json`.

## Considered Options

|  | `mise upgrade --bump` | The chosen sequence |
| --- | --- | --- |
| Installs tools | Yes — measured 260MB / ~14.5s against this repo's manifest | No — zero installs, ~14s |
| Failure mode | Exits 1 with the manifest **partially written** | Per tool; no partial manifest writes |
| Known flakiness | `npm:` tools fail when their `node` dependency is bumped in the same run | Not applicable |

Installing is the disqualifying property, not the slowest one. The action's whole contract is that it proposes versions it has _not_ verified, leaving verification to the pull request's own CI (which tests the consumer's real matrix, not whichever runner the update happened to land on). Downloading every toolchain to produce a proposal buys nothing and costs the runner minutes on every scheduled run.

The partial-write failure mode is the reason the ordering can't simply be papered over with a retry: a run that dies halfway leaves a manifest that is internally inconsistent with the lockfile, which is precisely the state this action exists to prevent.

## Consequences

- The action classifies every tool itself, so it needs a rule for every version-spec form mise supports, and needs to be told about new ones. That classification is the engine's main job and is covered by tests.
- Every proposed value is sanity-checked before it is written, because the action now writes them. This is load-bearing: mise 2026.9.10 turns a requested `prefix:1.30` into a proposed `prefix:prefix:1.1`, which would corrupt a consumer's manifest.
- The two commands take a confusingly similar flag. `--local` on `mise outdated` restricts scope to local config, which is what we want; `--global` on `mise lock` selects the runner's global lockfile, which we must never pass. Scope on the two subcommands is not the same idea.
- `mise config set` owns the TOML edit, so this action parses no TOML itself. Its dotted key path must be written **unquoted** for backend-prefixed tools (`tools.aqua:zizmor`) — quoting it silently appends a malformed duplicate key instead of updating the real one. It also drops the inline comment on the line it edits, which the README documents.

If a future mise release makes `mise upgrade --bump` skip installs and write atomically, this is worth revisiting. Until then, do not "simplify" the sequence back into it.
