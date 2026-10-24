# Autonomy levels

An autonomy level says how much Claude may do on its own in a session, and
what your part is. You pick one per session, independent of the profile
(`claude-a`, `claude-p`, later `claude-w`) and its subscription:

```fish
claude-p --level auto -w big-refactor   # personal profile, level auto
claude-a -w fix-123                     # academic profile, the directory's level or `supervised`
claude --level external                 # in a direnv directory: its profile
```

Profiles and levels are independent: n profile wrappers plus m level folders,
not n × m wrappers.

## The levels

The names describe your role. A new level is a new folder (see
[Adding a level](#adding-a-level)).

| Level | Your role | Typical use |
|---|---|---|
| `auto` | None until the end. Claude ships on its own. | High-intensity, low-stakes work, e.g. repo-wide pre-production refactors with many moving parts, possibly over several days. |
| `reviewed` | You (or another human) review each PR before it is merged. | Regular, medium-stakes work, e.g. several issues towards a release with some users but no SLA (most open-source and science work), as long as nothing in the plan is security-critical. |
| `supervised` | You review each PR, approve key steps along the way, and every merge. | High-stakes work: client-facing, or security-critical issues, mostly one at a time. **The default** when no level is set. |
| `external` | You review the branch and open the PR yourself. | Contributions to someone else's codebase, from your fork. |

### What each level allows

| | `auto` | `reviewed` | `supervised` | `external` |
|---|---|---|---|---|
| Permission mode | `auto` | `auto` | `acceptEdits` | `auto` |
| Commit, push feature branches | allow | allow | allow | allow, to the fork only; pushes to `upstream` denied |
| Open draft PR | allow | allow | allow | **deny** |
| `gh pr ready`, `gh pr edit`, `gh api` (with deny patterns) | allow | allow | ask | deny |
| Answer automated reviewers on own PRs | allow | allow | ask | – |
| Posting in your name: issues, PR comments, reviews | allow | ask | ask | ask (e.g., discussing an upstream issue) |
| Human review before merging | skipped | **required**, per PR | **required**, per PR | – |
| Merge own PRs (non-default branches; rulesets guard default branches) | allow | allow, after human review | ask, after human review | deny |
| Read releases (`gh release view/list`) | allow | allow | ask | deny |
| Edit release notes (`gh release edit`) | allow | ask | ask | deny |
| Edit agent-stack config (CLAUDE.md, agents, hooks, levels, skills, workflows, settings) | ask | ask | ask | ask |
| Always allowed | reading: `gh pr view/diff/checks`, `gh issue view`, `gh run list/view/watch`; `git fetch`; `claude-notify` | same | same | same |
| Always denied | `gh release create/delete/upload`, `gh auth`, `gh secret`, `gh repo edit`/`delete`, risky `gh api` calls (merges, deletions, protection, rulesets, collaborators, secrets, hooks, environments; `--input`; `-F x=@file` outside temp folders), force-push, reading secrets | same | same | same |

"Level `auto`" and "mode `auto`" are different things: the level is this
scheme, the mode is Claude Code's permission mode (a classifier decides on
commands that no rule covers). The levels `reviewed` and `external` use the
mode `auto` too.

### Human review

At the levels `reviewed` and `supervised`, a PR may only be merged once a
human has reviewed **that PR at its current head commit**. Either of these
counts:

- an approving review on GitHub by a human (not a bot), or
- your approval, recorded with `claude-approve <PR URL>`. You need this one
  for your own PRs: Claude pushes and opens PRs as you, and GitHub doesn't
  let PR authors approve their own PRs. Also use it to skip the review for
  one PR ("skip" = you approve without reviewing).

A signal never carries over to another PR, and new pushes need a new
signal. `claude-approve <PR URL> --revoke` takes your approval back.

The hook `level-gate.sh` enforces this: it blocks `gh pr merge` without a
signal and tells Claude to ask you. Claude can't record approvals itself:
the approvals folder (`~/.local/state/claude-levels/`) is denied to Claude's
file tools and to the sandbox.

## How it works

```
claude/
  settings.base.json        rules for every level -> ~/.claude-<profile>/settings.json (via link.sh)
  settings.<profile>.json   profile additions (e.g., academic: deny ~/Work/private)
  levels/<name>/
    settings.json           the level's mode and permission rules
    rules.md                the level's rules for Claude
  hooks/level-gate.sh       human-review gate before `gh pr merge`
  bin/claude-notify         ntfy push (also the Notification hook)
fish: claude, claude-approve
```

1. **`claude` (fish function)** shadows the binary. It takes `--level
   <name>` off the arguments, otherwise uses `$CLAUDE_LEVEL` (e.g., set by
   direnv), otherwise `supervised`, and starts
   `command claude --settings levels/<name>/settings.json
   --append-system-prompt-file levels/<name>/rules.md …` with
   `CLAUDE_LEVEL=<name>` set. It prints the level and where it came from
   (`flag`, `env` or `default`) on start. Unknown levels stop with a list of
   the available ones.
2. **Permissions:** Claude Code combines the permission lists of all
   settings sources and checks `deny`, then `ask`, then `allow`, where the
   first match wins regardless of source. So `settings.base.json` holds only
   what is the same at every level: the always-denied list, safe commands to
   allow, and `ask` for agent-stack config. Everything that differs between
   levels lives in the level files. A level can still deny something the
   base allows (`external` denies `gh pr create`). The mode
   (`defaultMode`) from `--settings` overrides the base's. Hooks and sandbox
   paths are combined too.
3. **Rules:** `rules.md` is appended to the system prompt, so it survives
   compaction. It overrides the global CLAUDE.md where they differ.
4. **Gate:** `level-gate.sh` reads `$CLAUDE_LEVEL` (inherited from the
   `claude` process). It fails closed: unknown levels and PRs it can't
   resolve block the merge.

### Default levels per directory

Set `CLAUDE_LEVEL` in a directory's `.envrc` (direnv), e.g. for forks:

```sh
# ~/Work/forks/.envrc
source_env ~/Work/agent-stack/direnv/personal.envrc
export CLAUDE_LEVEL=external
```

`--level` still overrides it for a session.

## Reporting and notifications

The same at every level (rules in the global CLAUDE.md, "Reporting"):

- Claude reports only at a **dead end**, i.e. when it is blocked on every
  line of work or out of work, or when you ask ("catch me up"). Then it
  sends a short summary, and goes point by point on request.
- In between, replies to background events are a single `·` (sign of
  life).
- Actions that would show a permission prompt wait on a list while other
  work is possible: a prompt blocks the whole session. They run at the dead
  end.
- At a dead end, Claude sends a push via ntfy: `claude-notify "<message>"`
  (`bin/claude-notify`). A `Notification` hook on `permission_prompt` sends
  one too, as a safety net for prompts Claude didn't expect (e.g. from the
  auto-mode classifier).
