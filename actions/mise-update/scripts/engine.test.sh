#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
engine="$script_dir/engine.sh"

failures=0

assert() {
  local name="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "ok - $name"
  else
    echo "not ok - $name"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    failures=$((failures + 1))
  fi
}

# Compared as JSON so cases can span lines without asserting on key order.
run_plan() {
  local name="$1" outdated="$2" tracked="$3" expected="$4"
  local actual
  actual=$(OUTDATED="$outdated" TRACKED_PATHS="$tracked" bash "$engine" plan | jq -S -c .)
  assert "$name" "$(jq -S -c . <<<"$expected")" "$actual"
}

run_render() {
  local name="$1" artifact="$2" plan="$3" lock="$4" prefix="$5" expected="$6"
  local actual
  actual=$(PLAN="$plan" LOCK_CHANGES="$lock" COMMIT_PREFIX="$prefix" \
    bash "$engine" render "$artifact")
  assert "$name" "$expected" "$actual"
}

run_add_paths() {
  local name="$1" plan="$2" working_directory="$3" workspace="$4" expected="$5"
  local actual
  actual=$(PLAN="$plan" WORKING_DIRECTORY="$working_directory" WORKSPACE="$workspace" \
    bash "$engine" render add-paths)
  assert "$name" "$expected" "$actual"
}

run_branch() {
  local name="$1" working_directory="$2" override="$3" expected="$4"
  local actual
  actual=$(WORKING_DIRECTORY="$working_directory" BRANCH="$override" bash "$engine" branch)
  assert "$name" "$expected" "$actual"
}

# --- Classification -------------------------------------------------------

run_plan \
  "a semver-shaped spec is bumped" \
  '{"aqua:zizmor":{"name":"aqua:zizmor","requested":"1.30.0","current":null,"bump":"1.30.1","latest":"1.30.1","release_url":"https://example.test/zizmor/1.30.1","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[{"name":"aqua:zizmor","from":"1.30.0","to":"1.30.1","release_url":"https://example.test/zizmor/1.30.1","path":"/repo/mise.toml"}],"skipped":[],"errors":[]}'

run_plan \
  "a backend that publishes no release notes bumps with a null link" \
  '{"npm:prettier":{"name":"npm:prettier","requested":"3.9.6","bump":"3.9.7","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[{"name":"npm:prettier","from":"3.9.6","to":"3.9.7","release_url":null,"path":"/repo/mise.toml"}],"skipped":[],"errors":[]}'

run_plan \
  "a major-only spec is bumped" \
  '{"node":{"name":"node","requested":"26","bump":"27","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[{"name":"node","from":"26","to":"27","release_url":null,"path":"/repo/mise.toml"}],"skipped":[],"errors":[]}'

run_plan \
  "floating specs are skipped silently, not reported as errors" \
  '{"node":{"name":"node","requested":"latest","bump":"26.9.0","source":{"type":"mise.toml","path":"/repo/mise.toml"}},"java":{"name":"java","requested":"lts","bump":"25.0.1","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[{"name":"node","requested":"latest","reason":"floating"},{"name":"java","requested":"lts","reason":"floating"}],"errors":[]}'

run_plan \
  "unsupported spec forms are reported as errors, not rewritten" \
  '{"aqua:a":{"name":"aqua:a","requested":"ref:main","bump":"1.0.0","source":{"type":"mise.toml","path":"/repo/mise.toml"}},"aqua:b":{"name":"aqua:b","requested":"path:/opt/b","bump":"1.0.0","source":{"type":"mise.toml","path":"/repo/mise.toml"}},"aqua:c":{"name":"aqua:c","requested":"sub-2:latest","bump":"1.0.0","source":{"type":"mise.toml","path":"/repo/mise.toml"}},"aqua:d":{"name":"aqua:d","requested":"1.2.3.4","bump":"1.2.3.5","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[],"errors":[{"name":"aqua:a","requested":"ref:main","reason":"unsupported version spec"},{"name":"aqua:b","requested":"path:/opt/b","reason":"unsupported version spec"},{"name":"aqua:c","requested":"sub-2:latest","reason":"unsupported version spec"},{"name":"aqua:d","requested":"1.2.3.4","reason":"unsupported version spec"}]}'

