Insert as a new step 6 in "Coding workflow" of the global CLAUDE.md
(between "5. Commit ..." and the current "6. Push ..."), renumber the
following steps (6→7, 7→8, 8→9), and update the two references to
"coding workflow step 8" in "Hard rules" and in step 9 itself to "step 9".

---

6. Before every push of code changes, review the branch: run the `adversarial-reviewer` and `quality-reviewer` subagents in parallel on `git diff <base>...HEAD` (pass the repository path and the base ref, e.g. `origin/dev`). Fix confirmed high and medium findings (commit, rerun the local checks from step 3), then review again: at most 2 rounds. List findings you decline, with reasons, under "Open questions" in the PR body. A `PreToolUse` hook additionally runs semgrep and ast-grep on `git push`; if it blocks the push, fix the findings or suppress them inline with a justification. Never bypass the hook. Pushes that change only docs or the PR body need no review.