- This works for every profile and account. Claude app pushes (Remote
  Control) only reach a phone signed in to the session's account, and the
  app can't switch between accounts with different email addresses.

The ntfy URL and token are in `~/.config/claude-notify/config` (denied to
Claude). The script runs outside the sandbox (`excludedCommands`) to read
it. Messages carry no content (no repository names for client work, no
code), because they pass through the ntfy server. The title names the
level and the profile.

## Adding a level

1. Create `claude/levels/<name>/settings.json` (mode plus `allow`/`ask`/
   `deny` rules) and `rules.md` (starting with "# Autonomy level: <name>").
2. If it has a merge policy of its own, add it to the `case` in
   `hooks/level-gate.sh` (unknown levels block merges).
3. Add a column to the tables above.

No change to the fish functions or the profiles is needed.

## Limits

- **Permission rules match command patterns, not intent** (as before). For
  example, `gh -R owner/repo pr merge` and `git -C dir push upstream` slip
  past patterns and the gate's command match; rulesets on default branches
  remain the real guard there.
- **Approvals are a file only you should write.** Claude's file tools and
  the sandbox can't write it, but an unsandboxed shell command could. Such
  commands prompt at `supervised`; at `auto`/`reviewed` the auto-mode
  classifier decides.
- **`external` assumes the fork is `origin` and the original repo is
  `upstream`.** A push to the original repo's URL directly is not caught.
- **Plain `command claude`** (or the binary's full path) bypasses the
  function: no level file, so only the base applies (mode `acceptEdits`;
  `gh` writes then prompt, or are decided by the classifier in mode
  `auto`). The gate treats a missing `CLAUDE_LEVEL` as `supervised`.
- **The level is fixed for a session.** Restart Claude to change it
  (`claude-p --level <name> -c` continues the last session).
- **`gh api -F x=@file` reads files outside the sandbox** (`gh` runs
  unsandboxed). The base denies `@` paths under `/home`, `/etc`, `/root`,
  `~`, `$…` and `.`; body files belong in the session scratchpad or
  `$TMPDIR`. A relative path like `@notes.md` is not caught.
- Subcommands (`claude mcp …`, `claude update`, …) bypass the level: the
  wrapper passes them through unchanged (list in `claude.fish`; extend it
  when Claude Code adds subcommands).
