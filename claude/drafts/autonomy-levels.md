# Autonomy levels

Decided with the user on 2026-10-21. The levels replace `claude-merge.fish`
and the merge exception in foca's `CLAUDE.local.md`. A new level is a new
column. Level names say what the user's role is (decided 2026-10-21).

How levels are switched (decided 2026-10-21): one folder per level
(`claude/levels/<name>/` with `settings.json` and `rules.md`), chosen per
session. A single fish function `claude` takes `--level <name>`, otherwise
`$CLAUDE_LEVEL` (e.g., from direnv), otherwise `supervised`, and runs
`command claude --settings …/settings.json`. A `SessionStart` hook loads
`rules.md`. Profile wrappers (`claude-a`, `claude-p`) stay and call it. To
be tested first: that `--settings` sets the mode and adds `allow` rules on
top of the base settings.

| | **auto** | **reviewed** | **supervised** | **external** (fork of someone else's repo) |
|---|---|---|---|---|
| Typical use | Multi-day refactors before production | Several issues towards a release | Client-facing or security-critical work, one by one | Contributions to others' codebases |
| Mode | `auto` | `auto` | `acceptEdits` | `auto` |
| Commit, push feature branches | allow | allow | allow | allow, to the fork only; pushes to `upstream` denied |
| Open draft PR | allow | allow | allow | deny (the user opens it after reviewing the branch) |
| `gh pr ready`, `gh pr edit`, `gh api` (with deny patterns) | allow | allow | ask | deny (no PRs) |
| Answer automated reviewers on own PRs | allow | allow | ask | – |
| Posting in the user's name: issues, PR comments, reviews | allow | ask | ask | ask (e.g., discussing an upstream issue) |
| Human review before merging | skipped | required: per PR, an approving review, or the user says "skip" for that PR | required, as in Medium | – |
| Merge own PRs (non-default branches; rulesets guard default branches) | allow | allow, once human review is done | ask, once human review is done | deny |
| Edit agent-stack config (CLAUDE.md, agents, hooks, skills, settings) | ask | ask | ask | ask |
| Always denied | `gh release`, `gh auth`, `gh secret`, `gh repo edit`/`delete`, force-push, secret files | same | same | same |

Notes:

- The review signal is per PR; a signal for one PR does not carry over.
- External: report the branch name and the compare link instead of a PR.
