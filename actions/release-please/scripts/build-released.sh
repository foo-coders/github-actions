#!/usr/bin/env bash
set -euo pipefail

# release-please-action outputs the root component's values under plain
# keys (e.g. "tag_name") but prefixes every other package's keys with its
# path (e.g. "actions/release-please--tag_name"). See "Root component
# outputs" vs "Path outputs" in its README.
jq -c --argjson outputs "$RUN_OUTPUTS" \
  '[.[] | {path: ., tag: $outputs[if . == "." then "tag_name" else . + "--tag_name" end]}]' \
  <<<"${PATHS_RELEASED:-[]}"
