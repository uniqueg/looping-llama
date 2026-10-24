#!/usr/bin/env bash
# Install the autonomy levels, the reporting/notification setup and the
# updated global rules into agent-stack and $HOME. Run it yourself, in a
# normal terminal (not inside Claude), when no Claude session is working:
# running sessions reload the new base settings immediately.
#
#   bash ~/Work/private/looping-llama/claude/drafts/levels/install.sh
#
# Everything it replaces is copied to ~/.local/state/looping-llama/install-<timestamp>/
# first. It is safe to run again.
set -euo pipefail

STACK=$HOME/Work/private/looping-llama
SRC=$STACK/claude/drafts/levels
TS=$(date +%Y%m%d%H%M%S)
BACKUP=$HOME/.local/state/looping-llama/install-$TS
FOCA_LOCAL=$HOME/Work/elixir/foca/CLAUDE.local.md

step() { printf '\n== %s\n' "$*"; }
save() {  # save <path>: copy into the backup folder, keeping the path
  [[ -e $1 ]] || return 0
  mkdir -p "$BACKUP$(dirname "$1")"
  cp -a "$1" "$BACKUP$1"
}

step "Checks"
for tool in python3 jq fish curl gh git; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done
[[ -f $SRC/settings.base.json ]] || { echo "drafts not found in $SRC" >&2; exit 1; }
read -rp "Install into $STACK and \$HOME (backups in $BACKUP)? [y/N] " ok
[[ $ok == [yY] ]] || exit 1

step "Backups"
for f in "$HOME"/.claude-*/settings.json "$HOME/.config/fish/config.fish" \
    "$HOME/.config/fish/functions/claude-merge.fish" "$FOCA_LOCAL" \
    "$STACK/claude/CLAUDE.md" "$STACK/claude/settings.base.json" "$STACK/link.sh" \
    "$STACK/claude/levels" "$STACK/claude/drafts/claude-merge.fish" \
    "$STACK/claude/drafts/autonomy-levels.md" "$STACK/claude/drafts/overnight-setup.md" \
    "$STACK/claude/drafts/review-setup" "$STACK/claude/skills/implement-issue/SKILL.md" \
    "$STACK/direnv" "$STACK/later/README.md" "$STACK/.gitignore" \
    "$STACK/claude/settings.base.json.bak.20261020032858" "$STACK/claude-academic_tree.txt" \
    "$STACK/work_agent-stack_tree.txt" "$STACK/work_claude_tree.txt"; do
  save "$f"
done
echo "  $BACKUP"

