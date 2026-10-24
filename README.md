# agent-stack

Walk, minimal: **Claude Code + Team seat only**, for the Academic persona. The Work persona is parked in `later/` until a work directory exists. Private gets no agent (`claude` is blocked under `~/Work/private`). Everything else is parked in `later/` (see `later/README.md`): not linked, not installed. Background: `../agent-stack-response-v7.md` (superseded where it conflicts with this file).

```
personas.map                  directory -> persona (academic | none)
direnv/<persona>.envrc        PERSONA, CLAUDE_CONFIG_DIR, GH_CONFIG_DIR; none.envrc shadows `claude` with a stub
git/<persona>.gitconfig       identity + SSH key, applied via includeIf
claude/settings.base.json     acceptEdits, sandbox, SEC-3 allow/ask/deny tiers -> ~/.claude-academic/settings.json
claude/CLAUDE.md              global rules: existing CI checks before "done", draft PRs only, never merge
claude/skills/                software-engineer, code-reviewer, architect, implement-issue (+ codeowners.py)
sandbox/apparmor-bwrap        AppArmor profile so bubblewrap works on Ubuntu 24.04
link.sh                       installs into $HOME (idempotent, backs up what it replaces)
NOTES.md                      usage log for the first two weeks
```

## Setup checklist (about 2 h)

