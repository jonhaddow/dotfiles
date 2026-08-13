---
name: plan-housekeeping
description: 'Reconcile a plan status table against the real state of its PRs and Jira tickets, and sweep the worktrees dead runs left behind. USE WHEN: an implementation session opens, the user says "housekeeping", "is the plan up to date", "check the state of the open PRs", "any stale worktrees", or implement-plan starts a run.'
---

# Plan housekeeping

Units merge in the days between sessions and nothing writes it back. A stale
row sends the next unit at the wrong base branch, leaves a ticket sitting in
review after the work shipped, and a dead run leaves its worktree on disk
holding a branch.

Read and correct. Never implement, never review, never touch code.

## 1. Pick the plans

A plan in hand → that one. Nothing named → every file under

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Claude/Plans
```

that still holds an open row. Write only inside `Claude/`.

## 2. Read the real state

Each row's PR link carries the repo and the number:

```bash
gh pr view <n> --repo <owner/repo> --json state,isDraft,mergedAt
acli jira workitem view ABC-124 --fields status --json
```

No `acli`, or not authenticated → do the table half and skip the tickets,
said once. A PR you cannot read → leave its row alone.

## 3. Correct the table

The PR is the truth. Only these moves:

| Row | PR | Do |
| --- | --- | --- |
| 🔍 | merged | → `✅`, ticket → done |
| 🔍 | open, ready | nothing |
| 🔍 | open, draft | ticket belongs at in-progress, not review |
| 🔍 | closed unmerged | nothing — report it; a close is a decision |
| ✅ | open | nothing — report it; someone marked it early |
| `Not started` | — | nothing. Don't go hunting for a branch |

Never move a row backwards, never add a row, never touch a unit's prose —
except that a row now at `✅` whose implementation notes are still there gets
them removed, by `implement-plan`'s step 4.

## 4. Move the tickets

Only where the table above says, and only through the `jira` skill.
Statuses, and what to do with a rejected transition, are `implement-plan`'s
step 5. Say which tickets will move before the first one moves.

## 5. Sweep the worktrees

A run that died left its worktree on disk, holding a branch and a
`node_modules`. This session created none, so everything under
`.claude/worktrees/` is a leftover:

```bash
git worktree list
```

For each, in the checkout you are in — no repo in hand, a vault-wide sweep,
skip this step:

```bash
git -C <path> status --porcelain      # uncommitted work
git -C <path> log --oneline @{u}..    # unpushed commits
```

- Both empty, and its PR merged or its branch gone from the remote → offer
  to remove it, by the `worktree` skill's part 4. One yes covers the batch.
- Either one non-empty → report the path and what is in it. Never remove it,
  and never offer to. It holds the only copy.
- Branch still open with a live PR → leave it, silently. A stacked unit is
  probably still building on it.

## 6. Report

- One line per row changed: unit, old → new, and the ticket move
- One line per drift left alone, with the reason
- The worktrees removed, and any held back with what is in them
- Nothing to do → one line saying the plan is current

Never dump the table back at the user.
