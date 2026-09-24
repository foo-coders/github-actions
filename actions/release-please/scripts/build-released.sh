#!/usr/bin/env bash
set -euo pipefail

jq -c --argjson outputs "$RUN_OUTPUTS" \
  '[.[] | {path: ., tag: $outputs[if . == "." then "tag_name" else . + "--tag_name" end]}]' \
  <<<"${PATHS_RELEASED:-[]}"
