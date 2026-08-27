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

Open with `plan-housekeeping` on this plan. Units merge between sessions and
nothing writes it back, so the table in front of you is the last session's,
not today's — and a row that still says open when its PR merged sends this
unit at the wrong base branch.

Plans have no fixed structure — a unit may be a table row, section, or
bullet, and "PR1" is the user's name for it. Work out:

- which unit the user means
- what else in the document constrains it — shared checklists, conventions,
  reference PRs; these live far from the unit and are what an agent misses
- the base branch: dependency merged → default branch; still open → that
  branch, and say so

Produce a scope brief: the unit plus every constraint, written out. The
agent never reads the plan.

**Carry the ticket key into the brief** when the unit's row has one.
`raise-pr`'s PROCEDURE.md makes the key conditional on the caller supplying
it — no key given, no key line — and forbids recovering one from the branch
name. So the implementer emits a keyless PR and is right to. Reading the key
to move the ticket is not the same as passing it on; that omission is
invisible until the PR is already up.

## 2. Confirm

State the unit, the base branch and why, anything ambiguous. Carrying a
ticket key → say it will move too, and to which statuses. That yes covers
every Jira write in this run. Wait — a wrong reading costs a run.

## 3. Run the implement flow

`~/.claude/skills/implement/SKILL.md` from its step 2 onward; its step 1 is
replaced by yours. Its failure rules hold: implementer fails → no review, no
write-back, worktree stays.

Differences:

- **Branch name** (its step 2): name it after the unit, prefixed with the
  unit's Jira key when it has one (`DEV-123-add-cart-totals`). The branch
  name is what a PR list, a CI run and a worktree directory show first —
  the key there ties all three back to the ticket
- **Write-back** (after its step 3): as soon as the draft PR exists, do
  step 4 below — the number won't change
- **Ticket** (after its step 3): step 5 below
- **Report** (its step 7): add one line each — plan updated or not, ticket
  moved or not, and why not

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

## 5. Move the ticket

Only when the unit's row carries a Jira key — no key, or no Ticket column,
skip in silence. The `jira` skill owns the commands; its preflight still
applies, and a missing or unauthenticated `acli` skips the ticket, said
once, rather than stopping the run.

Two moments:

- **Draft PR raised** — comment the PR URL, and move the ticket to the
  site's in-progress status.
- **PR merged** — `plan-housekeeping` saw it, in this run's step 1 or a
  later one — move it to the project's done status. Merged is the only
  trigger; a closed PR is not done.

Read the current status before each move — already there, or further on →
nothing to do. Never move a ticket backwards.

```bash
acli jira workitem view ABC-124 --fields status --json
acli jira workitem transition --key ABC-124 --status "<the site's own name>" --yes
```

Status names vary by site, and `acli` cannot list a workflow's transitions —
the `transitions` field is always empty. Take the names from the project's
own items instead of guessing:

```bash
acli jira workitem search --jql "project = ABC ORDER BY updated DESC" \
  --limit 50 --fields status --json
```

A rejected transition is a workflow rule, not a typo — report it and carry
on. Nothing about Jira fails the run or holds the PR.
