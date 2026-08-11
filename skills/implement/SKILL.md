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

## 9. Watch the PR

Read `~/.claude/skills/pr-watch/SKILL.md` and follow it: a bounded background
watch on the PR that wakes the session when review comments or CI results
land, assesses new comments, and fixes the mechanical ones through the same
split as steps 5 and 6. It always terminates on its own, and it never re-arms
after a fix push. When it closes, the run ends: whatever lands later is the
user's, in a separate session.