run_plan \
  "array and tool-option specs are reported, not crashed on" \
  '{"node":{"name":"node","requested":["20","22"],"bump":"22.1.0","source":{"type":"mise.toml","path":"/repo/mise.toml"}},"python":{"name":"python","requested":{"version":"3.12","postinstall":"x"},"bump":"3.13","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[],"errors":[{"name":"node","requested":"[\"20\",\"22\"]","reason":"unsupported version spec"},{"name":"python","requested":"{\"version\":\"3.12\",\"postinstall\":\"x\"}","reason":"unsupported version spec"}]}'

run_plan \
  "one unsupported tool does not cost the bumps alongside it" \
  '{"node":{"name":"node","requested":["20","22"],"bump":"22.1.0","source":{"type":"mise.toml","path":"/repo/mise.toml"}},"aqua:zizmor":{"name":"aqua:zizmor","requested":"1.30.0","bump":"1.30.1","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[{"name":"aqua:zizmor","from":"1.30.0","to":"1.30.1","release_url":null,"path":"/repo/mise.toml"}],"skipped":[],"errors":[{"name":"node","requested":"[\"20\",\"22\"]","reason":"unsupported version spec"}]}'

run_plan \
  "a tool that is already current is neither bumped nor reported" \
  '{"aqua:actionlint":{"name":"aqua:actionlint","requested":"1.7.12","bump":null,"latest":"1.7.12","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[],"errors":[]}'

run_plan \
  "no tools at all yields an empty plan" \
  '{}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[],"errors":[]}'

# --- The corruption guard -------------------------------------------------

run_plan \
  "the observed prefix: corruption is reported, never written" \
  '{"aqua:foo":{"name":"aqua:foo","requested":"prefix:1.30","bump":"prefix:prefix:1.1","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[],"errors":[{"name":"aqua:foo","requested":"prefix:1.30","reason":"unsupported version spec"}]}'

run_plan \
  "a proposal that is not version-shaped is refused" \
  '{"aqua:foo":{"name":"aqua:foo","requested":"1.30","bump":"prefix:1.1","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[],"errors":[{"name":"aqua:foo","requested":"1.30","reason":"unsafe proposed version"}]}'

run_plan \
  "a proposal identical to the requested spec is refused" \
  '{"aqua:foo":{"name":"aqua:foo","requested":"1.7.12","bump":"1.7.12","source":{"type":"mise.toml","path":"/repo/mise.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[],"errors":[{"name":"aqua:foo","requested":"1.7.12","reason":"unsafe proposed version"}]}'

# --- The tracked-file filter ----------------------------------------------

run_plan \
  "a tool sourced from an untracked config is an error, not a bump" \
  '{"aqua:zizmor":{"name":"aqua:zizmor","requested":"1.30.0","bump":"1.30.1","source":{"type":"mise.toml","path":"/repo/mise.local.toml"}}}' \
  '/repo/mise.toml' \
  '{"bumps":[],"skipped":[],"errors":[{"name":"aqua:zizmor","requested":"1.30.0","reason":"source config file not tracked"}]}'

run_plan \
  "tracked and untracked sources are separated within one run" \
  '{"aqua:zizmor":{"name":"aqua:zizmor","requested":"1.30.0","bump":"1.30.1","source":{"type":"mise.toml","path":"/repo/mise.toml"}},"npm:prettier":{"name":"npm:prettier","requested":"3.9.6","bump":"3.9.7","source":{"type":"mise.toml","path":"/repo/mise.local.toml"}}}' \
  '/repo/mise.toml
