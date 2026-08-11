---
name: implement-plan
description: 'Implement one unit of work from a plan in an isolated worktree, raise the PR, review it, apply the mechanical findings, print the judgement ones, and write the PR back to the plan. USE WHEN: user says "get a subagent to implement PR1", "implement the next PR from the plan", "implement <unit> from <plan>", or asks for a scoped piece of a plan to be built and raised as a PR. For work the user describes themselves, with no plan behind it, use the implement skill instead.'
---

# Implement a plan unit

Take one unit of work from a plan and run the `implement` flow over it. This
skill owns only what `implement` does not: resolving the unit from the plan
document, and writing the PR back to it. Everything else — worktree, dispatch,
review, fix pass, cleanup, report, PR watch — lives in `implement` and is not
repeated here.

## Where plans live

```
~/notes/Plans
```

An Obsidian vault outside the working repo, granted via `additionalDirectories`.

Plans drive the work; they do not travel with it. Never copy a plan into the
repo, and never let one reach a commit message or PR description. The only
edits you ever make to a plan are the write-backs in step 4.

If the user names a plan, use it. If they refer to "the plan" and only one file
in that directory plausibly covers the current repo or task, use it and say
which. If several could, ask.

If no plan covers the work — the user described it themselves — you are in the
wrong skill. Use `implement` instead: the same flow without the plan
resolution and write-backs.

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

## 3. Run the implement flow

Read `~/.claude/skills/implement/SKILL.md` and follow it from its step 3
onward — worktree, dispatch, review and split, fix pass, worktree removal,
report, PR watch. That file is the single source of truth for the flow; its steps 1 and
2 are replaced by yours above. Its failure rules travel with it: if the
implementer fails, there is no review, the worktree stays, and the write-back
below does not happen — there is no PR to write.

Three plan-specific differences:

- **Branch name** (its step 3): name the worktree branch after the unit,
  following whatever naming the plan or the repo's recent branches use.
- **Write-back** (between its steps 4 and 5): as soon as the PR exists, do
  step 4 below. The number will not change later, and the review's fix pass
  only adds commits to it.
- **Report** (its step 8): add one line — whether the plan was updated, status
  row and implementation notes removed — and say so explicitly if either edit
  did not happen, and why. Do not restate the plan.

## 4. Write the PR back to the plan

Two edits, both confined to the unit you just implemented.

**First, the status table.** Look for a status or tracking table in the plan,
the kind that lists units against their state. If there is one, update the row
for the unit you just implemented: mark it done or in progress as appropriate,
and record the PR number the same way the existing rows record theirs. Prefer
the existing convention — if done rows read `✅ #601`, write `✅ #607`. If there
is no status table, add a simple one listing the plan's units and their state,
so this and future PRs have somewhere to land. The `plan` skill writes these
tables as `Not started` → `🔍 [#658](https://github.com/org/repo/pull/658)` open
→ `✅ [#657](https://github.com/org/repo/pull/657)` merged, with the real PR URL
in the link, not a placeholder; use that only when the plan sets no convention
of its own.

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
