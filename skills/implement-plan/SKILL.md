---
name: implement-plan
description: 'Implement one unit of work from a plan in an isolated worktree, raise the PR, tear the worktree down, print a review, and write the PR back to the plan. USE WHEN: user says "get a subagent to implement PR1", "implement the next PR from the plan", "implement <unit> from <plan>", or asks for a scoped piece of a plan to be built and raised as a PR. For work the user describes themselves, with no plan behind it, use the implement skill instead.'
---

# Implement a plan unit

Take one unit of work from a plan, build it in a throwaway worktree, raise a PR,
run a review over it, and leave the repo with no worktree behind — so the branch
can be checked out normally in an IDE.

Your job is scoping, dispatch, and cleanup. **Do not write any of the
implementation yourself.**

**Once the PR is up and the worktree is gone, no more code changes.** The review
that follows is static: it prints findings and stops. Deciding what to act on,
and acting on it, is the user's, in their own session.

## Where plans live

```
~/notes/Plans
```

An Obsidian vault outside the working repo, granted via `additionalDirectories`.

Plans drive the work; they do not travel with it. Never copy a plan into the
repo, and never let one reach a commit message or PR description. The only
edits you ever make to a plan are the write-backs in step 6.

If the user names a plan, use it. If they refer to "the plan" and only one file
in that directory plausibly covers the current repo or task, use it and say
which. If several could, ask.

If no plan covers the work — the user described it themselves — you are in the
wrong skill. Use `implement` instead. It is the same flow without the plan
resolution here and the write-backs in step 6.

## 1. Resolve the scope

Plans are written for humans and have no fixed structure. A unit might be a
table row, a named section, a checklist item, or a bullet. "PR1" is what the
user calls it, not necessarily what the document calls it.

Read the plan and work out:

- **Which unit** the user means.
- **What else in the document applies to it** — shared checklists, hard
  constraints, conventions, per-area notes, reference PRs. These usually live
  far from the unit itself and are the part an agent will otherwise miss.
- **What base branch it should build on.** Units frequently depend on earlier
  ones. If a dependency is merged, base on the default branch. If it is still
  open, base on that branch and say so. You hold this context; the agent does
  not.

Produce a **scope brief**: the unit plus every section that constrains it,
written out. Not a file path — the agent will not read the plan.

## 2. Confirm before dispatching

State in a few lines:

- The unit you resolved, and what it covers
- The base branch and why
- Anything in the plan that looked ambiguous

Wait for the user. This is the cheap checkpoint — a wrong reading here costs a
whole implementation run.

## 3. Create the worktree

Read `~/.claude/skills/worktree/SKILL.md` and follow parts 1 and 2 — preflight
and create. That file is the single source of truth for the worktree lifecycle.

You create it, so you can always clean it up — even if the agent never reports
back. Base it on the branch you resolved in step 1, and name it after the unit,
following whatever naming the plan or the repo's recent branches use.

If creation fails, stop there. Do not dispatch the agent.

## 4. Dispatch the implementer

Spawn the `implement-pr` agent with the Agent tool, `run_in_background: false`.
Pass it:

- The **scope brief** inline, in full
- The **absolute worktree path** — it enters that, it does not create one
- The **base branch**, so the PR targets the right place

Do not pass a plan file path. Do not pre-write the commit message, PR title, or
PR description — the PR procedure owns those.

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

## 6. Write the PR back to the plan

Do this as soon as the PR exists — the number will not change later. Two
edits, both confined to the unit you just implemented.

**First, the status table.** Look for a status or tracking table in the plan,
the kind that lists units against their state. If there is one, update the row
for the unit you just implemented: mark it done or in progress as appropriate,
and record the PR number the same way the existing rows record theirs. Prefer
the existing convention — if done rows read `✅ #601`, write `✅ #607`. If there
is no status table, add a simple one listing the plan's units and their state,
so this and future PRs have somewhere to land.

**Second, remove the unit's implementation notes.** The PR now holds the real
implementation; the code is the source of truth. Notes left in the plan
describe what was *intended*, not what was *built* — the agent scoping the next
unit will read them as fact and be misled. Delete the how: approach sketches,
proposed code, file-by-file breakdowns, step sequences, anything an implementer
would follow. In their place leave a single line pointing at the PR, in the
plan's own link style.

Keep:

- The unit's heading and a one-line statement of what it covers — the plan must
  still show its shape.
- Anything that constrains **future** units — shared checklists, conventions,
  hard constraints, decisions later units depend on that live nowhere else.
  These are not this unit's notes, even when they sit next to it.

Rules for both edits:

- **Only this unit's content.** Do not touch other units, shared prose, or
  headings elsewhere in the document. Creating a missing status table is the
  one exception.
- **Nothing else changes.** No reformatting, no fixing typos you noticed, no
  ticking checklist items elsewhere in the document.

If a write fails, do not retry in a loop. Carry on and tell the user at the
end that the plan was not updated.

## 7. Review and print the findings

Invoke the `pr-review` skill with the PR number. It reads the diff from GitHub,
so it needs no working tree.

Show the merged review here, in chat. **Do not post it to the PR.** Present
every finding — defects, quality, design — as a numbered list, most serious
first, each one a line or two: what is wrong, where, and the suggested fix. If
the review is clean, say so.

Then stop. **Do not fix anything.** The user reviews the PR themselves and
decides what is worth acting on; review agents produce plausible-but-wrong
findings and cannot see the reasoning behind the change.

## 8. Report

Give the user:

- PR number and link
- One line on what was implemented
- Anything the agent flagged as out of scope or unresolved
- The branch name, ready to check out
- Whether the plan was updated — status row and implementation notes removed —
  and say so explicitly if either edit did not happen, and why

Then you are done. The run ends here: the PR is up, the worktree is gone, and
nothing further touches the code. CI, the findings above, and the user's own
review are all theirs to act on, in a separate session.

Do not restate the plan or recap the process.