step "agent-stack files"
rm -rf "$STACK/claude/levels"
cp -r "$SRC/levels" "$STACK/claude/levels"
cp "$SRC/README.md" "$STACK/claude/levels/README.md"
install -m 755 "$SRC/hooks/level-gate.sh" "$STACK/claude/hooks/level-gate.sh"
install -D -m 755 "$SRC/bin/claude-notify" "$STACK/claude/bin/claude-notify"
install -D -m 755 "$SRC/bin/claude-statusline" "$STACK/claude/bin/claude-statusline"
install -D -m 644 -t "$STACK/fish" "$SRC"/fish/*.fish
install -m 644 "$SRC/CLAUDE.md" "$STACK/claude/CLAUDE.md"
install -m 644 "$SRC/settings.base.json" "$STACK/claude/settings.base.json"
install -m 755 "$SRC/link.sh" "$STACK/link.sh"
if [[ -f $SRC/README.agent-stack.md ]]; then
  save "$STACK/README.md"
  install -m 644 "$SRC/README.agent-stack.md" "$STACK/README.md"
fi
install -m 644 "$SRC/skills/implement-issue/SKILL.md" "$STACK/claude/skills/implement-issue/SKILL.md"
# Tidying: persona `none` wording, a dead link, clutter
install -m 644 "$SRC/direnv/none.envrc" "$STACK/direnv/none.envrc"
install -m 755 "$SRC/direnv/no-agent/claude" "$STACK/direnv/no-agent/claude"
sed -i 's|See `../../agent-stack-response-v7.md` §2 step 6 and §3.|No notes kept.|' "$STACK/later/README.md"
rm -f "$STACK/claude/settings.base.json.bak.20261020032858" "$STACK/claude-academic_tree.txt" \
  "$STACK/work_agent-stack_tree.txt" "$STACK/work_claude_tree.txt"
grep -qxF 'claude/skills/synced/' "$STACK/.gitignore" ||
  printf '\n# Skills synced from claude.ai (not maintained here)\nclaude/skills/synced/\n' >>"$STACK/.gitignore"
# Drafts that are applied (or superseded) now
rm -rf "$STACK/claude/drafts/claude-merge.fish" "$STACK/claude/drafts/autonomy-levels.md" \
  "$STACK/claude/drafts/overnight-setup.md" "$STACK/claude/drafts/review-setup"
echo "  levels, level-gate.sh, claude-notify, fish functions, CLAUDE.md, settings.base.json, link.sh"

step "fish"
rm -f "$HOME/.config/fish/functions/claude-merge.fish"
# Profile wrappers must call the `claude` function, not the binary via `env`
sed -i 's/^\([[:space:]]*\)env CLAUDE_CONFIG_DIR=/\1CLAUDE_CONFIG_DIR=/' "$HOME/.config/fish/config.fish"
grep -n 'CLAUDE_CONFIG_DIR=' "$HOME/.config/fish/config.fish" | sed 's/^/  /' || true

step "agent clones"
# Clones and worktrees of agents survive reboots here (unlike /tmp);
# writable for the sandbox via settings.base.json (sandbox.filesystem.allowWrite)
mkdir -p "$HOME/Work/agent-clones"
echo "  $HOME/Work/agent-clones ready"

step "ntfy"
conf=$HOME/.config/claude-notify/config
if [[ -f $conf ]]; then
  echo "  $conf exists, kept"
else
  read -rp "  ntfy URL (e.g. https://ntfy.sh/<long random topic>): " url
  read -rsp "  ntfy access token (optional, Enter to skip): " token; echo
  mkdir -p "$(dirname "$conf")"
  (
    umask 077
    echo "NTFY_URL=$url" >"$conf"
    if [[ -n $token ]]; then echo "NTFY_TOKEN=$token" >>"$conf"; fi
  )
  echo "  wrote $conf"
fi

step "Local overrides"
if [[ -f $FOCA_LOCAL ]] && grep -q 'Exception to the global "never merge" rule' "$FOCA_LOCAL"; then
  rm "$FOCA_LOCAL"
  echo "  removed $FOCA_LOCAL (merge exception, now decided by the level)"
fi

step "link.sh"
"$STACK/link.sh"

step "Verify"
python3 - "$HOME" <<'PY'
import json, sys
home = sys.argv[1]
for p in ("academic", "personal"):
    s = json.load(open(f"{home}/.claude-{p}/settings.json"))
    perms = s["permissions"]
    hooks = json.dumps(s.get("hooks", {}))
    checks = {
        "force-push denied": "Bash(git push --force*)" in perms["deny"],
        "secrets denied": "Read(**/.env)" in perms["deny"],
        "merge not denied in base": "Bash(gh pr merge *)" not in perms["deny"],
        "level gate hook": "level-gate.sh" in hooks,
        "notify hook": "claude-notify" in hooks,
    }
    bad = [k for k, ok in checks.items() if not ok]
    print(f"  {p}: " + ("ok" if not bad else "FAILED: " + ", ".join(bad)))
PY
fish -c 'functions -q claude claude-approve' && echo "  fish functions: ok"
fish -c 'claude --level none-such' 2>&1 | sed 's/^/  /' || true
if claude-notify "agent-stack: notifications work"; then
  echo "  ntfy: sent a test push"
else
  echo "  ntfy: FAILED, check $conf"
fi

step "Next"
cat <<EOF
  1. Start sessions with a level, e.g.:
       claude-p --level auto -c      (continue the last session in this directory)
       claude-a -w fix-123           (default: supervised)
  2. For forks, add 'export CLAUDE_LEVEL=external' to the directory's .envrc.
  3. Commit agent-stack:
       cd ~/Work/private/looping-llama
       rm -r claude/drafts/levels
       git rm -r -q --cached claude/skills/synced
       git add -A
       git commit -m "feat: add autonomy levels" -m "Levels auto, reviewed, supervised and external, chosen per session
with claude --level; review gate before merges, ntfy notifications,
reporting rules, and link.sh merging settings like Claude Code."
  Backups: $BACKUP
EOF
