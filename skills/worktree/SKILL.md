---
name: worktree
description: 'Do a piece of work in a throwaway git worktree and tear it down afterwards, so the main checkout is never touched and the branch is left ready to check out. USE WHEN: starting any change that will become its own PR, work is dispatched to a subagent, the user says "in a worktree", "do not touch my checkout", or another skill (implement, implement-plan) points here for the worktree lifecycle.'
---

# Worktree lifecycle

A change that becomes its own PR gets a throwaway worktree: the checkout
stays usable, a subagent can't damage it, build artifacts die with it, and
the branch survives for the IDE.

**Whoever creates the worktree removes it.** A dispatched agent never does
either — the orchestrator passes it the absolute path.

Skip the worktree when:

- the work changes nothing (reading, reviewing, answering)
- the user asks to work in the checkout

**Never work in the checkout just because it sits on the target branch.** The
user switches branches to review other work. The working tree changes under
you and the run breaks. Take a detached worktree instead — part 2.

## 1. Preflight

Worktrees live **outside the repo**, at `~/.claude/worktrees/<repo>/<branch>`.
Inside the repo they land in the file watchers — Vite full-reloads, the Nx
daemon rebuilds, the IDE indexes them — and none of that reads `.gitignore`.

```bash
repo_root="$(git rev-parse --show-toplevel)"
wt_root="$HOME/.claude/worktrees/$(basename "$repo_root")"
mkdir -p "$wt_root"
```

`git worktree list` — anything under `$wt_root` this run didn't create is an
orphan. Mention it; don't remove it without asking.

## 2. Create

Branch name: short kebab-case from the scope (`fix-empty-cart-total`),
matching the repo's recent naming.

```bash
git -C "$repo_root" fetch origin
git -C "$repo_root" worktree add "$wt_root/<branch>" -b "<branch>" "<base>"
```

- `<base>` is the **remote** ref (`origin/main`) — a stale local branch
  silently branches from the wrong commit.
- **Record the absolute path now** — it's what makes cleanup possible if a
  dispatched agent dies.
- Copy ignored files the worktree needs: paths in `.worktreeinclude` if the
  repo has one, else `.env` / `.env.local` if present.
- Creation fails → stop; don't start the work.

### The branch is already checked out

`git worktree add` refuses a branch another worktree holds. `--detach` does
not, because it takes the commit and not the branch:

```bash
git -C "$repo_root" worktree add --detach "$wt_root/<branch>" "<branch>"
```

Commit on the detached HEAD, then push to the branch by name:

```bash
git -C <worktree-path> push origin HEAD:"<branch>"
```

The user's checkout never moves, and they stay free to switch branches. They
get the work with `git pull`.

## 3. Work in it

Work by absolute path — `git -C <worktree-path>`, and absolute paths for
Read/Edit/Write. **Don't use `EnterWorktree`**: it only accepts worktrees
under the repo's own `.claude/worktrees/`, which these are not. Pass the
absolute path to a dispatched agent.

- Every edit inside the worktree — a path outside it means stop.
- The branch exists and is checked out: don't create another, don't rename.
- Install frozen from the lockfile (`npm ci`, `bun install
  --frozen-lockfile`) so no spurious lockfile diff reaches the PR. Real
  dependency change → install frozen first, change, re-install unfrozen.

## 4. Remove

As soon as nothing left in the run touches the code — after the PR is up,
or in the implement flow after the fix pass pushes. Reviews read the diff
from GitHub; they never need the worktree.

```bash
git -C <worktree-path> status --porcelain   # must be empty
git -C <worktree-path> log --oneline @{u}.. # must be empty — everything pushed
# detached HEAD has no upstream — use this instead:
git -C <worktree-path> log --oneline origin/"<branch>"..HEAD
git worktree remove --force <worktree-path>
```

Both checks first — `--force` (needed for `node_modules`) would discard real
work. Either non-empty → stop and tell the user. The branch survives for the
IDE.

## 5. Reacquire an existing branch

For a later fix pass after the worktree is gone:

```bash
git fetch origin
git worktree add "$wt_root/<branch>" <branch>
git -C "$wt_root/<branch>" merge --ff-only origin/<branch>
```

The checkout holds the branch → add `--detach` and push per part 2.

Won't fast-forward → stop and ask; someone moved the branch. Remove per
part 4 when done.

## If the run fails

Leave the worktree in place and give the user the path — you recorded it in
part 2, whatever the agent returned.
