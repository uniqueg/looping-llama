# Parked (not linked, not installed)

Kept for later phases. Nothing here is referenced by `link.sh` or by the active settings. To reactivate an item, move it back to its original path and restore the wiring listed below.

| Item | Original path | Wiring to restore |
|---|---|---|
| Work persona (Team seat, own gh login and git identity) | `direnv/work.envrc`, `git/work.gitconfig` | Add `work` to the profile loop in `link.sh`. Map its directories in `personas.map`. Add `~/.config/gh-work` to the gh `Read` deny rules and `sandbox.filesystem.denyRead`. Fill in the work e-mail. |
| Private persona (API key via gopass, Sonnet, 30-day retention) | `claude/settings.private.json`, `direnv/private.envrc`, `git/private.gitconfig` | Add `private` back to the profile loop in `link.sh`. Set `private private` in `personas.map`. Add the deny rules below. |
| `claude-api` (Team quota → API key fallback) | `bin/claude-api` | The helper-scripts section in `link.sh` (links `bin/*` into `~/.local/bin`). Needs gopass. |
| OpenCode + `oc` + cross-review (Gemini API) | `opencode/`, `bin/oc`, `bin/cross-review` | The OpenCode section in `link.sh` (links `opencode.json`, `agents/`, and `claude/skills` into `~/.config/opencode/`). |
| guard-outward hook (outward MCP actions) | `claude/hooks/guard-outward.py` | The `hooks.PreToolUse` block below. Only useful once an MCP server is configured. |
| technical-writer skill, verify-citations, doc-export | `claude/skills/technical-writer/`, `bin/` | Move the skill back. Restore the helper-scripts section and the "Documents and citations" section of `claude/CLAUDE.md`. Needs pandoc/typst. |
| Google Workspace MCP, LiteLLM, Nebius, Antigravity | (never configured) | See `../../agent-stack-response-v7.md` §2 step 6 and §3. |

Settings fragments removed from `claude/settings.base.json`:

```json
"deny": ["Bash(gopass *)", "Bash(pass *)",
         "Read(~/.local/share/gopass/**)", "Read(~/.password-store/**)",
         "Read(~/.config/gh-private/**)", "Read(~/.config/rclone/**)"],
"sandbox.filesystem.denyRead": ["~/.local/share/gopass", "~/.password-store",
         "~/.config/gh-private", "~/.config/rclone"],
"hooks": {"PreToolUse": [{"matcher": "mcp__.*", "hooks": [{"type": "command",
         "command": "@AGENT_STACK@/claude/hooks/guard-outward.py"}]}]}
```

To reuse the `hooks` fragment, also restore the `@AGENT_STACK@` substitution in `link.sh`'s render step: `json.loads(f.read().replace("@AGENT_STACK@", stack))`.
