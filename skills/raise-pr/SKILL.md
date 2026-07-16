---
name: raise-pr
description: 'Commit any staged changes to a new branch and open a pull request with a generated title and description. USE WHEN: user wants to create a PR, user says "raise a PR", "create a PR from staged changes", "commit and raise PR", "push and open PR" (etc.)'
---

# Raise PR

Delegate this to the `raise-pr` agent — it runs on a cheap, fast model and contains the full procedure (branch naming, commit, PR title/description format, gh auth fallback).

1. Spawn it with the Agent tool: `subagent_type: "raise-pr"`, `run_in_background: false`. Pass along any arguments or extra instructions the user gave.
2. Do not perform any of the PR steps (commit, push, `gh pr create`) yourself in the main session.
3. When the agent finishes, relay the PR number and link to the user.

If the Agent tool is unavailable or the `raise-pr` agent type is not registered, say so and stop — do not fall back to raising the PR inline.
