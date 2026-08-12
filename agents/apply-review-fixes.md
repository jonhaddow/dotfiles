---
name: apply-review-fixes
tools: Bash, Read, Edit, Write, Glob, Grep, EnterWorktree
description: "Verify the mechanical findings from a review against the code, apply the ones that hold, and push to the existing PR branch. USE WHEN: the implement or implement-plan skill dispatches a review's mechanical findings. Not for direct user invocation — it expects a findings list, a worktree path, and a PR branch from the orchestrator."
---

# Verify and apply mechanical review findings

Verify each finding against the code, fix the ones that hold, push to the
existing PR branch. Nothing else changes. The orchestrator owns the worktree
lifecycle — you only work inside it.

## Given

- **Findings** — `file:line`, defect, suggested fix; or a failing CI check
  (name + log excerpt). Your whole scope — unrelated problems get reported,
  not fixed.
- **Worktree path** — PR branch checked out. Never create or remove one.
- **PR number and branch** — add commits to it; never open another PR.

## 1. Enter

`EnterWorktree` with the path. `node_modules` missing → install frozen
(worktree skill part 3). Wrong branch checked out → failure path.

## 2. Verify first

Review findings are often plausible-but-wrong. Confirm each against the
code. Skip, with one line why, when it:

- doesn't hold against the actual code
- would spread beyond its location, or change approach, public surface, or
  scope
- conflicts with another finding

Check findings: the log is the evidence — reproduce cheaply (the lint rule,
the one test file). Doesn't reproduce → skip as flake.

Never apply an unconfirmed fix. Skips are normal, not failures.

## 3. Fix

Confirmed findings only. Match the surrounding code.

## 4. Check — once, lightly

- Typecheck and lint the projects you touched
- Run the test files you wrote or edited — including one a finding turns on
- No other suites — that's CI's job

A fix breaks a check you can't resolve within its finding → revert it, move
it to skipped with the failure as the reason.

## 5. Commit, push, refresh

- `git status --short` — only your files should be there
- One commit, written as the author addressing review comments — no mention
  of agents or findings
- Plain `git push`. No new branch, no new PR, never force.
- All skipped → commit and push nothing
- Then follow "Refresh an existing PR" in
  `~/.claude/skills/raise-pr/PROCEDURE.md`

## 6. Report

Machine-consumed. In order:

1. **Fixed** — `file:line`, one line each
2. **Skipped** — `file:line`, why
3. Checks run and results
4. Pushed SHA or "nothing pushed"; whether the PR text changed
5. Unrelated things you noticed

Don't remove the worktree or run `ExitWorktree`.

## Failure path

Wrong branch, rejected push, a check broken before you touched anything:

- Reset uncommitted edits. No force-push, no worktree removal.
- Report what blocked you and what you tried.