/repo/sub/mise.toml' \
  '{"bumps":[{"name":"aqua:zizmor","from":"1.30.0","to":"1.30.1","release_url":null,"path":"/repo/mise.toml"}],"skipped":[],"errors":[{"name":"npm:prettier","requested":"3.9.6","reason":"source config file not tracked"}]}'

# --- Branch derivation ----------------------------------------------------

run_branch "the root working directory yields the bare branch name" "." "" "mise-update"
run_branch "an unset working directory yields the bare branch name" "" "" "mise-update"
run_branch "a nested path is prefixed and flattened" "packages/app" "" "mise-update-packages-app"
run_branch "a leading ./ is ignored" "./packages/app" "" "mise-update-packages-app"
run_branch \
  "characters that are illegal or awkward in a ref are sanitised" \
  "./sub dir/../weird..name." "" \
  "mise-update-sub-dir-weird-name"
run_branch "an explicit branch overrides the derivation" "packages/app" "my-branch" "my-branch"

# --- Rendering ------------------------------------------------------------

bumps_plan='{"bumps":[{"name":"aqua:zizmor","from":"1.30.0","to":"1.30.1","release_url":"https://example.test/zizmor/1.30.1","path":"/repo/mise.toml"},{"name":"npm:prettier","from":"3.9.6","to":"3.9.7","release_url":null,"path":"/repo/mise.toml"}],"skipped":[],"errors":[]}'
empty_plan='{"bumps":[],"skipped":[],"errors":[]}'
errors_plan='{"bumps":[],"skipped":[],"errors":[{"name":"aqua:foo","requested":"prefix:1.30","reason":"unsupported version spec"}]}'
node_move='[{"name":"node","backend":"core:node","old_versions":["26.8.2"],"new_versions":["26.9.0"]}]'
mixed_moves='[{"name":"node","backend":"core:node","old_versions":["26.8.2"],"new_versions":["26.9.0"]},{"name":"aqua:zizmor","backend":"aqua:zizmor","old_versions":["1.30.0"],"new_versions":["1.30.1"]},{"name":"npm:prettier","backend":"npm:prettier","old_versions":["3.9.6"],"new_versions":["3.9.7"]}]'

footer=$'---\n\nProposed by [`mise-update`](https://github.com/foo-coders/github-actions/tree/main/actions/mise-update). These versions were never installed by the update run — the CI on this pull request is what verifies them.'

run_render \
  "the title counts manifest bumps and lockfile-only moves once each" \
  title "$bumps_plan" "$mixed_moves" "chore(deps)" \
  "chore(deps): update 3 mise tools"

run_render \
  "a single tool is counted in the singular" \
  title "$empty_plan" "$node_move" "chore(deps)" \
  "chore(deps): update 1 mise tool"

run_render \
  "a run with nothing to propose gets a countless title" \
  title "$empty_plan" '[]' "chore(deps)" \
  "chore(deps): update mise tools"

run_render \
  "the commit prefix is caller-chosen" \
  title "$empty_plan" "$node_move" "fix(deps)" \
  "fix(deps): update 1 mise tool"

run_render \
  "a manifest-only run lists bumps, and leaves an absent release link blank" \
  body "$bumps_plan" '[]' "chore(deps)" \
  "$(
    cat <<'EOF'
### Manifest bumps

| Tool | From | To | Release notes |
| --- | --- | --- | --- |
| `aqua:zizmor` | `1.30.0` | `1.30.1` | [release notes](https://example.test/zizmor/1.30.1) |
| `npm:prettier` | `3.9.6` | `3.9.7` |  |

EOF
  )"$'\n\n'"$footer"

run_render \
  "a lockfile-only run lists moves under their own heading" \
  body "$empty_plan" "$node_move" "chore(deps)" \
  "$(
    cat <<'EOF'
### Lockfile-only moves

| Tool | From | To |
| --- | --- | --- |
| `node` | `26.8.2` | `26.9.0` |

EOF
  )"$'\n\n'"$footer"

