---
name: implement
description: 'Build a piece of work — a bug fix, a small feature, a rename, a cleanup — in an isolated worktree, raise the PR, review it, apply the mechanical findings, and print the judgement ones for the user. USE WHEN: user asks for a change to be implemented, says "fix this", "implement X", "build X and raise a PR", "get a subagent to make this change", or describes a scoped change they want built and raised as a PR. For a unit of work from a plan document, use the implement-plan skill instead.'
---

# Implement

Take one piece of work, build it in a throwaway worktree, raise a PR, run a
review over it, and leave the repo with no worktree behind — so the branch can
be checked out normally in an IDE.

The scope comes from the user. If it comes from a plan document instead, use
`implement-plan`: the same flow, plus plan resolution and a write-back to the
plan.

Your job is scoping, dispatch, and cleanup. **Do not write any of the change
yourself.**

The review that follows splits its findings by disposition. **Mechanical**
findings — concrete, local, verified against the code — are applied by a fix
agent and pushed to the PR. **Judgement** findings are printed and left alone:
deciding on those is the user's, in their own session. After the report, a
time-boxed watch stays on the PR: Copilot reviews and CI land minutes after a
PR goes up, and late comments get the same assess-and-split treatment, with a
fresh worktree for any mechanical fixes. When the watch closes, the run is
over and nothing further touches the code.

## 1. Write the scope brief

The user's request is the specification. The agent starts cold — it cannot see
this conversation — so write out everything it needs:

- **What is wrong, or what should change**, in the user's own terms. For a bug:
  the symptom, how to reproduce it, and the correct behaviour.
- **Anything already established in this session** — a diagnosis, a stack trace,
  a file or function the user pointed at, a decision on how to fix it.
- **The boundary.** What is explicitly out of scope. Small changes drift.
- **Whether tests are expected**, if the repo's convention does not settle it.

Do not go reading the codebase to write the brief. The agent has search tools
and does that work; you only pass on what you already know.

Pick the **base branch**: the default branch, from the remote. Use something
else only if the user names it, or if the work depends on an open branch — say
which and why.

If the request is really several PRs, or needs design decisions the user has not
made, say so now. Suggest a plan and `implement-plan` instead of splitting it
yourself.

## 2. Confirm — briefly

If anything is ambiguous — which of two behaviours is correct, how wide the
change should go, which branch to base on — ask, and wait. One wrong reading
costs a whole run.

If nothing is ambiguous, state the scope and base branch in a line or two and
carry on. Do not stop for approval on a change the user has already described
clearly.

## 3. Create the worktree

Read `~/.claude/skills/worktree/SKILL.md` and follow parts 1 and 2 — preflight
and create. That file is the single source of truth for the worktree lifecycle.

You create it, so you can always clean it up — even if the agent never reports
back. Base it on the branch you picked in step 1, and name it after the change
(`fix-empty-cart-total`).

If creation fails, stop there. Do not dispatch the agent.

## 4. Dispatch the implementer

Spawn the `implement-pr` agent with the Agent tool, `run_in_background: false`.
Pass it:

- The **scope brief** inline, in full
- The **absolute worktree path** — it enters that, it does not create one
- The **base branch**, so the PR targets the right place

Do not pre-write the commit message, PR title, or PR description — the PR
procedure owns those.

It returns a PR number and URL, and notes.

**If it reports a failure**, stop. No review. Relay what blocked it, and give
the user the worktree path so they can look at the work — you have it from
step 3 regardless of what the agent returned. Leave the worktree in place.

## 5. Review and split the findings

Invoke the `pr-review` skill with the PR number. It reads the diff from GitHub,
picks its own level per axis — a one-line fix gets a light pass on its own —
and tags every finding **mechanical** or **judgement**.

Hold the merged report: do not render it here, and **do not post it to the
PR.** Its single rendering is the report in step 8, split by disposition, after
the fix pass has settled which findings survived.

Keep the worktree in place — the fix pass needs it.

## 6. Fix the mechanical findings

If nothing is tagged mechanical, go to step 7.

Otherwise spawn the `apply-review-fixes` agent with the Agent tool,
`run_in_background: false`. Pass it:

- The **mechanical findings**, in full — `file:line`, the defect, the
  suggested fix
- The **absolute worktree path**
- The **PR number and branch**

It verifies each finding against the code before touching it, fixes the ones
that hold, runs scoped checks, and pushes to the PR branch. Anything it skips —
refuted, out of scope, broke a check — comes back with a reason; treat those as
judgement findings from here on.

Fix nothing yourself, and dispatch nothing for judgement findings — those are
the user's call.

If it reports a failure, relay what blocked it, carry its findings into the
report unfixed, and go to step 7 — the emptiness checks there decide whether
the worktree can come down.

## 7. Remove the worktree

Nothing later in this flow needs it — no code changes after the fix pass.

