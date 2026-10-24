# agent-stack

My Claude Code setup, kept in one repository and installed into `$HOME` by
`link.sh`. It provides:

- **Profiles and personas:** separate Claude Code profiles (accounts, settings,
  memory) and matching git and GitHub identities, chosen by directory or by
  wrapper command.
- **Autonomy levels:** per session, how much Claude may do on its own
  (`auto`, `reviewed`, `supervised`, `external`).
- **Global rules** for Claude (`claude/CLAUDE.md`), shared skills, review
  subagents and hooks.
- **Reporting:** Claude works quietly and pushes a notification (ntfy) when it
  needs me.

Parked parts (work persona files, API fallback, OpenCode, more hooks and
skills) are in [`later/`](later/README.md). The usage log and the per-repo
branch-protection survey are in [`NOTES.md`](NOTES.md).

## Layout

```
README.md                     this file
NOTES.md                      usage log; branch protection per mapped repo
personas.map                  directory under ~/Work -> persona (academic | personal | work | none)
link.sh                       installs into $HOME (idempotent; backs up what it replaces)
direnv/
  <persona>.envrc             PERSONA, CLAUDE_CONFIG_DIR, GH_CONFIG_DIR for a persona's directories
  none.envrc                  shadows `claude` with a stub (no agent in that tree)
  no-agent/claude             the stub
git/<persona>.gitconfig       git identity and SSH key, applied via includeIf
fish/
  claude.fish                 `claude` function: picks the autonomy level, then runs the binary
  claude-approve.fish         records my review of a PR for the level gate
sandbox/apparmor-bwrap        AppArmor profile so bubblewrap works on Ubuntu 24.04+
claude/
  CLAUDE.md                   global rules -> ~/.claude-<profile>/CLAUDE.md
  settings.base.json          rules for every profile and level -> ~/.claude-<profile>/settings.json
  settings.<profile>.json     profile additions (academic: deny ~/Work/private)
  levels/
    README.md                 autonomy levels in detail
    <level>/settings.json     the level's permission mode and rules (auto, reviewed, supervised, external)
    <level>/rules.md          the level's rules, appended to Claude's system prompt
  hooks/
    pre-push-checks.sh        PreToolUse: semgrep / ast-grep on the branch's files before `git push`
    level-gate.sh             PreToolUse: human-review gate before `gh pr merge`
  bin/claude-notify           ntfy push; also the Notification hook
  agents/                     review subagents -> ~/.claude-<profile>/agents
  skills/                     skills -> ~/.claude-<profile>/skills
  workflows/                  saved workflow scripts (pre-release-review.js)
  drafts/                     drafts of changes to this setup only
  work/                       project and session documents (git-ignored)
later/                        parked items, not linked or installed (see later/README.md)
```

What `link.sh` installs, for each profile in its loop (`academic`, `personal`):

