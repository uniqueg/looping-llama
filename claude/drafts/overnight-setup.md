# Overnight setup: review gate and approvals (2026-10-20)

Yes, the plan works. I'll squash-merge my own PRs only under the conditions in
`CLAUDE.local.md`: CI green, Sourcery/Copilot reviews done, no open threads,
merged in stack order. I'll work through (a), then (b), then (c). When
something needs your approval, I'll skip it, note it and move on to the next
useful item.

## A. Set up the adversarial reviewers (about 5 minutes, fish)

I tested the `sed` and `jq` commands on copies of your files. Full details are
in `~/Work/agent-stack/claude/drafts/review-setup/INSTALL.md`.

```fish
# 1. Tools  (/usr/bin/sg is NOT ast-grep)
mise use -g semgrep ast-grep pre-commit

# 2. Move agents and hook into agent-stack
cd ~/Work/agent-stack
mkdir -p claude/agents claude/hooks
mv claude/drafts/review-setup/agents/*.md claude/agents/
mv claude/drafts/review-setup/hooks/pre-push-checks.sh claude/hooks/
chmod +x claude/hooks/pre-push-checks.sh

# 3. Link the agents into both profiles, and make link.sh keep doing it
for p in personal academic
    ln -sfn ~/Work/agent-stack/claude/agents ~/.claude-$p/agents
end
sed -i 's|^  link "$AGENT_STACK/claude/skills" "$cfg/skills"$|&\n  link "$AGENT_STACK/claude/agents" "$cfg/agents"|' link.sh

# 4. Register the hook (run once; patches the live settings, not via link.sh)
set snip ~/Work/agent-stack/claude/drafts/review-setup/settings-snippet.json
for f in ~/.claude-personal/settings.json ~/.claude-academic/settings.json ~/Work/agent-stack/claude/settings.base.json
    cp $f $f.bak.(date +%Y%m%d%H%M%S)
    jq --indent 2 --slurpfile s $snip '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + $s[0].hooks.PreToolUse)' $f > $f.tmp
    and mv $f.tmp $f
end

# 5. CLAUDE.md: new step 6 "review before every push"; later steps renumbered
cd ~/Work/agent-stack/claude
diff CLAUDE.md drafts/review-setup/CLAUDE.md.new
mv drafts/review-setup/CLAUDE.md.new CLAUDE.md
```

After restarting Claude, `/agents` should list both reviewers, and `/hooks`
should show `PreToolUse → Bash`.

**Don't run `link.sh` for now.** Your live `settings.json` files have drifted
far from `settings.base.json`: auto mode, many permissions, `git commit`/`git
fetch` excluded from the sandbox. `link.sh` would replace them with the stale
base, keeping only a backup.

Optionally, commit agent-stack afterwards:

```fish
cd ~/Work/agent-stack
git add claude/agents claude/hooks claude/CLAUDE.md claude/settings.base.json link.sh
git commit -m "feat: add pre-push review gate"
```

## B. Approvals I'll need overnight

1. **`gh issue edit` / `gh issue comment` / `gh pr comment` / `gh pr review` /
   `gh issue create`.** These are either in your `ask` list or blocked by the
   classifier; it already denied the #68 amendment. I need them for:
   - #68;
   - closing #30, #32, #40 and #44 with a comment;
   - `@dependabot rebase` on #55/#57;
   - replying to review threads.

   Allow them temporarily:

   ```fish
   set f ~/.claude-personal/settings.json
   cp $f $f.pre-overnight
   jq --indent 2 '["Bash(gh issue edit *)","Bash(gh issue comment *)","Bash(gh issue create *)","Bash(gh pr comment *)","Bash(gh pr edit *)","Bash(gh pr review *)"] as $r | .permissions.ask = ((.permissions.ask // []) - $r) | .permissions.allow = ((.permissions.allow // []) + $r | unique)' $f > $f.tmp; and mv $f.tmp $f
   # Tomorrow, to revert:
   #   mv ~/.claude-personal/settings.json.pre-overnight ~/.claude-personal/settings.json
   ```

   If you also run step A.4, do this one afterwards (or the revert drops the
   hook again).

   Or apply #68 yourself right now:

   ```fish
   gh issue edit 68 -R elixir-cloud-aai/cloud-registry --body-file /tmp/claude-1000/-home-uniqueg-Work-elixir-foca/4524d39e-1037-4b70-a716-b937796a5b2f/scratchpad/body68.md
   ```