Follow part 4 of `~/.claude/skills/worktree/SKILL.md`: both emptiness checks,
then `git worktree remove --force`. If either check is non-empty, stop and tell
the user rather than forcing it.

## 8. Report

Give the user:

- PR number and link
- One line on what changed
- **Fixed and pushed** — the findings the fix pass applied, one line each
- **For your judgement** — every remaining finding, numbered, most serious
  first, each one a line or two: what is wrong, where, and the suggested fix.
  For the fix pass's skips, add why they were not applied.
- The review verdict
- Anything the implementer flagged as out of scope or unresolved
- The branch name, ready to check out

If the review found nothing, say so. Render every finding exactly once, here —
the user never sees the agents' replies directly.

**Fix nothing further in this round.** The judgement findings are the user's:
review agents produce plausible-but-wrong findings and cannot see the
reasoning behind the change, which is exactly why nothing non-mechanical is
applied for them.

Do not recap the process. Then arm the watch — step 9.

## 9. Watch the PR — bounded

Copilot's review and CI both land a few minutes after the PR goes up — after
step 8 has already reported. Arm a background watch so those arrivals wake the
session, then leave it alone. Never sit in a foreground polling loop.

Use the Monitor tool: `persistent: false`, `timeout_ms: 900000`. The script
polls with `gh` every 30 seconds and:

- emits one line per new inline review comment and per new review
- emits one line per check run reaching a terminal state
- exits on its own when there is nothing left to wait for — every check
  terminal and no reviewer still requested — or at its own ~14-minute
  deadline, whichever is first. The Monitor timeout is only the backstop; the
  script's exit is the normal end, so an untouched PR stops the polling by
  itself.

Reference script — fill `repo` and `pr`, adapt as needed:

```bash
repo=<owner/repo>; pr=<n>; end=$((SECONDS + 840)); nc=0; nr=0; prev=""
while [ $SECONDS -lt $end ]; do
  c=$(gh api "repos/$repo/pulls/$pr/comments?per_page=100" 2>/dev/null) || c='[]'
  t=$(jq length <<<"$c")
  [ "$t" -gt "$nc" ] && jq -r --argjson n "$nc" '.[$n:][] |
    "comment by \(.user.login) — \(.path):\(.line // 0) — \(.body | gsub("[\r\n]+"; " ") | .[0:400])"' <<<"$c"
  nc=$t
  r=$(gh api "repos/$repo/pulls/$pr/reviews" 2>/dev/null) || r='[]'
  t=$(jq length <<<"$r")
  [ "$t" -gt "$nr" ] && jq -r --argjson n "$nr" '.[$n:][] |
    "review by \(.user.login): \(.state)"' <<<"$r"
  nr=$t
  s=$(gh pr checks "$pr" --json name,bucket 2>/dev/null) || s='[]'
  cur=$(jq -r '.[] | select(.bucket != "pending") | "check \(.name): \(.bucket)"' <<<"$s" | sort)
  comm -13 <(printf '%s\n' "$prev") <(printf '%s\n' "$cur")
  prev=$cur
  pending=$(gh pr view "$pr" --json reviewRequests --jq '.reviewRequests | length' 2>/dev/null || echo 1)
  jq -e 'length > 0 and all(.bucket != "pending")' <<<"$s" >/dev/null \
    && [ "$pending" -eq 0 ] && [ $SECONDS -gt 120 ] && break
  sleep 30
done
echo "watch over"
```

The 120-second floor stops an instant all-green from closing the watch before
Copilot has even been requested. A repo with no checks at all never satisfies
the early exit and simply runs to the deadline — still bounded.

Handle events as they arrive:

- **New comments** — refetch their full bodies with `gh`, then rerun the
  machinery of steps 5 and 6 on them alone: dispatch the defects agent at the
  level the review used, passing the comments and PR number, to judge each one
  addressed, valid, or invalid. Tag the valid ones mechanical or judgement by
  pr-review's rule. If any are mechanical: `git fetch origin`, re-create a
  worktree on the existing branch — `git worktree add
  .claude/worktrees/<branch> <branch>`, fast-forwarded to `origin/<branch>`;
  if it will not fast-forward, stop and tell the user — dispatch
  `apply-review-fixes`, then remove the worktree per part 4 of the worktree
  skill. Report the whole assessment in chat: fixed and pushed, for the
  user's judgement, addressed, invalid.
- **A failed check** — surface it: the check name and a line or two from
  `gh run view --log-failed`. Do not fix it; say what you would look at
  first.
- **The watch ends** — one line. If nothing arrived, say the watch closed
  quietly.

**One round only.** A fix push starts fresh CI and may draw a new Copilot
review; do not re-arm the watch for those, and never restart a watch that has
ended. Every path through this step terminates. Whatever lands after the
watch closes is the user's, in a separate session — the run ends here.
