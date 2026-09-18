#!/usr/bin/env bash
set -euo pipefail

# The engine is the pure half of this action: it decides what to propose and
# what to write, and never invokes mise or touches the network. Every mode
# reads its inputs from the environment and writes one artifact to stdout, so
# the whole decision surface is exercised by engine.test.sh.
#
#   plan    OUTDATED + TRACKED_PATHS                  -> plan JSON
#   render title|body|annotations
#           PLAN + LOCK_CHANGES + COMMIT_PREFIX       -> pull request text
#   render add-paths
#           PLAN + WORKING_DIRECTORY + WORKSPACE      -> files to commit
#   branch  WORKING_DIRECTORY + BRANCH                -> branch name
#
# See this action's CONTEXT.md for the vocabulary (bump, move, skip, error).

usage() {
  echo "usage: engine.sh plan | render <title|body|annotations> | branch" >&2
  exit 2
}

# Classify every tool mise reported, keyed on its requested version spec. The
# distinction that matters is "this could be bumped and something went wrong"
# (error) versus "there is nothing to bump here" (skip) — reporting a floating
# spec as an error would train reviewers to ignore the error list.
plan() {
  local outdated="${OUTDATED:-}"
  [ -n "$outdated" ] || outdated='{}'

  jq -n -c \
    --argjson outdated "$outdated" \
    --arg tracked "${TRACKED_PATHS:-}" '
    ($tracked | split("\n") | map(select(length > 0))) as $tracked_paths

    # mise proposes a version that is about to be written into a manifest, so
    # it is sanity-checked first. This is not theoretical: mise 2026.9.10
    # turns a requested "prefix:1.30" into a proposed "prefix:prefix:1.1".
    | def unsafe($requested; $proposed):
        ($proposed | test("^[0-9]+[0-9A-Za-z.+_-]*$") | not)
        or ($proposed == $requested)
        or (($requested | contains(":")) and ($proposed | contains(":")));

      # A version spec is not always a string: the array and tool-option forms
      # arrive as an array or an object. Rendering those to text keeps them in
      # the error bucket instead of crashing the classification — one such
      # tool must not cost the whole run.
      def as_text: if type == "string" then . else tojson end;

      def classify:
        {
          name: (.name // ""),
          requested: (.requested // "" | as_text),
          proposed: (.bump // "" | as_text),
          url: (.release_url // null),
          path: (.source.path // "")
        }
        | . + (
            if (.requested == "latest" or .requested == "lts") then
              {bucket: "skipped", reason: "floating"}
            elif (.requested | test("^[0-9]+(\\.[0-9]+){0,2}$") | not) then
              {bucket: "errors", reason: "unsupported version spec"}
            elif (.proposed == "" or .proposed == null) then
              {bucket: "current"}
            elif (.path as $p | $tracked_paths | index($p) | not) then
              {bucket: "errors", reason: "source config file not tracked"}
            elif unsafe(.requested; .proposed) then
              {bucket: "errors", reason: "unsafe proposed version"}
            else
              {bucket: "bumps"}
            end
          );

      [$outdated | to_entries[] | (.value + {name: (.value.name // .key)}) | classify] as $tools
      | {
          bumps: [$tools[] | select(.bucket == "bumps")
            | {name, from: .requested, to: .proposed, release_url: .url, path}],
          skipped: [$tools[] | select(.bucket == "skipped") | {name, requested, reason}],
          errors: [$tools[] | select(.bucket == "errors") | {name, requested, reason}]
        }
  '
}

# A lockfile change identifies its tool by backend ("aqua:zizmor"), except for
# mise's built-in tools, whose backend carries a "core:" prefix the manifest
# never uses ("core:node" is written "node").
render() {
  local artifact="${1:-}"
  case "$artifact" in
    title | body | annotations | add-paths) ;;
    *) usage ;;
  esac

  local plan="${PLAN:-}" lock="${LOCK_CHANGES:-}"
  [ -n "$plan" ] || plan='{}'
  [ -n "$lock" ] || lock='[]'

  jq -n -r \
    --arg artifact "$artifact" \
    --arg prefix "${COMMIT_PREFIX:-chore(deps)}" \
    --arg dir "${WORKING_DIRECTORY:-.}" \
    --arg workspace "${WORKSPACE:-${GITHUB_WORKSPACE:-}}" \
    --argjson plan "$plan" \
    --argjson lock "$lock" '
    def tool_id: ((.backend // .name // "") | sub("^core:"; ""));
    # mise reports an empty list when a tool enters or leaves the lockfile
    # rather than moving between two versions.
    def versions:
      (if type == "array" then join(", ") else (. // "") end)
      | if . == "" then "—" else . end;
    def section($heading; $header; $rows):
      if ($rows | length) == 0 then []
      else ["### " + $heading, ""] + $header + $rows + [""] end;

    (($plan.bumps // []) | map(. + {id: .name})) as $bumps
    | ($bumps | map(.id)) as $bump_ids
    | ($lock | map(. + {id: tool_id})) as $locked
    # A tool bumped in the manifest also moves in the lockfile; listing it in
    # both sections would read as two separate changes and double the count.
    | ($locked | map(select(.id as $i | $bump_ids | index($i) | not))) as $moves
    | (($bump_ids + ($locked | map(.id))) | unique | length) as $count
    | ($plan.errors // []) as $errors

    | if $artifact == "title" then
        $prefix + ": " + (
          if $count == 0 then "update mise tools"
          elif $count == 1 then "update 1 mise tool"
          else "update \($count) mise tools"
          end
        )

      # Only the manifests the plan actually edited, plus the lockfile. A
      # change any other step left in the working tree is not ours to propose.
      elif $artifact == "add-paths" then
        (($dir | ltrimstr("./") | rtrimstr("/")) as $d
         | (if $d == "" or $d == "." then "mise.lock" else $d + "/mise.lock" end)) as $lockfile
        | (($bumps | map(.path | ltrimstr($workspace + "/"))) + [$lockfile])
        | unique
        | join("\n")

      elif $artifact == "annotations" then
        ($errors
          | map("::warning title=mise-update::\(.name) (\(.requested)): \(.reason)")
          | join("\n"))

      else
        (
          section(
            "Manifest bumps";
            ["| Tool | From | To | Release notes |", "| --- | --- | --- | --- |"];
            [$bumps[] | "| `\(.name)` | `\(.from)` | `\(.to)` | "
              + (if .release_url then "[release notes](\(.release_url))" else "" end)
              + " |"]
          )
          + section(
            "Lockfile-only moves";
            ["| Tool | From | To |", "| --- | --- | --- |"];
            [$moves[] | "| `\(.id)` | `\(.old_versions | versions)` | `\(.new_versions | versions)` |"]
          )
          + section(
            "Not updated";
            ["| Tool | Requested | Reason |", "| --- | --- | --- |"];
            [$errors[] | "| `\(.name)` | `\(.requested)` | \(.reason) |"]
          )
          + (if $count == 0 and ($errors | length) == 0
             then ["No mise manifest or lockfile changes.", ""]
             else [] end)
          + [
              "---",
              "",
              "Proposed by [`mise-update`](https://github.com/foo-coders/github-actions/tree/main/actions/mise-update). These versions were never installed by the update run — the CI on this pull request is what verifies them."
            ]
        )
        | join("\n")
      end
  '
}

# One stable branch per working directory, so the pull request is amended in
# place rather than re-opened. The root case cannot simply append the path:
# "mise-update-." is not a legal ref, and "mise-update/<path>" would collide
# with the bare "mise-update" ref in a repo that needs both.
branch() {
  local override="${BRANCH:-}"
  if [ -n "$override" ]; then
    echo "$override"
    return
  fi

  local dir="${WORKING_DIRECTORY:-}"
  dir="${dir#./}"
  local slug
  slug=$(printf '%s' "$dir" |
    sed -e 's|[^A-Za-z0-9._/-]|-|g' \
      -e 's|/|-|g' \
      -e 's|[-.]\{2,\}|-|g' \
      -e 's|^[-.]*||' \
      -e 's|[-.]*$||')

  if [ -z "$slug" ]; then
    echo "mise-update"
  else
    echo "mise-update-$slug"
  fi
}

case "${1:-}" in
  plan) plan ;;
  render) render "${2:-}" ;;
  branch) branch ;;
  *) usage ;;
esac
