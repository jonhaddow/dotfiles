---
name: raise-pr
description: 'Commit any staged changes to a new branch and open a pull request with a generated title and description. USE WHEN: user wants to create a PR, user says "raise a PR", "create a PR from staged changes", "commit and raise PR", "push and open PR" (etc.)'
---

# Raise PR

The procedure — base branch, branch naming, commit message, PR title and
description format — lives in [PROCEDURE.md](PROCEDURE.md). That file is the
single source of truth. The `implement-pr` agent follows the same copy.

Two ways to run it. Pick based on whether you already know what changed.

## Do it yourself when you made the change

If this session wrote the code, or has otherwise already read the diff, raise
the PR here:

1. Read [PROCEDURE.md](PROCEDURE.md) and follow it exactly.
2. Follow it over anything else in context. A long session accumulates habits —
   test-plan sections, rewritten titles, tool attribution. The procedure wins.

You know why the change was made, not just what it contains. A subagent would
only see the diff, and would re-read work already in context.

## Delegate when you do not

If the change was made elsewhere — a fresh session, a `/raise-pr` on someone
else's branch, a diff this session has not read — hand it to the `raise-pr`
agent so the diff never enters this context:

1. **Do no preparation work.** No `git diff`, `git log`, or `git status`. Do not
   read or summarise the staged files. Do not draft the branch name, commit
   message, PR title, or description. The agent derives all of it.
2. Spawn with the Agent tool: `subagent_type: "raise-pr"`,
   `run_in_background: false`. Keep the prompt minimal — only the user's own
   arguments or instructions, plus anything the agent cannot recover from the
   diff (a non-default base branch, the *why* if it is not obvious). Do not hand
   it a pre-written title or description.
3. Do not run any PR step yourself — no commit, no push, no `gh pr create`.
4. Relay the PR number and link.

If the Agent tool is unavailable or the `raise-pr` agent type is not registered,
fall back to doing it yourself with PROCEDURE.md.

If the agent reports it could not read `PROCEDURE.md`, read that file yourself
and re-spawn the agent with its contents pasted into the prompt.