2. **Merging PRs that aren't mine.** Your new permission covers only my own
   PRs. The plan has these going in during (a):
   - Dependabot #55 and #57, once my CI fix (#83) is merged;
   - #56, after I push tests to the contributor's fork.

   If you reply **"you may also merge #55, #57 and #56 once green and
   reviewed"**, I'll merge them too. Otherwise I'll leave them for you, and N2
   will touch the same files (`requirements_dev.txt`) and need a rebase later.

3. **Pushing to the contributor's fork (#56).** "Maintainers can edit" is
   enabled, but the classifier may still refuse to push to someone else's
   repository. If it does, I'll put the tests in my own PR instead and credit
   the contributor.

4. **The `pypi` environment** in Settings → Environments is still yours to
   check tomorrow. Nothing tonight depends on it.

Things I'll avoid because they would hit the guards:

- force-pushes: I rebase stacked branches by merging `dev` into them instead;
- branch-protection and ruleset changes;
- anything that needs secrets.

## C. Current state

- **Created:** issues #69–#82.
- **Posted:** the review on #61.
- **PR #83 (N1):** CI is green and the PR is marked ready; I'm waiting for
  Sourcery.
- **Next:** handle Sourcery's comments on #83 and merge it, then N2, N3 + N4
  together (#70–#72), rebase #65, then (b).

Everything is in the handoff memory, so a new session can pick it up.

## Blocked

- **RESOLVED (user changed the ruleset: 0 approvals required; #83 is
  now CLEAN).** Previously, merging #83 needed an approving review:
  (2026-10-20, session 3.) #83 has green CI and both Sourcery threads are
  resolved, but GitHub reports `reviewDecision: REVIEW_REQUIRED`, so the PR
  is `BLOCKED`. I can't approve my own PR, and I won't use an admin bypass.
  To unblock: approve #83, or have a co-maintainer approve it. Then I merge
  it under the overnight mandate. Until then I keep stacking PRs:
  N2 → `ci/fix-ci`, N3+N4 → `build/packaging`.
- **#89 (external, montionugera) vs. my #90: your call on closing #89.**
  Both target #71/#72/#32/#40. #89's #72 fix is correct, but it does NOT
  fully address #71/#40:
  - its fixtures need `flask_pymongo`, so the suite cannot even load on
    FOCA 0.14 (#65);
  - its mock identity provider accepts tokens signed with any key (a forged
    token gets 200).

  I posted a review comment on #89 but did not close it. I plan to merge #90
  once CI is green and Sourcery has reviewed it. GitHub then closes the
  issues via #90; #89 stays open for you to close, with thanks.
- **#68:** nothing needed. Your amendment (`strategy: Recreate`) is in the
  issue body.
- **Your unsigned commits block #65 and #66.** The first 3 commits of each
  were committed as `alexander.kanitz@alumni.ethz.ch`. That address is not
  verified on your GitHub account (`no_user`), so `required_signatures`
  blocks the merge, even as a squash. Fixing this would take a force-push,
  which I may not do.
  - #65: I opened **#92**: the same tree as one signed squash commit, with
    you as the author. I merge #92 once Sourcery is done. #65 stays open
    for you to close.
  - #66 (your draft): still blocked. Either rebase it onto `dev` with
    re-signed commits and force-push it yourself, or tell me to recreate it
    as a signed squash, like #92. For the future: verify the alumni address
    on GitHub, or commit with the gmail identity in scratch clones.
- **#99 (#68, MongoDB pin/auth/probes): needs your decision on the
  default MongoDB version.** The draft PR is reviewed (two rounds) and
  documented. Chart v2 used `mongo:noble`, which now resolves to MongoDB
  9.0. Community Edition does not support binary downgrades, so with the
  new default `mongo:7.0`, production must set `mongodb.image` to its
  running version before upgrading. Options:
  - (a) keep `mongo:7.0` as the default (it avoids the kernel bug
    SERVER-121912) and rely on the docs;
  - (b) default to what production runs (e.g., `mongo:9.0`).
  Please check the production version; the command is in
  `deployment/README.md`. #99 stays a draft until then.
- **(c) is blocked on #62 / #66.**
  - N10–N13 (#78–#81) are planned "after #62".
  - #61, #59, #63 and #64 depend on #62, directly or via #61.
  - #13 and #20 are large spec-changing features.
  - N14 (#82) builds on #68 (#99, see above).
  - #62 is implemented by your draft #66, which is blocked by its unsigned
    commits (see above).
  - To unblock, either re-sign and force-push #66 yourself, or tell me to
    recreate it as a signed squash (like #92). I then rebase it on `dev`,
    because #95–#98 changed the same files, and continue with (c).
