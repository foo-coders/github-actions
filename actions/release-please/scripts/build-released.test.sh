#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_released="$script_dir/build-released.sh"

failures=0

run_case() {
  local name="$1" paths_released="$2" run_outputs="$3" expected="$4"
  local actual
  actual=$(PATHS_RELEASED="$paths_released" RUN_OUTPUTS="$run_outputs" bash "$build_released")
  if [ "$actual" = "$expected" ]; then
    echo "ok - $name"
  else
    echo "not ok - $name"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    failures=$((failures + 1))
  fi
}

run_case \
  "single package, no explicit path (root)" \
  '["."]' \
  '{"tag_name":"v1.2.3"}' \
  '[{"path":".","tag":"v1.2.3"}]'

run_case \
  "multiple paths including root" \
  '[".", "actions/release-please"]' \
  '{"tag_name":"v1.0.0","actions/release-please--tag_name":"release-please/v2.0.0"}' \
  '[{"path":".","tag":"v1.0.0"},{"path":"actions/release-please","tag":"release-please/v2.0.0"}]'

run_case \
  "nothing released" \
  '[]' \
  '{}' \
  '[]'

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi

echo "all cases passed"
