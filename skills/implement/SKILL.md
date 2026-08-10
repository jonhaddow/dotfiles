---
name: implement
description: 'Build a piece of work — a bug fix, a small feature, a rename, a cleanup — in an isolated worktree, raise the PR, tear the worktree down, and print a review. USE WHEN: user asks for a change to be implemented, says "fix this", "implement X", "build X and raise a PR", "get a subagent to make this change", or describes a scoped change they want built and raised as a PR. For a unit of work from a plan document, use the implement-plan skill instead.'
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

**Once the PR is up and the worktree is gone, no more code changes.** The review
that follows is static: it prints findings and stops. Deciding what to act on,
and acting on it, is the user's, in their own session.

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

## 5. Remove the worktree

As soon as the PR is raised. Nothing later in this flow needs it — the review
reads from GitHub, and no code changes after this point.

Follow part 4 of `~/.claude/skills/worktree/SKILL.md`: both emptiness checks,
then `git worktree remove --force`. If either check is non-empty, stop and tell
the user rather than forcing it.

## 6. Review and print the findings

Invoke the `pr-review` skill with the PR number. It reads the diff from GitHub,
so it needs no working tree, and it picks its own level per axis — a one-line
fix gets a light pass on its own.

Show the merged review here, in chat. **Do not post it to the PR.** Present
every finding as a numbered list, most serious first, each one a line or two:
what is wrong, where, and the suggested fix. If the review is clean, say so.

Then stop. **Do not fix anything.** The user reviews the PR themselves and
decides what is worth acting on; review agents produce plausible-but-wrong
findings and cannot see the reasoning behind the change.

## 7. Report

Give the user:

- PR number and link
- One line on what changed
- Anything the agent flagged as out of scope or unresolved
- The branch name, ready to check out

Then you are done. The run ends here: the PR is up, the worktree is gone, and
nothing further touches the code. CI, the findings above, and the user's own
review are all theirs to act on, in a separate session.

Do not recap the process.
