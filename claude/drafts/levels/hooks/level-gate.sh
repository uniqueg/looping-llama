#!/usr/bin/env bash
# Claude Code PreToolUse hook: enforce the human-review gate of the session's
# autonomy level ($CLAUDE_LEVEL, set by the `claude` fish function) before
# Claude runs `gh pr merge`. Other commands pass through.
#
# - auto: no gate.
# - reviewed, supervised: the PR's current head commit needs an approving
#   review by a human on GitHub, or the user's approval recorded with
#   `claude-approve <PR URL>` (a file under ~/.local/state/claude-levels/,
#   which Claude may not write).
# - external, unknown levels: merges are blocked.
# Blocks (exit 2) and tells Claude why; fails closed if the PR can't be
# resolved.

set -uo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

# Only act on `gh pr merge`, also inside chained commands
re='(^|[;&|(])[[:space:]]*gh[[:space:]]+pr[[:space:]]+merge([[:space:]][^;&|]*)?'
[[ $command =~ $re ]] || exit 0
read -ra args <<<"${BASH_REMATCH[2]:-}"

level=${CLAUDE_LEVEL:-supervised}
block() {
    echo "level-gate ($level): $1" >&2
    exit 2
}

case $level in
    auto) exit 0 ;;
    reviewed | supervised) ;;
    external) block "merging is not allowed at this level." ;;
    *) block "unknown autonomy level; merges are blocked." ;;
esac

# PR selector (number, URL or branch) and --repo/-R
selector=""
repo_args=()
for ((i = 0; i < ${#args[@]}; i++)); do
    case ${args[i]} in
        -R | --repo) repo_args=(--repo "${args[i + 1]:-}"); ((i++)) ;;
        --repo=*) repo_args=(--repo "${args[i]#--repo=}") ;;
        -*) ;;
        *) [[ -z $selector ]] && selector=${args[i]} ;;
    esac
done

cd "${cwd:-.}" 2>/dev/null || true
pr=$(gh pr view ${selector:+"$selector"} "${repo_args[@]}" \
    --json number,headRefOid,url 2>/dev/null) ||
    block "could not resolve the PR to check its review status."
number=$(jq -r .number <<<"$pr")
head=$(jq -r .headRefOid <<<"$pr")
url=$(jq -r .url <<<"$pr")
# https://github.com/<owner>/<repo>/pull/<n>
IFS=/ read -r _ _ _ owner name _ <<<"$url"

# 1. The user's approval for this head commit
marker=$HOME/.local/state/claude-levels/approved/$owner/$name/$number
if [[ -f $marker && $(<"$marker") == "$head" ]]; then
    exit 0
fi

# 2. An approving review by a human (not a bot) on this head commit
query='query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      latestReviews(first: 50) {
        nodes { state author { __typename } commit { oid } }
      }
    }
  }
}'
approved=$(gh api graphql -F owner="$owner" -F name="$name" \
    -F number="$number" -f query="$query" --jq "[
        .data.repository.pullRequest.latestReviews.nodes[]
        | select(.state == \"APPROVED\" and .author.__typename == \"User\"
                 and .commit.oid == \"$head\")
    ] | length" 2>/dev/null) ||
    block "could not read the reviews of $url."
if [[ ${approved:-0} -gt 0 ]]; then
    exit 0
fi

block "no human review for $url at ${head:0:7}. Ask the user to review it \
and approve on GitHub, or to run: claude-approve $url"