| # | Step | Expected output |
|---|---|---|
| 1 | **Sandbox (AppArmor).** `sudo cp sandbox/apparmor-bwrap /etc/apparmor.d/bwrap && sudo systemctl reload apparmor`, then `bwrap --ro-bind / / --dev /dev --proc /proc --unshare-net true; echo $?` | `0` and nothing else. Before the fix you get `setting up uid map: Permission denied` or `loopback: Failed RTM_NEWADDR`. |
| 2 | **Repo.** `mv ~/Work/sandbox/loopy/agent-stack ~/Work/private/looping-llama && cd ~/Work/private/looping-llama && git init && git add -A && git commit -m "agent-stack: walk minimal"`. Move it **before** step 4: link.sh writes absolute paths. | `[main (root-commit) …] agent-stack: walk minimal` |
| 3 | **SSH key.** The academic persona uses `~/.ssh/id_ed25519_github`; check it with `ssh -i ~/.ssh/id_ed25519_github -o IdentitiesOnly=yes -T git@github.com`. | `Hi <your-login>! You've successfully authenticated…` |
| 4 | **Link.** `./link.sh`, then run it again. `git config --global --get-regexp includeIf` | Run 1: `wrote …settings.json`, four `.envrc` files, three `git: … identity` lines. Run 2: `up to date`, nothing new. Three `includeIf` lines (biozentrum, elixir, ga4gh → academic). |
| 5 | **direnv.** `echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc && exec zsh`, then `direnv allow` in `~/Work/{private,biozentrum,elixir,ga4gh}` | Per academic directory: `direnv: export +CLAUDE_CONFIG_DIR +GH_CONFIG_DIR +PERSONA`. In `private`: `direnv: export +PERSONA ~PATH`. |
| 6 | **GitHub.** `cd ~/Work/elixir && gh auth login` (GitHub.com, SSH, skip key upload). Check with `gh auth status`. | `Logged in to github.com account <login> (keyring)`. The token lives in the persona's own `GH_CONFIG_DIR` (`~/.config/gh-academic`). |
| 7 | **Claude.** `cd ~/Work/elixir && claude`, then `/login` with the Team account and `/status`. | Claude starts at all, which means the sandbox works (`failIfUnavailable` would make it exit otherwise). `/status` shows the Team organization. `! echo $CLAUDE_CONFIG_DIR` prints `/home/uniqueg/.claude-academic` (`/status` doesn't list the config dir), and `ls ~/.claude-academic/projects` now has `-home-uniqueg-Work-elixir`. |
| 8 | **Private stays agent-free.** `cd ~/Work/private && claude` | `agent-stack: no agent for PERSONA=none …`, exit 1 |
| 9 | **Persistence.** In the academic profile: `/config` → *Continue automatically at usage limit* → on. Then `/sandbox`. | The toggle shows on. `/sandbox` shows the sandbox enabled, with no dependency warning (a seccomp warning is optional and fine). |
| 10 | **Rulesets (by hand).** For each repo you'll use first (status per repo: `NOTES.md`): *Settings → Rules → Rulesets → New branch ruleset*, target the **default** branch (sometimes `dev`, not `main`), Enforcement *Active*, *Restrict deletions*, *Require a pull request before merging*, *Block force pushes*. Check with `gh ruleset check <default-branch> -R <owner>/<repo>`. | The three rules are listed as applying to the default branch. |

## Definition of done (Walk, minimal)

| | Test | Pass when |
|---|---|---|
| **(a)** | `cd ~/Work/elixir/<repo> && claude -w <task>`, then `/implement-issue <n>` (or `/software-engineer <task>`) | The agent runs the project's existing CI checks and they're green. It pushes the feature branch and opens the **draft** PR without prompting. It ends by printing the CODEOWNERS for the changed paths and `gh pr ready <n> -R …`. Nothing is marked ready or merged. |
| **(b)** | In `~/Work/elixir/<repo>` and `~/Work/ga4gh/<repo>`: `/status` and `! echo $CLAUDE_CONFIG_DIR` in Claude, and `git config user.email` in the shell. Then the same in `~/Work/misc/<repo>` | Academic dirs: `/status` shows the Team seat, `CLAUDE_CONFIG_DIR` is `/home/uniqueg/.claude-academic`, and the e-mail is `alexander.kanitz@unibas.ch`. `misc`: `CLAUDE_CONFIG_DIR` is empty (default `~/.claude` profile), and the e-mail is your global one. |
| **(c)** | In a repo **with** a ruleset, ask Claude to run each of these: `git push origin HEAD:<default-branch>`, `git push --force`, `gh pr merge <n>`, `cat ~/.ssh/id_*`, `gh auth token` | The push to the default branch runs and **GitHub rejects it** (`GH013: Repository rule violations`). Force-push, merge and `gh auth token` are **denied** without a prompt. The `cat` fails in the sandbox, and any unsandboxed retry prompts. |

## Approval tiers (SEC-3, `claude/settings.base.json`)

| Tier | Commands |
|---|---|
| **Auto** | `git push` (any branch: the default branch is guarded server-side by rulesets), `gh pr create --draft …` (only with `--draft` first), `gh repo fork`, `gh issue view`, `gh pr view/diff/checks` |
| **Ask** | `gh pr ready`, `gh pr edit` (all edits, including `--add-reviewer`), `gh pr comment/review`, `gh issue comment/create`, `gh api` |
| **Deny** | `gh pr merge`, force-push (`--force*`, `-f`, `+refspec`, `--mirror`), `gh repo delete`, `gh release`, `gh auth` |
| Everything else | Shell commands run automatically **inside** the sandbox. `git push` and all `gh` run **outside** it (`excludedCommands`) so they can use the SSH key and the gh token; any of them not listed above prompts. That includes `gh pr create` without `--draft` first, `gh pr list` and `gh run view`. |

Repos without a ruleset get `git push` back on ask in the repo's own `.claude/settings.local.json` (see `NOTES.md`). It applies to all `claude -w` worktrees of that repo too.

## Known limits (accepted for Walk)

- **Force-push deny rules match patterns, not intent.** Combined short flags such as `-uf`, and `git -C dir push --force`, slip past them. The ruleset (*Block force pushes*) is the real guard on the default branch; on feature branches a force-push only rewrites the agent's own branch.
- **`git push` is auto-allowed everywhere.** In a repo with no ruleset, a push to the default branch goes through unless that repo has the local ask override.
- **The `claude` stub is an accident guard, not a lock.** Calling it by full path or from outside direnv bypasses it.
- **`~/Work/private` has no git identity of its own.** It uses your global `user.email`, which is `alumni.ethz.ch`.
- **`~/Work/misc` and `~/Work/sandbox` keep the default `~/.claude` profile,** with no agent-stack settings.
