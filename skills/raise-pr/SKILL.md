---
name: raise-pr
description: 'Commit any staged changes to a new branch and open a pull request with a generated title and description. USE WHEN: user wants to create a PR, user says "raise a PR", "create a PR from staged changes", "commit and raise PR", "push and open PR" (etc.)'
---

# Raise PR

The format lives in [PROCEDURE.md](PROCEDURE.md) — the single source of
truth, also followed by the `implement-pr` agent.

## Do it yourself when this session made the change

You already know the *why*, not just the diff. Follow PROCEDURE.md exactly —
over any habits the session has accumulated (test-plan sections, rewritten
titles, attribution).

## Delegate when it didn't

Change made elsewhere (fresh session, someone else's branch) → hand it to
the `raise-pr` agent so the diff never enters this context:

- **No preparation.** No `git diff`/`log`/`status`, no drafted branch name,
  title, or description — the agent derives all of it.
- Spawn `raise-pr`, foreground. Prompt: only the user's own instructions,
  plus anything unrecoverable from the diff (non-default base, the why, the
  Jira key).
- Relay the PR number and link.

Agent tool unavailable → do it yourself. Agent can't read PROCEDURE.md →
re-spawn with its contents pasted in.
