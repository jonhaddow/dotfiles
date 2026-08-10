---
name: plan
description: 'Turn a feature or piece of work into a planning document in the Obsidian vault — grounded in the codebase, gaps settled by grilling, split into small incremental PRs, with a status table for tracking. USE WHEN: user says "plan this", "brainstorm X", "let''s plan the X feature", "write a plan for", or describes work big enough to need more than one PR. The implement-plan skill then builds each unit from the document this produces.'
---

# Write a plan

Produce one document in `~/notes/Plans` that another session can implement from,
one PR at a time, without you in the room.

The document is read later by an orchestrator with no memory of this
conversation. Everything it needs must be on the page. Nothing on the page may
be a guess dressed as a fact.

## 1. Check what already exists

```bash
ls ~/notes/Plans
```

If a plan already covers this work, open it and extend it. Do not write a second
document on the same subject. If a related plan exists — a dependency, a
prerequisite, a plan this one supersedes — note it now; it will be linked.

## 2. Ground it in the codebase

Finding facts is your job, never the user's. Before asking anything, dispatch a
subagent to establish current state: what exists today, where it lives, what
already does part of this, what the repo's conventions are, and what would have
to change.

Use `Explore` for "where is it and what shape is it", the `Plan` agent when the
work needs an architectural read. Do not read the codebase yourself in this
session — you need the context for the writing.

What comes back becomes the **Current state** section, and usually shrinks the
work: half the plan is often already built.

## 3. Grill the gaps

Read the ask against what you found and list every decision the plan cannot be
written without: behaviour at the edges, the shape of the data, what happens on
failure, migration of existing state, scope boundaries, ordering constraints.

**If any decision is genuinely open, invoke the `grilling` skill and settle them
before writing.** Do not write a plan over an unsettled decision. A guess on the
page becomes fact to the session that implements it, and nobody rereads a plan
to check whether its premises held.

Skip the grilling only when the work has no open decisions — a mechanical
change, or something the user has already specified end to end. Say which, in
one line, rather than skipping silently.

If decisions are open and the `grilling` skill is not available, **stop**. Say
it is missing and that it installs from `.skill-lock.json` with
`npx skills experimental_install`. Do not improvise the interview and do not
write the plan without it.

Record where the answers came from in the document's opening line, the way the
existing plans do: `Decisions settled in grilling session, same day.`

## 4. Split into units

**Default to many small PRs.** Small merges land, get reviewed properly, and
revert cleanly. A large one sits open, collects conflicts, and gets skimmed.

Each unit must:

- Be describable in **one line**. If it needs two, it is two units.
- Merge on its own, leaving the product working — no half-states on the default
  branch. Put unfinished user-visible behaviour behind a flag rather than
  splitting it into a broken intermediate.
- Be revertible on its own.
- Hold one kind of change. Never combine a mechanical change (rename, move,
  dependency bump) with a behavioural one — the review cannot see the behaviour
  through the noise.

Order them:

1. Preparation first — dead code removal, extractions, config the rest depends
   on. These are cheap to review and shrink everything after them.
2. Then the easiest real case, as the template the rest follow.
3. Then the bulk, ideally in parallel.
4. Riskiest last, when the pattern is proven.

For each unit record its **dependency**: none (branches from the default
branch), or the unit it stacks on. Say which units can run in parallel — that is
what makes a long list cheap. Prefer units that branch from the default branch;
stack only where the dependency is real.

If the work genuinely cannot be split — one atomic migration — say so and say
why. That is a finding, not a failure.

## 5. Write the document

`~/notes/Plans/<Title Case Name>.md`. Match the house structure:

```markdown
# <Title>

Planned <D Mon YYYY>. <Where the decisions came from.>

<One or two lines: what this does, in plain terms.>

| Unit | Status |
| --- | --- |
| PR1 — <one-line name> | Not started |
| PR2 — <one-line name> | Not started |

## Current state

<What exists today, from step 2. Concrete: file paths, versions, current
behaviour. This is what stops the implementer rediscovering it.>

## Constraints and conventions

<Anything that binds every unit: decisions from the grilling, house patterns to
follow, things that must not break, the reference PR to copy.>

## PR1 — <name>

<One line: what this unit covers.>

<The how: approach, files, sequence.>

## PR2 — <name>

...
```

Status values, and the legend the write-back follows:

| Value | Meaning |
| --- | --- |
| `Not started` | No branch yet |
| `🔍 [#658](url)` | PR open, in review |
| `✅ [#657](url)` | Merged |

Two rules that matter more than they look:

- **Anything constraining more than one unit goes in Constraints and
  conventions, never inside a unit.** When a unit ships, its implementation
  notes are deleted from this document. A constraint parked under PR3 disappears
  with PR3 and the units after it lose it.
- **Write the how inside the unit.** That is what gets deleted later, by design
  — once the PR exists, the code is the truth and stale intent misleads.

Link related plans in Obsidian style: `[[MF Share Version Skew]]`.

## 6. Report

Show the user:

- The path written
- The unit list, one line each, with the dependency graph in a sentence — what
  is parallel, what stacks
- Anything you deliberately left out of scope
- What PR1 is, and that `implement-plan` builds it

Do not implement anything. Do not restate the plan you just wrote — the user
can read it.
