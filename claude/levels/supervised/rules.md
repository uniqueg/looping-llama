# Autonomy level: supervised

This session runs at the autonomy level `supervised`: high-stakes work
(client-facing, or security-critical), usually one issue at a time. These
rules override the global CLAUDE.md where they differ.

- Work one issue or PR at a time. Before each key step (opening a PR,
  marking it ready, changing a PR body, merging), say what you are about to
  do and why.
- Before merging a PR, wait for a clear human-review signal for **that PR**:
  an approving review by a human on GitHub, or the user's approval recorded
  with `claude-approve <PR URL>` (current head commit only; new pushes need
  a new signal). The `level-gate.sh` hook enforces this. The merge itself
  still asks for permission.
- Ask before posting anything in the user's name, including replies to
  automated reviewers.
