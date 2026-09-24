#!/usr/bin/env bash
set -euo pipefail

# Upstream keys the root component plainly ("tag_name") but prefixes others by path ("actions/x--tag_name").
jq -c --argjson outputs "$RUN_OUTPUTS" \
  '[.[] | {path: ., tag: $outputs[if . == "." then "tag_name" else . + "--tag_name" end]}]' \
  <<<"${PATHS_RELEASED:-[]}"
