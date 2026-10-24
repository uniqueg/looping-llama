# Installing

Run this in a normal terminal (not inside Claude), when no Claude session is
working (running sessions reload the base settings immediately):

```sh
bash ~/Work/private/looping-llama/claude/drafts/levels/install.sh
```

It asks once to confirm, and for your ntfy URL (and optional token) if
`~/.config/claude-notify/config` doesn't exist yet. Everything it replaces
goes to `~/.local/state/looping-llama/install-<timestamp>/` first. It:

1. Installs into agent-stack: `claude/levels/` (with this README),
   `claude/hooks/level-gate.sh`, `claude/bin/claude-notify`, `fish/claude.fish`
   and `fish/claude-approve.fish`, the new global `claude/CLAUDE.md`,
   `claude/settings.base.json` and `link.sh`. Removes the drafts
   `claude-merge.fish` and `autonomy-levels.md`.
2. fish: removes `claude-merge`, and drops `env` from `claude-a`/`claude-p` in
   `config.fish` (so they call the `claude` function).
3. Writes the ntfy config (mode 600), if missing.
4. Deletes foca's `CLAUDE.local.md` if it only holds the merge exception (the
   level decides now).
5. Runs `link.sh`. It now merges base and profile settings like Claude Code
   does (objects key by key, lists combined) and keeps keys you set yourself
   (`theme`, `env`, `model`, …). It also links the fish functions and
   `~/.local/bin/claude-notify`.
6. Checks both profiles' settings, the fish functions and a test push, and
   prints the next steps, including the commit commands for agent-stack.

Tested in a fake home directory with copies of your settings: both profiles
keep the base's deny rules (academic lost them before) and your own keys.

## Test after installing (about 10 minutes)

In a scratch repo with a PR of your own:

| Test | Expected |
|---|---|
| `claude-p --level nope` | "unknown level 'nope'. Levels: auto external reviewed supervised", exit 1 |
| `claude-p`, then `/permissions` | Banner "autonomy level supervised (default)"; mode `acceptEdits`; `gh pr merge` under ask |
| `claude-p --level reviewed`, ask Claude to merge the PR | Blocked by `level-gate.sh` ("no human review …") |
| `claude-approve <PR URL>`, ask again | Merges without a prompt |
| Push a commit to the PR after approving, merge again | Blocked again (new head) |
| `claude-p --level external`, ask Claude to open a draft PR | Denied |
| `claude-p --level auto`, `/permissions` | Mode `auto`; `gh issue create` allowed |
| Ask Claude which level it is at | Names the level and its rules |
| `claude-p` (supervised), ask for an action that prompts, walk away | ntfy push after about 6 s without typing |
| `claude-p mcp list` | Works as before (subcommands bypass the level) |
