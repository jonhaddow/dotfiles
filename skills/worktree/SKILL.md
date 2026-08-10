---
name: worktree
description: 'Do a piece of work in a throwaway git worktree and tear it down afterwards, so the main checkout is never touched and the branch is left ready to check out. USE WHEN: starting any change that will become its own PR, work is dispatched to a subagent, the user says "in a worktree", "do not touch my checkout", or another skill (implement, implement-plan) points here for the worktree lifecycle.'
---

# Worktree lifecycle

Any change that will become its own PR belongs in a throwaway worktree, not in
the user's checkout. The checkout stays clean and usable while the work runs, a
subagent cannot damage it, the build artifacts die with the worktree, and the
branch survives for the user to check out in their IDE.

**One session owns the lifecycle from end to end**: whoever creates the worktree
removes it. If the work is dispatched to a subagent, the orchestrator owns it —
it creates the worktree, passes the absolute path, and removes it when the agent
reports back. The agent never creates or removes one.

Skip the worktree only when the work is not a change to the repo at all —
reading, reviewing, answering a question — or when the user asks to work in
their checkout directly.

## 1. Preflight

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

## 2. Create

Derive a short kebab-case branch name from the scope
(`refactor-drop-standalone-header`, `fix-empty-cart-total`), following whatever
naming the repo's recent branches use — or the plan, if there is one.

```bash
repo_root="$(git rev-parse --show-toplevel)"
git -C "$repo_root" fetch origin
git -C "$repo_root" worktree add ".claude/worktrees/<branch>" -b "<branch>" "<base>"
```

Use the remote ref for `<base>` — `origin/<default branch>`, or the open branch
this stacks on. A stale local branch silently branches from the wrong commit.

**Record the absolute worktree path now**, before any work starts. It is what
makes cleanup possible if the work is dispatched and the agent dies mid-run.

Then copy across anything git ignores that the worktree still needs. If the repo
root has a `.worktreeinclude`, copy each path it lists. Otherwise check for
`.env` and `.env.local` and copy them if present. `git worktree add` copies no
ignored files, so without this the worktree has no local environment.

If creation fails — the branch already exists, the base is unknown, the repo is
mid-rebase — stop there and say so. Do not start the work.

## 3. Work in it

Enter the worktree with `EnterWorktree`, or dispatch a subagent and pass it the
absolute path.

**Every edit happens inside the worktree.** If a path you are about to write to
does not start with the worktree path, stop. The branch is already created and
checked out — do not create another and do not rename it.

The worktree has no `node_modules`. Install before running anything, using the
lockfile's package manager and its frozen variant (`bun install
--frozen-lockfile`, `npm ci`). That keeps a spurious lockfile diff out of the
PR. If the work genuinely changes dependencies, install frozen first, then make
the change and re-install unfrozen so the lockfile updates on purpose.

## 4. Remove

As soon as the PR is raised. Nothing after that point needs the worktree — a
review reads the diff from GitHub, and no code changes once the PR is up.

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

## If the run fails

If the work is blocked, or a dispatched agent reports a failure or dies without
reporting, **leave the worktree in place**. Give the user the path — you
recorded it in part 2, so you have it whatever the agent returned — and let them
look at the work themselves.
