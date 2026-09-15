# Dependabot

Why `.github/dependabot.yml` is split into two `github-actions` entries, and how each one's commits reach — or deliberately skip — a published CHANGELOG.

## Two entries, two audiences

The repo's `uses:` references fall into two groups that need opposite handling:

- **`.github/workflows/`** — CI internal to this repo. Nothing here is published, so bumps are grouped into a single PR and prefixed `chore`, which release-please files under "Miscellaneous Chores" and keeps out of any changelog.
- **`actions/*/`** — composite actions released as packages (see [release-please-config.md](release-please-config.md)). Bumps are left ungrouped so each one lands as its own commit, and prefixed `fix` so release-please surfaces it under "Bug Fixes" and cuts a patch release. A grouped PR would collapse several bumps into one changelog entry; a `chore` prefix would cut no release at all.

Release-please attributes a commit to a package by the **file path** it touches, not by the commit scope — so a bump to `actions/<name>/action.yml` lands in that action's changelog whatever Dependabot writes in the scope.

The `/actions/*` glob picks up new actions on its own: adding `actions/<name>/` needs no change here, unlike [release-please-config.md](release-please-config.md), which must be updated.

## Cooldown

`cooldown.default-days` holds a release back for 7 days after it is published, so a version that gets yanked or hotfixed in its first week never reaches a PR here. GitHub applies 3 days by default; 7 is a deliberate tightening.

## Open PR limit

`open-pull-requests-limit` is written out at Dependabot's own default of 5 on the `actions/*` entry only, because ungrouped bumps open one PR per dependency and so reach the cap. Raise it if bumps start queueing. The workflows entry needs no limit: its `"*"` group matches every dependency, so it can only ever have one PR open.

## Reviewing a bump

Dependabot rewrites the pinned SHA and its trailing version comment together, in the shape [pinning-third-party-actions.md](pinning-third-party-actions.md) requires.

A bump inside a [wrapped](wrapping-third-party-actions.md) action needs one extra judgement. Dependabot prefixes it `fix`, which cuts a patch release — right for a patch or minor bump upstream. When the bump crosses a **major** version upstream, rewrite the prefix to `feat!` before merging: callers tracking the rolling `<name>/v<major>` tag would otherwise be handed a breaking upstream change as a patch, which is exactly what wrapping the action was meant to prevent.
