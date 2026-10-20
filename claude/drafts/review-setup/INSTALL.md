# Review gate: install steps (fish)

What gets installed:

| File | Goes to | Purpose |
|---|---|---|
| `agents/adversarial-reviewer.md` | `claude/agents/` → linked as `~/.claude-{personal,academic}/agents` | correctness/security reviewer subagent |
| `agents/quality-reviewer.md` | same | Sourcery-like maintainability reviewer (runs on Sonnet) |
| `hooks/pre-push-checks.sh` | `claude/hooks/` (referenced by absolute path) | `PreToolUse` hook: semgrep/ast-grep before `git push` |
| `settings-snippet.json` | merged into both live `settings.json` + `settings.base.json` | registers the hook |
| `CLAUDE.md.new` | replaces `claude/CLAUDE.md` | new workflow step 6 (steps 6–8 → 7–9, references updated) |

## 1. Tools

```fish
mise use -g semgrep ast-grep pre-commit
semgrep --version; ast-grep --version; jq --version
```

`/usr/bin/sg` is shadow-utils, not ast-grep: always call `ast-grep`.

## 2. Move agents and hook into agent-stack

```fish
cd ~/Work/agent-stack
mkdir -p claude/agents claude/hooks
mv claude/drafts/review-setup/agents/*.md claude/agents/
mv claude/drafts/review-setup/hooks/pre-push-checks.sh claude/hooks/
chmod +x claude/hooks/pre-push-checks.sh
```

## 3. Link the agents into both profiles

```fish
for p in personal academic
    ln -sfn ~/Work/agent-stack/claude/agents ~/.claude-$p/agents
end
```

So that `link.sh` keeps doing this, add a line after the `skills` link
(around line 44):

```fish
sed -i 's|^  link "$AGENT_STACK/claude/skills" "$cfg/skills"$|&\n  link "$AGENT_STACK/claude/agents" "$cfg/agents"|' link.sh
grep -n 'claude/agents' link.sh
```

## 4. Register the hook

Your live `settings.json` files have diverged from `settings.base.json`
(auto mode, extra permissions, `git commit`/`git fetch` excluded from the
sandbox, ...). Running `link.sh` would overwrite them with the stale base
(it makes a backup). So patch the live files directly, and the base too:

```fish
set snip ~/Work/agent-stack/claude/drafts/review-setup/settings-snippet.json
for f in ~/.claude-personal/settings.json ~/.claude-academic/settings.json ~/Work/agent-stack/claude/settings.base.json
    cp $f $f.bak.(date +%Y%m%d%H%M%S)
    jq --indent 2 --slurpfile s $snip '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + $s[0].hooks.PreToolUse)' $f > $f.tmp
    and mv $f.tmp $f
end
jq '.hooks' ~/.claude-personal/settings.json
```

(Run it once; a second run would add the hook twice.)

Recommended separately: bring `settings.base.json` and the overlays up to
date with the live files, so that `link.sh` is safe to run again.

## 5. CLAUDE.md

```fish
cd ~/Work/agent-stack/claude
diff CLAUDE.md drafts/review-setup/CLAUDE.md.new
mv drafts/review-setup/CLAUDE.md.new CLAUDE.md
```

Both profiles symlink `CLAUDE.md` to this file, so this updates both.

## 6. Check

```fish
# Hook passes non-push commands through (exit 0, no output)
echo '{"tool_input":{"command":"git status"},"cwd":"'(pwd)'"}' | ~/Work/agent-stack/claude/hooks/pre-push-checks.sh; echo $status
```

Then restart Claude Code (both profiles) and check:

- `/agents` lists `adversarial-reviewer` and `quality-reviewer`;
- `/hooks` shows `PreToolUse` → `Bash` → `pre-push-checks.sh`.

## 7. Commit agent-stack

```fish
cd ~/Work/agent-stack
git add claude/agents claude/hooks claude/CLAUDE.md claude/settings.base.json link.sh
git commit -m "feat: add pre-push review gate"
```

Then the drafts directory can go: `rm -r claude/drafts/review-setup`.

## Notes

- The hook needs `jq`. It runs on every Bash call but exits immediately
  unless the command is `git push` or `git -C <dir> push`.
- It only runs on pushes from Claude, not on your own pushes; humans get
  the same checks through pre-commit once a repo configures them
  (cloud-registry #73).
- Without a repo config (`.semgrep.yml` or `.semgrep/`), semgrep uses
  `$SEMGREP_CONFIGS` (default `p/python p/secrets`), downloaded from
  semgrep.dev on each run (the first run can take a while; timeout 300 s).
- ast-grep runs only in repos with an `sgconfig.yml`.
- Missing tools are reported as warnings and do not block the push.
- Tested 2026-10-20 with stub tools: blocks (exit 2) on semgrep or
  ast-grep findings, honors a repo `.semgrep.yml`, passes through for
  non-push commands, passing scans and branches with no changes.
- The two reviewers were already used, as general-purpose agents with
  these prompts, on cloud-registry #83 before pushing: no high or medium
  findings, eight low findings (all fixed).
