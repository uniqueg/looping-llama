#!/usr/bin/env bash
# Claude Code PreToolUse hook: refuse file tools on .env and .env.* files, in
# every folder (permission rules like Read(**/.env) only cover the project).
# Follows symlinks. Blocks (exit 2) if the input can't be parsed. Bash is
# covered by the sandbox's denyRead list, not by this hook.
#
# Limit: Grep on a whole directory isn't caught, only a path or glob naming
# such a file.

set -uo pipefail

is_env() {  # is_env <name>
    [[ $1 == .env || $1 == .env.* ]]
}

deny() {
    echo "Blocked: $1 is a .env file, which may hold secrets. Ask the user instead." >&2
    exit 2
}

input=$(cat)
if ! paths=$(jq -er '[.tool_input.file_path, .tool_input.notebook_path, .tool_input.path]
                     | map(select(. != null)) | .[]' <<<"$input" 2>/dev/null); then
    # No path given is fine (Grep in the current folder); broken input is not.
    jq -e . <<<"$input" >/dev/null 2>&1 || { echo "Blocked: can't parse the hook input (is jq installed?)." >&2; exit 2; }
    paths=""
fi

while IFS= read -r path; do
    [[ -n $path ]] || continue
    path=${path/#\~/$HOME}
    is_env "$(basename -- "$path")" && deny "$path"
    is_env "$(basename -- "$(realpath -m -- "$path")")" && deny "$path"
done <<<"$paths"

glob=$(jq -r '.tool_input.glob // empty' <<<"$input")
if [[ $glob == *.env* && $glob != *.envrc* ]]; then
    deny "$glob"
fi

exit 0
