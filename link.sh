#!/usr/bin/env bash
# Install agent-stack config into $HOME by symlinking/rendering from this repo.
# Idempotent; existing files that would be replaced are backed up as *.bak.<timestamp>.
# Usage: ./link.sh            (WORK_ROOT defaults to ~/Work)
set -euo pipefail

AGENT_STACK=$(cd "$(dirname "$0")" && pwd)
WORK_ROOT=${WORK_ROOT:-$HOME/Work}
TS=$(date +%Y%m%d%H%M%S)

backup() {  # move a real file/dir (not our symlink) out of the way
  if [[ -e $1 && ! -L $1 ]]; then mv "$1" "$1.bak.$TS"; echo "  backed up $1 -> $1.bak.$TS"; fi
}
link() {  # link <target-in-repo> <path-in-home>
  mkdir -p "$(dirname "$2")"
  backup "$2"
  ln -sfn "$1" "$2"
  echo "  $2 -> $1"
}

echo "== Claude Code profiles"
for p in academic; do  # add personas here (work is parked in later/)
  cfg=$HOME/.claude-$p
  mkdir -p "$cfg"
  overlay=$AGENT_STACK/claude/settings.$p.json
  rendered=$(python3 - "$AGENT_STACK" "$overlay" <<'PY'
import json, os, sys
stack, overlay = sys.argv[1], sys.argv[2]
with open(f"{stack}/claude/settings.base.json") as f:
    s = json.load(f)
if os.path.exists(overlay):
    with open(overlay) as f:
        s.update(json.load(f))
print(json.dumps(s, indent=2))
PY
)
  if [[ -f $cfg/settings.json ]] && [[ $(cat "$cfg/settings.json") == "$rendered" ]]; then
    echo "  $cfg/settings.json up to date"
  else
    backup "$cfg/settings.json"
    printf '%s\n' "$rendered" > "$cfg/settings.json"
    echo "  wrote $cfg/settings.json"
  fi
  link "$AGENT_STACK/claude/CLAUDE.md" "$cfg/CLAUDE.md"
  link "$AGENT_STACK/claude/skills" "$cfg/skills"
  mkdir -p "$HOME/.config/gh-$p" && chmod 700 "$HOME/.config/gh-$p"
done

echo "== Persona directories (direnv + git identity)"
while read -r dir persona; do
  [[ -z $dir || $dir == \#* ]] && continue
  root=$WORK_ROOT/$dir
  if [[ ! -d $root ]]; then echo "  skip $root (missing)"; continue; fi
  line="source_env $AGENT_STACK/direnv/$persona.envrc"
  if [[ ! -f $root/.envrc ]]; then
    printf '%s\n' "$line" > "$root/.envrc"; echo "  wrote $root/.envrc ($persona)"
  elif ! grep -qxF "$line" "$root/.envrc"; then
    echo "  WARNING: $root/.envrc exists without '$line' - add it manually"
  fi
  gitcfg=$AGENT_STACK/git/$persona.gitconfig
  [[ -f $gitcfg ]] || continue  # persona without its own git identity (none)
  key="includeIf.gitdir:$root/.path"
  if ! git config --global --get-all "$key" 2>/dev/null | grep -qxF "$gitcfg"; then
    git config --global --add "$key" "$gitcfg"
    echo "  git: $root/ -> $persona identity"
  fi
done < "$AGENT_STACK/personas.map"

echo
echo "Done. Next: run 'direnv allow' in each persona directory listed above."
