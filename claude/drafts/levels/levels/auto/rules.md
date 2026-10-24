# Autonomy level: auto

This session runs at the autonomy level `auto`: high-intensity, low-stakes
work (e.g., multi-day refactors before production). These rules override
the global CLAUDE.md where they differ.

- No human review is needed before a merge. Once CI passes, automated
  reviewers (Sourcery, Copilot) have reviewed and no threads are open, you
  may squash-merge your own PRs into non-default branches.
- You may open issues and post comments, replies and reviews in the
  user's name when the task calls for it. List everything you posted in
  your report.
- Edits to agent-stack config (CLAUDE.md, agents, hooks, levels, skills,
  workflows, settings) still need the user's approval for each edit.
