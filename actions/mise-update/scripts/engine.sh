#!/usr/bin/env bash
set -euo pipefail

# Pure: never invokes mise or the network, so engine.test.sh covers every decision.
#
#   plan    OUTDATED + TRACKED_PATHS                  -> plan JSON
#   render title|body|annotations
#           PLAN + LOCK_CHANGES + COMMIT_PREFIX       -> pull request text
#   render add-paths
#           PLAN + WORKING_DIRECTORY + WORKSPACE      -> files to commit
#   branch  WORKING_DIRECTORY + BRANCH                -> branch name

usage() {
  echo "usage: engine.sh plan | render <title|body|annotations> | branch" >&2
  exit 2
}

plan() {
  local outdated="${OUTDATED:-}"
  [ -n "$outdated" ] || outdated='{}'

  jq -n -c \
    --argjson outdated "$outdated" \
    --arg tracked "${TRACKED_PATHS:-}" '
    ($tracked | split("\n") | map(select(length > 0))) as $tracked_paths

    | def unsafe($requested; $proposed):
        ($proposed | test("^[0-9]+[0-9A-Za-z.+_-]*$") | not)
        or ($proposed == $requested)
        or (($requested | contains(":")) and ($proposed | contains(":")));

      # Array and tool-option specs are not strings; one must not crash the run.
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

# The lockfile says "core:node" where the manifest says "node".
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
    # Empty when a tool enters or leaves the lockfile.
    def versions:
      (if type == "array" then join(", ") else (. // "") end)
      | if . == "" then "—" else . end;
    def section($heading; $header; $rows):
      if ($rows | length) == 0 then []
      else ["### " + $heading, ""] + $header + $rows + [""] end;

    (($plan.bumps // []) | map(. + {id: .name})) as $bumps
    | ($bumps | map(.id)) as $bump_ids
    | ($lock | map(. + {id: tool_id})) as $locked
    # A manifest bump also moves the lockfile; list it once.
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

      # Other working-tree changes are not ours to propose.
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

# "mise-update-." is no legal ref, and "mise-update/<path>" would collide with "mise-update".
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
