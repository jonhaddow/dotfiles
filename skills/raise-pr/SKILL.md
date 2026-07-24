---
name: raise-pr
description: 'Commit any staged changes to a new branch and open a pull request with a generated title and description. USE WHEN: user wants to create a PR, user says "raise a PR", "create a PR from staged changes", "commit and raise PR", "push and open PR" (etc.)'
---

# Raise PR

Delegate this to the `raise-pr` agent — it runs on a cheap, fast model and contains the full procedure (branch naming, commit, PR title/description format, gh auth fallback).

1. **Do no preparation work yourself.** Do not run `git diff`, `git log`, or `git status`, do not read or summarise the staged files, and do not draft the branch name, commit message, PR title, or PR description. The agent derives all of that from the staged diff itself — doing it in the main session wastes tokens and duplicates the agent's job.
2. Spawn the agent with the Agent tool: `subagent_type: "raise-pr"`, `run_in_background: false`. Keep the prompt minimal: pass only (a) any arguments or explicit instructions the user gave, and (b) context the agent cannot recover from the diff alone — the _why_ behind the change if it is not obvious, or a non-default base branch. Do not hand it a pre-written title or description; let it write them.
3. Do not perform any of the PR steps (commit, push, `gh pr create`) yourself in the main session.
4. When the agent finishes, relay the PR number and link to the user.

If the Agent tool is unavailable or the `raise-pr` agent type is not registered, say so and stop — do not fall back to raising the PR inline.