run_render \
  "a mixed run shows a bumped tool only under manifest bumps" \
  body "$bumps_plan" "$mixed_moves" "chore(deps)" \
  "$(
    cat <<'EOF'
### Manifest bumps

| Tool | From | To | Release notes |
| --- | --- | --- | --- |
| `aqua:zizmor` | `1.30.0` | `1.30.1` | [release notes](https://example.test/zizmor/1.30.1) |
| `npm:prettier` | `3.9.6` | `3.9.7` |  |

### Lockfile-only moves

| Tool | From | To |
| --- | --- | --- |
| `node` | `26.8.2` | `26.9.0` |

EOF
  )"$'\n\n'"$footer"

run_render \
  "a tool entering or leaving the lockfile renders without an empty cell" \
  body "$empty_plan" '[{"name":"aqua:zizmor","backend":"aqua:zizmor","old_versions":[],"new_versions":["1.29.0"]},{"name":"npm:prettier","backend":"npm:prettier","old_versions":["3.9.6"],"new_versions":[]}]' "chore(deps)" \
  "$(
    cat <<'EOF'
### Lockfile-only moves

| Tool | From | To |
| --- | --- | --- |
| `aqua:zizmor` | `—` | `1.29.0` |
| `npm:prettier` | `3.9.6` | `—` |
EOF
  )"$'\n\n'"$footer"

run_render \
  "errors are listed in the body alongside the changes" \
  body "$errors_plan" "$node_move" "chore(deps)" \
  "$(
    cat <<'EOF'
### Lockfile-only moves

| Tool | From | To |
| --- | --- | --- |
| `node` | `26.8.2` | `26.9.0` |

### Not updated

| Tool | Requested | Reason |
| --- | --- | --- |
| `aqua:foo` | `prefix:1.30` | unsupported version spec |

EOF
  )"$'\n\n'"$footer"

run_render \
  "a run with no changes at all says so" \
  body "$empty_plan" '[]' "chore(deps)" \
  "$(
    cat <<'EOF'
No mise manifest or lockfile changes.

EOF
  )"$'\n\n'"$footer"

# --- Files to commit ------------------------------------------------------

run_add_paths \
  "only the edited manifests and the lockfile are committed" \
  '{"bumps":[{"name":"aqua:zizmor","from":"1.30.0","to":"1.30.1","release_url":null,"path":"/ws/mise.toml"}]}' \
  "." "/ws" \
  "$(printf 'mise.lock\nmise.toml')"

run_add_paths \
  "a lockfile-only run still commits the lockfile" \
  "$empty_plan" "." "/ws" \
  "mise.lock"

run_add_paths \
  "paths are relative to the workspace, under a nested working directory" \
  '{"bumps":[{"name":"aqua:zizmor","from":"1.30.0","to":"1.30.1","release_url":null,"path":"/ws/packages/app/mise.toml"}]}' \
  "packages/app" "/ws" \
  "$(printf 'packages/app/mise.lock\npackages/app/mise.toml')"

run_add_paths \
  "a working directory written as ./dir/ resolves the same way" \
  "$empty_plan" "./packages/app/" "/ws" \
  "packages/app/mise.lock"

run_add_paths \
  "two tools sharing one manifest list it once" \
  '{"bumps":[{"name":"a","from":"1","to":"2","release_url":null,"path":"/ws/mise.toml"},{"name":"b","from":"1","to":"2","release_url":null,"path":"/ws/mise.toml"}]}' \
  "." "/ws" \
  "$(printf 'mise.lock\nmise.toml')"

run_render \
  "errors are surfaced as workflow annotations" \
  annotations "$errors_plan" '[]' "chore(deps)" \
  "::warning title=mise-update::aqua:foo (prefix:1.30): unsupported version spec"

run_render \
  "a clean run emits no annotations" \
  annotations "$empty_plan" "$node_move" "chore(deps)" \
  ""

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi

echo "all cases passed"
