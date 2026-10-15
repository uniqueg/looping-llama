# Notes: usage log and repo protection

Goal: learn how fast the Team seat's limits burn before adding anything (API fallback, OpenCode, …).

## How to check

- **`/usage`** (aliases `/cost`, `/stats`) inside Claude Code shows your plan usage against the session and weekly limits, plus what is contributing to them. It reports the seat as a whole, so sessions in `~/Work/misc` or `~/Work/sandbox` (default `~/.claude` profile) count too.
- **`/status`** confirms which account and organization the current session uses.
- **When a limit hits:** with *Continue automatically at usage limit* on, the session waits and resumes after the reset, but only if Claude Code stays running. If it exits during the wait, send a prompt after the reset. `/usage-credits` shows or requests Team extra usage. Note it here if you do.

## Routine

Check `/usage` at the end of each working day, and right after any session that felt heavy. Log one line per check. If a limit hits, log the time and what you were doing.

| Date | Time | Persona | Session % | Weekly % | Hit limit? | What drove it (task, model, long context, subagents) |
|---|---|---|---|---|---|---|
| 2026-10-__ | | | | | | |

## After two weeks, decide

- Weekly limit never hit → stay subscription-only.
- Hit late in the week → turn on *Continue automatically* waits, or Team extra usage.
- Hit early or often → unpark `claude-api` (see `later/README.md`) as the overflow path.

## Branch protection per mapped repo (surveyed 2026-10-15)

For each of the 16 git repos under `~/Work/{biozentrum,elixir,ga4gh}`, the default branch's effective rules and classic protection were read via the GitHub API. Rulesets target the **default** branch, which is `dev` for some repos.

**Private repos without a paid plan: none.** Every mapped GitHub repo is public, so rulesets are free on all of them.

To keep `git push` on ask in a repo (this also covers its `claude -w` worktrees), create `<repo>/.claude/settings.local.json`:

```json
{ "permissions": { "ask": ["Bash(git push *)"] } }
```

### Rulesets impossible (not on GitHub): decide ask per repo

- [ ] `biozentrum/pls-2025` (GitLab, git.scicore.unibas.ch: use its protected branches instead)
- [ ] `biozentrum/programming_for_life_sciences_2025` (no remote: pushes fail until one is added)
- [ ] `biozentrum/programming_for_life_sciences_2026` (no remote: pushes fail until one is added)
- [ ] `biozentrum/programming_for_life_sciences` (GitLab, git.scicore.unibas.ch: use its protected branches instead)

### No protection yet: add a ruleset before agents push there

- [ ] `elixir/demo-tes-hybrid-cloud` → elixir-cloud-aai/demo-tes-hybrid-cloud (default `main`)
- [ ] `elixir/elixir-cloud-visualizations` → uniqueg/elixir-cloud-visualizations (default `main`)
- [ ] `elixir/harbor-helm` → uniqueg/harbor-helm (default `main`)
- [ ] `ga4gh/ga4gh-io-schema` → uniqueg/ga4gh-io-schema (default `main`)
- [ ] `ga4gh/ga4gh-registry` → uniqueg/ga4gh-registry (default `main`)

### Classic branch protection only: check that it requires a PR and blocks force pushes (or replace it with a ruleset)

- [ ] `biozentrum/zarp-cli` → zavolanlab/zarp-cli (default `dev`)
- [ ] `biozentrum/zarp` → zavolanlab/zarp (default `dev`)
- [ ] `elixir/elixir-cloud-demos` → elixir-cloud-aai/elixir-cloud-demos (default `main`)
- [ ] `elixir/landing-page` → biohackcloud/landing-page (default `main`)
- [ ] `elixir/proTES` → elixir-cloud-aai/proTES (default `dev`)
- [ ] `elixir/proWES` → elixir-cloud-aai/proWES (default `dev`)

### No action needed

- `psankhe28/cloud-storage-handler`: no push access. Agents go through `gh repo fork`, and the upstream's own protection applies.
