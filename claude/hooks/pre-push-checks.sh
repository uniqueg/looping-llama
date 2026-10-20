#!/usr/bin/env bash
# Claude Code PreToolUse hook: run semgrep and ast-grep on the files a branch
# changes before Claude runs `git push`. Blocks the push (exit 2) and shows
# the findings to Claude if any check fails. Other commands pass through.
#
# - semgrep: uses the repository's .semgrep.yml / .semgrep/ if present,
#   otherwise $SEMGREP_CONFIGS (default: "p/python p/secrets").
# - ast-grep: runs only if the repository has an sgconfig.yml.
# Missing tools are reported as a warning, not an error.

set -uo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

# Only act on `git push` and `git -C <dir> push`
if [[ ! $command =~ ^[[:space:]]*git([[:space:]]+-C[[:space:]]+([^[:space:]]+))?[[:space:]]+push([[:space:]]|$) ]]; then
    exit 0
fi
repo=${BASH_REMATCH[2]:-$cwd}
repo=${repo/#\~/$HOME}
cd "$repo" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Base: merge base with the remote's default branch
base_ref=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null)
for ref in "$base_ref" origin/dev origin/main origin/master; do
    if [[ -n $ref ]] && git rev-parse --verify -q "$ref" >/dev/null; then
        base_ref=$ref
        break
    fi
done
base=$(git merge-base "$base_ref" HEAD 2>/dev/null) || exit 0

mapfile -t files < <(git diff --name-only --diff-filter=ACMR "$base" HEAD)
[[ ${#files[@]} -eq 0 ]] && exit 0

status=0
report=""

if command -v semgrep >/dev/null 2>&1; then
    configs=()
    if [[ -e .semgrep.yml || -d .semgrep ]]; then
        [[ -e .semgrep.yml ]] && configs+=(--config .semgrep.yml)
        [[ -d .semgrep ]] && configs+=(--config .semgrep)
    else
        for c in ${SEMGREP_CONFIGS:-p/python p/secrets}; do
            configs+=(--config "$c")
        done
    fi
    if ! out=$(semgrep scan --error --quiet --metrics=off "${configs[@]}" "${files[@]}" 2>&1); then
        status=2
        report+=$'semgrep findings:\n'"$out"$'\n\n'
    fi
else
    report+=$'warning: semgrep not installed; skipped\n'
fi

if [[ -e sgconfig.yml ]]; then
    if command -v ast-grep >/dev/null 2>&1; then
        if ! out=$(ast-grep scan "${files[@]}" 2>&1); then
            status=2
            report+=$'ast-grep findings:\n'"$out"$'\n\n'
        fi
    else
        report+=$'warning: ast-grep not installed; skipped\n'
    fi
fi

if [[ $status -ne 0 ]]; then
    echo "Push blocked by pre-push checks (changed files since $base_ref):" >&2
    echo "$report" >&2
    echo "Fix the findings (or justify ignoring them with an inline suppression), commit, and push again." >&2
    exit 2
fi
[[ -n $report ]] && echo "$report" >&2
exit 0
