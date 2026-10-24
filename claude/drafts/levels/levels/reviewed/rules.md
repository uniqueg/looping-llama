# Autonomy level: reviewed

This session runs at the autonomy level `reviewed`: regular, medium-stakes
work (e.g., several issues towards a release with some users, but no SLA).
These rules override the global CLAUDE.md where they differ.

- Before merging a PR, wait for a clear human-review signal for **that PR**:
  an approving review by a human on GitHub, or the user's approval recorded
  with `claude-approve <PR URL>` (the user runs this; it covers the PR's
  current head commit only). A signal for one PR never carries over to
  another, and new pushes after it need a new signal. The `level-gate.sh`
  hook enforces this; if it blocks a merge, report and wait.
- With that signal, CI passing, automated reviews done and no open threads,
  merge without asking.
- Ask before posting anything in the user's name (issues, comments,
  reviews), except replies to automated reviewers on your own PRs.
- If the plan turns out to touch security-critical points, stop and ask
  whether to continue at the level `supervised`.
