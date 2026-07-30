---
name: implement
description: 'Implement one unit of work from a plan in an isolated worktree, raise the PR, tear the worktree down, and print a review. USE WHEN: user says "get a subagent to implement PR1", "implement the next PR from the plan", "implement <unit> from <plan>", or asks for a scoped piece of a plan to be built and raised as a PR.'
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
repo, and never let one reach a commit message or PR description. The only edit
you ever make to a plan is the status write-back in step 7.

If the user names a plan, use it. If they refer to "the plan" and only one file
in that directory plausibly covers the current repo or task, use it and say
which. If several could, ask.

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

## 3. Preflight

Check the worktree directory will not pollute the repo:

```bash
git check-ignore -q .claude/worktrees && echo ignored || echo NOT-ignored
```

If not ignored, add it to `.git/info/exclude` before going further. Otherwise
the worktree shows up as untracked in the main checkout and can be swept into a
`git add -A`.

Then look for orphans from earlier runs:

```bash
git worktree list
```

Anything under `.claude/worktrees/` that this run did not create is left over.
Mention it but do not remove it without asking. It may be someone's parked work.

## 4. Create the worktree

You create it, so you can always clean it up — even if the agent never reports
back. Derive a short kebab-case branch name from the scope
(`refactor-drop-standalone-header`), following whatever naming the plan or the
repo's recent branches use.

```bash
repo_root="$(git rev-parse --show-toplevel)"
git -C "$repo_root" fetch origin
git -C "$repo_root" worktree add ".claude/worktrees/<branch>" -b "<branch>" "<base>"
```

Use the remote ref for `<base>` (`origin/dev`, or the open branch this stacks
on). A stale local branch silently branches from the wrong commit.

**Record the absolute worktree path now**, before dispatching. It is what makes
cleanup possible if the agent dies mid-run.

Then copy across anything git ignores that the worktree still needs. If the repo
root has a `.worktreeinclude`, copy each path it lists. Otherwise check for
`.env` and `.env.local` and copy them if present. `git worktree add` copies no
ignored files, so without this the worktree has no local environment.

If creation fails — the branch already exists, the base is unknown, the repo is
mid-rebase — stop here and say so. Do not dispatch the agent.

## 5. Dispatch the implementer

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
step 4 regardless of what the agent returned. Leave the worktree in place.

## 6. Remove the worktree

As soon as the PR is raised. Nothing later in this flow needs it — the review
reads from GitHub, and no code changes after this point.

```bash
git -C <worktree-path> status --porcelain   # must be empty
git -C <worktree-path> log --oneline @{u}.. # must be empty — everything pushed
git worktree remove --force <worktree-path>
```

Check both before removing. `--force` is needed because the worktree holds an
ignored `node_modules`, but it will also discard real work — the two checks
above are what makes it safe. If either is non-empty, stop and tell the user
rather than forcing it.

This deletes `node_modules` with it, which is the point. The local branch
survives, so the user can check it out in their IDE straight away.

## 7. Write the PR back to the plan

Do this as soon as the PR exists — the number will not change later.

Look for a status or tracking table in the plan, the kind that lists units
against their state. If there is one, update the row for the unit you just
implemented: mark it done or in progress as appropriate, and record the PR
number the same way the existing rows record theirs.

Rules:

- **Only the row for this unit.** Do not touch other rows, prose, or headings.
- **Match the existing convention.** If done rows read `✅ #601`, write
  `✅ #607`. Do not introduce a new format or a link style the table does not
  already use.
- **If there is no status table, do nothing.** Do not create one. A plan without
  tracking is a plan the user reads top to bottom; adding scaffolding to it is
  not your call.
- **Nothing else changes.** No reformatting, no fixing typos you noticed, no
  ticking checklist items elsewhere in the document.

If the write fails, do not retry in a loop. Carry on and tell the user at the
end that the plan was not updated.

## 8. Review and print the findings

Invoke the `pr-review` skill with the PR number. It reads the diff from GitHub,
so it needs no working tree.

Show the merged review here, in chat. **Do not post it to the PR.** Present
every finding — defects, quality, design — as a numbered list, most serious
first, each one a line or two: what is wrong, where, and the suggested fix. If
the review is clean, say so.

Then stop. **Do not fix anything.** The user reviews the PR themselves and
decides what is worth acting on; review agents produce plausible-but-wrong
findings and cannot see the reasoning behind the change.

## 9. Report

Give the user:

- PR number and link
- One line on what was implemented
- Anything the agent flagged as out of scope or unresolved
- The branch name, ready to check out
- Whether the plan's status table was updated, and say so explicitly if it was
  not — either because the plan has no table, or because the write failed

Then you are done. The run ends here: the PR is up, the worktree is gone, and
nothing further touches the code. CI, the findings above, and the user's own
review are all theirs to act on, in a separate session.

Do not restate the plan or recap the process.
