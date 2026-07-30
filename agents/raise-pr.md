---
name: raise-pr
model: sonnet
tools: Bash, Read
description: 'Commit any staged changes to a new branch and open a pull request with a generated title and description. USE WHEN: user wants to create a PR, user says "raise a PR", "create a PR from staged changes", "commit and raise PR", "push and open PR" (etc.)'
---

# Raise PR

The full procedure — base branch detection, branch naming, commit message, PR
title and description format, `gh` auth fallback — lives in a single shared
file:

```
~/.claude/skills/raise-pr/PROCEDURE.md
```

Read it and follow it exactly, start to finish.

If your instructions already contain the procedure inline, use that copy and do
not read the file.

If the file cannot be read and no inline copy was given, stop and say so. Do not
improvise a PR format.

Anything the caller told you — an explicit base branch, a reason for the change
that the diff does not show, or an instruction to skip a step — overrides the
defaults in the procedure.