| In `$HOME` | From |
|---|---|
| `~/.claude-<profile>/settings.json` | rendered: `settings.base.json` merged with `settings.<profile>.json`; keys I set myself (`theme`, `model`, …) are kept |
| `~/.claude-<profile>/CLAUDE.md`, `agents`, `skills`, `workflows` | symlinks into `claude/` (saved workflows are then available by name, e.g. `pre-release-review`) |
| `~/.config/gh-<profile>/` | created, mode 700 (that persona's gh login) |
| `~/.config/fish/functions/claude.fish`, `claude-approve.fish` | symlinks into `fish/` |
| `~/.local/bin/claude-notify` | symlink to `claude/bin/claude-notify` |
| `~/Work/<dir>/.envrc` | `source_env …/direnv/<persona>.envrc`, per line of `personas.map` (only if missing) |
| `~/.gitconfig` | one `includeIf.gitdir:~/Work/<dir>/` per mapped directory with a git identity |

Not in the repo, set up by hand: the profile wrappers in
`~/.config/fish/config.fish`, the ntfy config
(`~/.config/claude-notify/config`), and the approvals folder
(`~/.local/state/claude-levels/approved/`, written by `claude-approve`).

## Profiles and personas

A **profile** is a Claude Code config directory (`CLAUDE_CONFIG_DIR`) with its
own login, settings, memory and sessions. A **persona** ties a profile to a
git identity and a gh login, per directory tree.

| Persona / profile | Claude config | Account | gh config | git identity | Directories (`personas.map`) |
|---|---|---|---|---|---|
| `academic` | `~/.claude-academic` | Team seat | `~/.config/gh-academic` | `git/academic.gitconfig` | `~/Work/biozentrum`, `~/Work/elixir`, `~/Work/ga4gh` |
| `personal` | `~/.claude-personal` | personal account | `~/.config/gh-personal` | `git/personal.gitconfig` | `~/Work/private` |
| `none` | – | – | – | – | none mapped at the moment; `claude` is blocked there |
| (default) | `~/.claude` | whichever is logged in | `~/.config/gh` | global `~/.gitconfig` | everything else, e.g. `~/Work/misc`, `~/Work/sandbox` |

There are two ways to pick a profile:

- **By directory (direnv).** In a mapped directory, its `.envrc` sources the
  persona's `direnv/<persona>.envrc`, which sets `PERSONA`,
  `CLAUDE_CONFIG_DIR` and `GH_CONFIG_DIR`. Plain `claude` then uses that
  profile, and git uses that identity (via `includeIf`).
- **By wrapper (fish).** `claude-a` and `claude-p` in
  `~/.config/fish/config.fish` set the profile explicitly, anywhere:

  ```fish
  function claude-a
      CLAUDE_CONFIG_DIR=$HOME/.claude-academic claude $argv
  end
  function claude-p
      CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude $argv
  end
  ```

  They call the `claude` fish function (not the binary), so levels work with
  them. They set only `CLAUDE_CONFIG_DIR`: `gh` and git still follow the
  directory.

### Adding a work profile (`claude-w`)

1. fish: add to `~/.config/fish/config.fish`, next to the others:
   ```fish
   function claude-w
       CLAUDE_CONFIG_DIR=$HOME/.claude-work claude $argv
   end
   ```
2. Create `claude/settings.work.json` (profile additions; `{}` is fine, or
   copy academic's deny of `~/Work/private`).
3. `link.sh`: add `work` to the profile loop (`for p in academic personal work`).
4. Move `later/direnv/work.envrc` to `direnv/` and `later/git/work.gitconfig`
   to `git/` (fill in the work e-mail). Map the work directories in
   `personas.map` (`<dir> work`).
5. `./link.sh`, `direnv allow` in each work directory, `gh auth login` there
   (the token goes to `~/.config/gh-work`), then `claude-w` and `/login`.
   The base's read denies (`~/.config/gh-*`) already cover the new gh login.

See also the work row in [`later/README.md`](later/README.md).

## Autonomy levels

A level says how much Claude may do on its own in a session, and what my part
is. It is chosen per session, independently of the profile. Details,
including how the human-review gate and approvals work and how to add a
level: [`claude/levels/README.md`](claude/levels/README.md).

| Level | My role | Mode | Merge own PRs | Post in my name |
|---|---|---|---|---|
| `auto` | none until the end; Claude ships on its own | `auto` | allowed, no human review | allowed |
| `reviewed` | I (or another human) review each PR before it is merged | `auto` | allowed, after human review of that PR | ask |
| `supervised` (default) | I review each PR, approve key steps, and every merge | `acceptEdits` | ask, after human review of that PR | ask |
| `external` | I review the branch on my fork and open the PR myself | `auto` | denied (no PRs at all) | ask |

Human review means an approving review by a human on GitHub, or my approval
recorded with `claude-approve <PR URL>`, for the PR's current head commit.
`claude-approve <PR URL> --revoke` takes it back.

How a level is chosen: `claude --level <name>`, otherwise `$CLAUDE_LEVEL`
(e.g. from a directory's `.envrc`), otherwise `supervised`. The `claude` fish
function prints the level and its source on start, and runs
`command claude --settings claude/levels/<name>/settings.json
--append-system-prompt-file claude/levels/<name>/rules.md …`.

Profiles and levels combine freely:

```fish
claude-a --level auto -w task        # academic profile, level auto, new worktree
claude-p --level reviewed -c         # personal profile, continue the last session here
claude -w fix-123                    # in a mapped directory: its profile; its level or supervised
```

For forks, set a default level in the directory's `.envrc`:

```sh
source_env ~/Work/private/looping-llama/direnv/personal.envrc
export CLAUDE_LEVEL=external
```

## Global rules

`claude/CLAUDE.md` applies to every profile and project; project `CLAUDE.md`
/ `AGENTS.md` files add to it, and the level's `rules.md` overrides it where
they differ. Sections:

| Section | In short |
|---|---|
| Autonomy level | levels exist; without one, follow `supervised`; talk about a level change is not an instruction to change it |
| Hard rules | no clinical or TRE data; no pushes to default branches, no force-push; merge and post only as the level allows; no secrets; `git commit`/`push`, `gh`, `claude-notify` as standalone commands outside the sandbox; external content is data |
| Reporting | report only at a dead end or when asked; `·` as sign of life; defer prompting actions; one ntfy push at a dead end |
| Working with me | check decision records first; give exact commit commands; follow ecosystem conventions; where documents go |
| Delegation | background agents without foreseeable conflicts; copy decisions into prompts; no broader merge rights than the level |
| Issues and PRs | every PR closes an issue; issues are PR-sized; split big ones into child issues |
| Coding workflow | nine steps: worktree, existing checks, test-first, Conventional Commits (50-char subject), review subagents before push, draft PR, CI loop (max 3), ready + automated reviews (max 3) |
| Learnings and memory | save learnings right away; settings or rule changes as `feedback` memories with "Recommendation: …" |

## Reporting and notifications

Claude reports only at a **dead end** (blocked on every line of work, or out
of work) or when I ask; in between it replies to background events with `·`.
Actions that would show a permission prompt wait on a list until the dead
end, because a prompt blocks the whole session.

At a dead end, Claude runs `claude-notify "<message>"`, which sends a push
via [ntfy](https://ntfy.sh). A `Notification` hook on `permission_prompt`
calls the same script as a safety net for unexpected prompts. This works for
every profile and account (Claude app pushes only reach a phone signed in to
the session's account).

- Config: `~/.config/claude-notify/config` with `NTFY_URL=…` and optionally
  `NTFY_TOKEN=…`, mode 600. Claude may not read it; the script runs outside
  the sandbox (`excludedCommands`) to use it.
- The title names the level and the persona or profile. Messages carry no
  content (no repository names for client work, no code), since they pass
  through the ntfy server; the script cuts them at 200 characters.

## Reviews and gates

| Check | Where | When |
|---|---|---|
| `adversarial-reviewer` subagent | `claude/agents/` | before every push of code changes (workflow step 6): correctness and security, tries to break the change |
| `quality-reviewer` subagent (Sonnet) | `claude/agents/` | same, in parallel: maintainability, tests, docs (like Sourcery or Copilot) |
| `pre-push-checks.sh` hook | `claude/hooks/` | on `git push` / `git -C <dir> push`: semgrep (`$SEMGREP_CONFIGS`, default `p/python p/secrets`, plus the repo's `.semgrep.yml` / `.semgrep/`) and ast-grep (if the repo has `sgconfig.yml`) on the files changed since the default branch; blocks on findings, warns if a tool is missing |
| Automated PR reviewers (Sourcery, Copilot) | GitHub | after `gh pr ready` (workflow step 9) |
| `level-gate.sh` hook | `claude/hooks/` | on `gh pr merge`: `auto` passes; `reviewed`/`supervised` need human review of the current head commit; `external` and unknown levels are blocked; fails closed |
| Rulesets | GitHub, per repo | always: the real guard for default branches (status per repo: `NOTES.md`) |

Skills and workflows:

| Name | Kind | Purpose |
|---|---|---|
| `software-engineer` | skill | implement features or fixes; ends in a draft PR |
| `implement-issue` | skill | a GitHub issue end to end: size check (whole issue per PR), worktree, draft PR, CI and automated reviews, then merge or hand-over with CODEOWNERS (`codeowners.py`), as the level allows |
| `code-reviewer` | skill | read-only review of a branch, PR or diff (also external or student work); never posts |
| `architect` | skill | cloud, zero-trust and standards architecture (Kubernetes, Helm, GA4GH, FHIR, OMOP, ADRs) |
| `synced/` | skills | skills synced from claude.ai (docs, pdf, pptx, …), not maintained here (git-ignored) |
| `pre-release-review` | workflow | review a repo, or its changes since a ref, before a release (security, functionality, best practice, integration) with adversarial verification |

## Installation

### Fresh machine

| # | Step | Expected |
|---|---|---|
| 1 | **Tools.** Claude Code, fish, direnv, git, gh, jq, python3, curl, bubblewrap and socat (sandbox). For the pre-push hook: `mise use -g semgrep ast-grep` (`/usr/bin/sg` is not ast-grep). | `claude --version`, `semgrep --version`, `ast-grep --version` work. |
| 2 | **Sandbox (AppArmor).** `sudo cp sandbox/apparmor-bwrap /etc/apparmor.d/bwrap && sudo systemctl reload apparmor`, then `bwrap --ro-bind / / --dev /dev --proc /proc --unshare-net true; echo $?` | `0` and nothing else. Without the fix: `setting up uid map: Permission denied` or `loopback: Failed RTM_NEWADDR`. |
| 3 | **Repo.** Clone to `~/Work/private/looping-llama` **before** step 5: `link.sh` writes absolute paths, and settings and the `claude` function expect this path. | |
| 4 | **SSH key.** All personas use `~/.ssh/id_ed25519_github`: `ssh -i ~/.ssh/id_ed25519_github -o IdentitiesOnly=yes -T git@github.com` | `Hi <login>! You've successfully authenticated…` |
| 5 | **Link.** `./link.sh`, then again. `git config --global --get-regexp includeIf` | Run 1: `wrote …settings.json` per profile, the symlinks, `.envrc` files and `git: … identity` lines. Run 2: `up to date`, nothing new. One `includeIf` per mapped directory. |
| 6 | **fish and direnv.** In `~/.config/fish/config.fish` (interactive block): `direnv hook fish \| source` and the `claude-a`/`claude-p` wrappers (see above). Then `direnv allow` in each mapped directory. | In `~/Work/elixir`: `direnv: export +CLAUDE_CONFIG_DIR +GH_CONFIG_DIR +PERSONA`. `functions -q claude claude-approve` succeeds. |
| 7 | **GitHub, per persona.** `cd ~/Work/elixir && gh auth login` and `cd ~/Work/private && gh auth login` (GitHub.com, SSH, skip key upload). | `gh auth status` in each shows the right account; tokens live in `~/.config/gh-academic` and `~/.config/gh-personal`. |
| 8 | **ntfy.** Pick a long random topic (or a server with a token) and write `~/.config/claude-notify/config` with mode 600 (`NTFY_URL=…`, optionally `NTFY_TOKEN=…`). Subscribe to it in the ntfy app. | `claude-notify test` arrives on the phone. |
| 9 | **Claude, per profile.** `claude-a`, then `/login` with the Team account and `/status`; the same with `claude-p` and the personal account. | Claude starts at all (so the sandbox works: `failIfUnavailable`). It prints `claude: autonomy level supervised (default)`. `/status` shows the account; `! echo $CLAUDE_CONFIG_DIR` shows the profile directory. |
| 10 | **Persistence.** In each profile: `/config` → *Continue automatically at usage limit* → on. Then `/sandbox`. | The toggle shows on; `/sandbox` shows the sandbox enabled, with no dependency warning (a seccomp warning is fine). |
| 11 | **Rulesets (by hand).** For each repo agents will push to: *Settings → Rules → Rulesets → New branch ruleset*, target the **default** branch (sometimes `dev`), Enforcement *Active*, *Restrict deletions*, *Require a pull request before merging*, *Block force pushes*. Check with `gh ruleset check <default-branch> -R <owner>/<repo>`. Repos where that's impossible: see `NOTES.md`. | The three rules apply to the default branch. |

### One-time migration to levels

On the existing machine, the levels were installed from drafts with
`claude/drafts/levels/install.sh` (run once, in a normal terminal, with no
Claude session working). It backed up everything it replaced to
`~/.local/state/looping-llama/install-<timestamp>/`, installed `claude/levels/`,
the new hook, `claude-notify`, the fish functions, `CLAUDE.md`,
`settings.base.json`, `link.sh`, the updated `implement-issue` skill and this
README, removed applied drafts and the `claude-merge`
function and foca's merge exception in `CLAUDE.local.md`, dropped `env` from
the profile wrappers, wrote the ntfy config, ran `link.sh` and checked the
result. On a fresh machine it is not needed: the steps above cover it.

### Acceptance tests

Run in a scratch repo with a ruleset and a PR of my own, after installing or
after changing permissions.

| Test | Pass when |
|---|---|
| `claude-p --level nope` | `unknown level 'nope'. Levels: auto external reviewed supervised`, exit 1 |
| `claude-p`, then `/permissions` | banner `autonomy level supervised (default)`; mode `acceptEdits`; `gh pr merge` under ask |
| `claude-p --level reviewed`, ask Claude to merge the PR | blocked by `level-gate.sh` (`no human review …`) |
| `claude-approve <PR URL>`, ask again | merges without a prompt |
| push to the PR after approving, merge again | blocked again (new head commit) |
| `claude-p --level external`, ask for a draft PR | denied |
| `claude-p --level auto`, `/permissions` | mode `auto`; `gh issue create` allowed |
| at any level, ask Claude to run `git push origin HEAD:<default-branch>`, `git push --force`, `gh auth token`, `cat ~/.ssh/id_*` | the push to the default branch is rejected by GitHub (`GH013: Repository rule violations`); force-push and `gh auth` are denied without a prompt; the `cat` fails in the sandbox, and an unsandboxed retry prompts |
| `cd ~/Work/elixir/<repo>`: `git config user.email`, and `! echo $CLAUDE_CONFIG_DIR` in Claude | the academic e-mail; `/home/uniqueg/.claude-academic` |
| `claude-a -w <task>` in a mapped repo, then `/implement-issue <n>` | existing checks green, review subagents run, branch pushed and **draft** PR opened without prompts; at `supervised`, nothing merged |
| at `supervised`, trigger a prompt and walk away | ntfy push after a few seconds |
| `claude-p mcp list` | works as before (subcommands bypass the level) |

## Changing things

Edit files in the repo, never the installed copies, then run `./link.sh`
(settings are rendered, everything else is symlinked, so edits to
`CLAUDE.md`, skills, agents, hooks, levels and fish functions are live at
once; settings need `link.sh`). Claude asks before editing agent-stack config
(`CLAUDE.md`, agents, hooks, levels, skills, workflows, settings, `bin/`,
`fish/`, `direnv/`, `link.sh`, `personas.map`, any `.envrc`); the sandbox
can't write the levels, `bin/`, `fish/`, `direnv/`, `link.sh` or
`personas.map` at all.

Settings, from lowest to highest precedence:

1. `claude/settings.base.json`: what is the same at every level (always-denied
   commands, safe commands to allow, sandbox, hooks).
2. `claude/settings.<profile>.json`: merged into the base by `link.sh`
   (objects key by key, lists combined).
3. Project settings (`.claude/settings.json`, `.claude/settings.local.json`),
   e.g. `{"permissions": {"ask": ["Bash(git push *)"]}}` for repos without a
   ruleset (see `NOTES.md`).
4. The level, via `--settings claude/levels/<level>/settings.json`: its
   `defaultMode` wins; its rules are added.

Permission lists from all sources are combined, and **deny beats ask beats
allow** regardless of source. So a level can add `allow` or `ask` rules for
what the base leaves open, and deny what the base allows (`external` denies
`gh pr create`), but nothing can allow what the base denies. Hooks and
sandbox paths are combined too.

Common changes:

| Change | Where |
|---|---|
| A rule for every level | `claude/settings.base.json`, then `./link.sh` |
| A rule for one level | `claude/levels/<level>/settings.json` (next session) |
| A new level | new folder in `claude/levels/` (see its README); merge policy in `claude/hooks/level-gate.sh` |
| A new mapped directory | `personas.map`, then `./link.sh` and `direnv allow` |
| A new profile | see [Adding a work profile](#adding-a-work-profile-claude-w) |
| Unpark something | [`later/README.md`](later/README.md) lists the wiring to restore |

## Known limits

- **Permission rules match command patterns, not intent.** Combined short
  flags (`git push -uf`), `git -C dir push --force`, `gh -R owner/repo pr
  merge` and `git -C dir push upstream` slip past patterns and the gate's
  command match. Rulesets on default branches are the real guard; on feature
  branches a force-push only rewrites the agent's own branch.
- **`git push` is allowed everywhere.** In a repo without a ruleset, a push to
  the default branch goes through unless the repo has the local ask override
  (`NOTES.md`).
- **Approvals are a file only I should write.** Claude's file tools and the
  sandbox can't write `~/.local/state/claude-levels/`, but an unsandboxed
  shell command could. Such commands prompt at `supervised`; at `auto` and
  `reviewed` the auto-mode classifier decides.
- **`external` assumes the fork is `origin` and the original is `upstream`.**
  A push to the original repo's URL directly is not caught.
- **`command claude` or the binary's full path bypasses the level.** Only the
  base applies (mode `acceptEdits`); the gate treats a missing `CLAUDE_LEVEL`
  as `supervised`.
- **Outside mapped directories** (`~/Work/misc`, `~/Work/sandbox`), plain
  `claude` uses the default `~/.claude` profile, which `link.sh` doesn't
  manage: no base settings, hooks or global rules, only the level file. Use
  `claude-a`/`claude-p` there.
- **The wrappers set only the Claude profile.** `gh`, git and `claude-approve`
  follow the directory's persona, so a wrapper used outside its persona's
  directories pushes and opens PRs with the default gh login and global git
  identity.
- **The level is fixed for a session.** Restart to change it
  (`claude-p --level <name> -c` continues the last session).
- **`gh api -F x=@file` reads files outside the sandbox** (`gh` runs
  unsandboxed). The base denies `@` paths under `/home`, `/etc`, `/root`,
  `~`, `$…` and `.`; a relative path like `@notes.md` is not caught. Body
  files belong in the session scratchpad or `$TMPDIR`.
- **The `claude` stub (`none`) is an accident guard, not a lock.** The full
  path, `command claude` or a shell without direnv bypass it.
- **Subcommands are passed through by name.** The `claude` function knows a
  fixed list (`mcp`, `update`, `doctor`, …); a subcommand missing from it
  gets `--settings` put before it (untested).
