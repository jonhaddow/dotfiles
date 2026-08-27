---
name: implement
description: 'Build a piece of work — a bug fix, a small feature, a rename, a cleanup — in an isolated worktree, raise a draft PR, review and fix it before opening it to humans, and print the judgement findings for the user. USE WHEN: user asks for a change to be implemented, says "fix this", "implement X", "build X and raise a PR", "get a subagent to make this change", or describes a scoped change they want built and raised as a PR. For a unit of work from a plan document, use the implement-plan skill instead.'
---

# Implement

Build one piece of work in a worktree, raise a **draft** PR, review and fix
it while nobody is watching, then open it. You scope, dispatch, and clean
up — **never write the change yourself**.

Every finding is **mechanical** (concrete, local, verified — a fix agent
applies it) or **judgement** (everything else — printed for the user, never
applied). When in doubt: judgement.

## 1. Scope

Write a brief for a cold agent:

- What should change, and why
- Anything this session already established (diagnosis, stack trace, decisions)
- What is out of scope
- Whether tests are expected, if convention doesn't settle it

Don't read the codebase for this — the agent has search tools.

Base branch: the remote default, unless the user names another or the work
stacks on an open branch.

Then question the shape, while it's still free: does the brief hold more
than one reason to change — unrelated concerns, a risky part bundled with a
safe one, a refactor that enables the feature? If a seam is obvious, say so
and let the user pick one unit or ask for a plan. If the brief is too vague
to tell, don't guess — step 4 asks again against the real diff.

Ambiguous → ask now. Otherwise state scope and base in a line and go.

## 2. Worktree

Worktree skill, parts 1–2. You created it → you remove it, even if the agent
dies. Creation fails → stop.

## 3. Dispatch

`implement-pr` agent, foreground. Pass: the brief in full, the absolute
worktree path, the base branch, and "raise as draft". Don't pre-write commit
or PR text.

Failure → stop, no review. Relay it, leave the worktree, give the path.

## 4. Review + CI

- Invoke `pr-review` with the PR number. Its scope check runs first: a
  `split` verdict stops the review there — skip to step 7, hold the draft,
  and run no fix pass. Bug findings against a diff you're about to
  rearrange are worse than none.
- While it runs: `gh pr checks <n>`. No checks → CI skips drafts; note it,
  move on. Take what's terminal when the review returns — don't hold the
  draft for a slow suite; the watch covers it.
- Red checks the PR owns (lint, typecheck, its tests) → mechanical.
  Flake / infra / unrelated → judgement. Append them to the review file
  under the same two sections, with the check name and the log excerpt —
  one file holds everything step 5 and step 7 draw from.
- Hold the report until step 7. Never post it to the PR.

## 5. Fix

Mechanical findings → `apply-review-fixes` agent, foreground: the review
file path — its `## Mechanical` section is the agent's whole scope — plus
the worktree path, the PR number and branch. Don't restate the findings. It verifies, fixes,
pushes, and refreshes the PR text. Skips become judgement findings.
Failure → carry its findings into the report unfixed.

## 6. Open

Remove the worktree (worktree skill part 4). Then `gh pr ready <n>`. Don't
wait for the fresh CI — the watch covers it.

## 7. Report

- PR link, one line on the change, and whether it's open or held draft
- **Should this be split?** — only if the review says so: the seam, and that
  it's still draft pending your call
- **Fixed and pushed** — one line each
- **For your judgement** — exactly as `pr-review` printed them, order and
  wording untouched. A skipped mechanical fix joins them, the skip reason
  standing in for the recommendation.
- Verdict, implementer flags, branch name
- The review file path, last

The user never saw the diff — an agent wrote it. So the short form is the
whole report: no mechanism, no reasoning chain, no quoting from the review
file. The file holds the rest. Fix nothing further. No process recap.

## 8. Watch

`pr-watch` skill: reviews and fresh CI land on the opened PR, same
mechanical/judgement split. It ends on its own — after that, the run is over.

Held draft → no watch. Nothing is coming until the user opens it.
