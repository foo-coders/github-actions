# mise update

Proposes updates to a mise manifest and its lockfile as one pull request. The action discovers what is outdated, decides what it can safely rewrite, rewrites it, re-resolves the lockfile, and hands the result to a pull request.

## Language

### What the action works on

**Manifest**: The mise configuration file that declares a tool and its requested version spec (`mise.toml` and its variants). _Avoid_: config, config file, toml

**Lockfile**: The `mise.lock` alongside the manifest, holding the exact resolved version of each tool. It is what determines the versions CI installs. _Avoid_: lock, mise.lock

**Requested spec**: The version string written against a tool in the manifest — `1.30.0`, `26`, `latest`, `prefix:1.30`. _Avoid_: requested version, constraint, range

**Proposed version**: The version mise suggests replacing a requested spec with. It is never trusted without a sanity check. _Avoid_: new version, target version

### What the engine decides

**Plan**: The engine's verdict on a discovery result: every tool sorted into bumps, skips and errors. The interface between the engine's two modes, and what the tests assert on.

**Bump**: A rewrite of a tool's requested spec in the manifest. Only a semver-shaped spec is ever bumped. _Avoid_: upgrade, update (as a noun for this specific act)

**Move**: A change to a tool's resolved version in the lockfile without any change to its requested spec — what happens when a floating spec like `26` re-resolves. Reported as a _lockfile-only move_ when the same tool was not also bumped. _Avoid_: lockfile bump, re-lock

**Skip**: A tool deliberately left alone because there is nothing to bump — a floating spec such as `latest` or `lts`. Never reported to the reviewer; the lockfile pass still moves it. _Avoid_: ignore, exclude

**Error**: A tool that could have been bumped but wasn't, because something was wrong: an unsupported spec form, an untracked source manifest, or an unsafe proposed version. Always reported, both in the pull request body and as a workflow annotation. _Avoid_: failure, warning, problem

The distinction that carries the weight is **skip** versus **error**: _"there is nothing to bump here"_ against _"this could be bumped and something went wrong"_. Reporting a skip as an error would train reviewers to ignore the error list.

### How it runs

**Engine**: The pure half of the action (`scripts/engine.sh`): it classifies, renders and derives, and never invokes mise or touches the network. Every decision the action makes lives here so it can be tested.

**Discovery**: The one command that asks mise what is outdated, restricted to the consumer's local configuration so the runner's global configuration is never in scope.

**Working directory**: The consumer's mise project root. One working directory yields one branch and one pull request.
