---
name: implement-plan
description: 'Implement one unit of work from a plan in an isolated worktree, raise the PR, review it, apply the mechanical findings, print the judgement ones, and write the PR back to the plan. USE WHEN: user says "get a subagent to implement PR1", "implement the next PR from the plan", "implement <unit> from <plan>", or asks for a scoped piece of a plan to be built and raised as a PR. For work the user describes themselves, with no plan behind it, use the implement skill instead.'
---

# Implement a plan unit

Run the `implement` flow on one unit from a plan. This skill owns only what
`implement` doesn't: resolving the unit, and writing the PR back.

## Where plans live

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Claude/Plans
```

- Plans drive the work; they never travel with it — no copies in the repo,
  no mention in commits or PR text. Your only plan edits are step 4's.
- Named plan → use it. "The plan" + one plausible file → use it, say which.
  Several → ask.
- No plan covers the work → wrong skill; use `implement`.

## 1. Resolve the scope

Plans have no fixed structure — a unit may be a table row, section, or
bullet, and "PR1" is the user's name for it. Work out:

- which unit the user means
- what else in the document constrains it — shared checklists, conventions,
  reference PRs; these live far from the unit and are what an agent misses
- the base branch: dependency merged → default branch; still open → that
  branch, and say so

Produce a scope brief: the unit plus every constraint, written out. The
agent never reads the plan.

## 2. Confirm

State the unit, the base branch and why, anything ambiguous. Wait — a wrong
reading costs a run.

## 3. Run the implement flow

`~/.claude/skills/implement/SKILL.md` from its step 2 onward; its step 1 is
replaced by yours. Its failure rules hold: implementer fails → no review, no
write-back, worktree stays.

Differences:

- **Branch name** (its step 2): name it after the unit
- **Write-back** (after its step 3): as soon as the draft PR exists, do
  step 4 below — the number won't change
- **Report** (its step 7): add one line — plan updated or not, and why not

## 4. Write back

Two edits, confined to this unit:

**Status table.** Update the unit's row: state plus PR number, in the
table's own convention. No table → add a simple one. Default:
`Not started` → `🔍 [#658](real PR URL)` open → `✅ [#657](real PR URL)`
merged.

**Remove the unit's implementation notes.** The PR is the source of truth
now; leftover notes describe what was intended and mislead the next unit's
scoping. Delete the how — approach sketches, proposed code, step
sequences — and leave one line linking the PR.

Keep: the unit's heading, one line on what it covers, and anything that
constrains **future** units.

Touch nothing else — no other units, no reformatting, no typo fixes. A
write fails → don't retry in a loop; report it at the end.
