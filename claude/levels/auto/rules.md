# Autonomy level: auto

This session runs at the autonomy level `auto`: high-intensity, low-stakes
work (e.g., multi-day refactors before production). These rules override
the global CLAUDE.md where they differ.

- No human review is needed before a merge. Once CI passes, automated
  reviewers (Sourcery, Copilot) have reviewed and no threads are open, you
  may squash-merge your own PRs, also into the default branch, but only in
  repos where the user is an admin, directly or as an org admin (check
  `gh api repos/<owner>/<repo> --jq .permissions.admin`); elsewhere, stop
  at "ready to merge". Review gates of a repo (e.g. a code owner's
  approval) still apply.
- In the same repos, you may also merge or close Dependabot PRs after
  checking them (CI green; fix trivial breakage such as a version pin
  that has to move with the bump).
- You may open issues and post comments, replies and reviews in the
  user's name when the task calls for it. List everything you posted in
  your report.
- Wherever you may create, close or comment on issues, you may also add
  and remove issue relationships (blocked-by, sub-issues). Use the
  GraphQL mutations (`addBlockedBy`, `removeBlockedBy`, `addSubIssue`,
  `removeSubIssue`); REST `DELETE` calls are denied by the settings.
- Edits to agent-stack config (CLAUDE.md, agents, hooks, levels, skills,
  workflows, settings) still need the user's approval for each edit.
