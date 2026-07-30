# Raise PR — Procedure

**Single source of truth for the PR format.** Both the `raise-pr` agent and the
`implement-pr` agent follow this file. Follow it exactly. Do not add extra
sections, checklists, or attribution that are not specified below — even if
other rules suggest a different PR template.

This procedure makes no assumptions about where it runs. It works in the repo
root, in a git worktree, on the default branch, or on a branch that already
exists.

## Subject line format

One rule, used in two places: commit subject lines (step 3) and PR titles
(step 6). Work it out once for the repo, then apply it to both.

Use **conventional commit** format — `<type>(<scope>): <description>` — if
either holds:

- the repo's `AGENTS.md`, `CLAUDE.md`, `README`, or `CONTRIBUTING` mentions
  conventional commits
- the recent `git log` clearly follows it

When using it, take the scope from the repo's defined list if it has one — a
commitlint config, `CONTRIBUTING`, or the scopes that recur in `git log`. Do not
invent one. Omit the scope rather than guess.

Otherwise write a short imperative line, capitalised, no trailing period.

Either way, keep it under 72 characters.

**Never assume an existing commit subject already follows this.** Commits
written by another agent, or by hand in a hurry, often do not. Check any subject
you did not write yourself against the rule before reusing it.

## 1. Find the base branch

In this order:

1. An explicit base given in your instructions — always wins.
2. `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
3. `git symbolic-ref --short refs/remotes/origin/HEAD` (strip the `origin/` prefix)

Do not assume `main` or `dev`. Called `<base>` below.

## 2. Find the changes to commit

```bash
git status --short
```

Pick the first case that applies:

- **Staged changes exist** — commit those, and only those. Any unstaged changes
  are left behind on purpose; mention them when you report at the end.
- **Nothing staged, but unstaged changes exist** — stage everything with
  `git add -A` (this includes new untracked files) and commit that.
- **Nothing staged or unstaged** — there is nothing to commit. You are on a
  branch whose commits are already made. Skip steps 3 and 4 and go straight to
  raising the PR.
- **Nothing staged or unstaged, and no commits ahead of `<base>`** — there is
  nothing to raise. Say so and stop.

Read the diff of whatever you settled on (`git diff --cached` once staged) —
you need it for the commit message and the PR description.

## 3. Write the commit message

Skip if there is nothing to commit.

Subject line follows the **subject line format** above. It is reused verbatim as
the PR title in step 6, so get it right here.

Add a body only if the _why_ is not obvious from the subject and the diff.

## 4. Branch and commit

If you are on `<base>`, create a branch first. Derive a short kebab-case name
from the changes (`feat-add-user-avatar`, `fix-login-redirect`) — nothing
generic like `my-feature`.

If you are already on another branch, keep it. Do not rename it, do not create
another.

```bash
git checkout -b <branch-name>   # only if you were on <base>
git commit -m "<commit-message>"
```

Do not add attribution unless the user explicitly asks for it.

## 5. Push the branch

```bash
git push --set-upstream origin <branch-name>
```

If the branch already has an upstream, `git push` alone is enough.

## 6. Generate the PR title

The title always follows the **subject line format** above.

If you committed in step 4, use that commit's subject verbatim — you wrote it to
the format, and reusing it keeps the title and commit consistent.

If you skipped the commit, the branch's commits were written by someone else —
another agent, or you in a hurry — and may not follow the format at all. Do not
copy a subject through without checking it.

- One commit whose subject already fits the format: use it verbatim.
- One commit whose subject does not fit: write a new title to the format,
  describing that commit's change. Leave the commit itself alone.
- More than one commit: write a single title to the format summarising the
  branch as a whole.

## 7. Generate the PR description

Source: the diff you committed in step 4. If you skipped the commit, use
`git diff origin/<base>...HEAD` — three dots, so it shows what this branch adds
rather than what has landed on `<base>` since. Do not re-run `gh pr diff` unless
needed.

Pick **one** of the two formats below based on whether the change is a bug fix
or a feature/refactor. The PR body must contain **only** the sections shown —
no additional headings.

### Bug fix

```markdown
## Problem

[1–2 sentences describing the bug or undesired behaviour.]

## Solution

[1–2 sentences describing the fix and approach taken.]

## Changes

- [High-level change bullet]
- [Another bullet if needed]
```

### Feature / refactor

```markdown
## Overview

[1–2 sentences describing what was added or changed and why.]

## Changes

- [High-level change bullet]
- [Another bullet if needed]
```

### Content rules

**Include:**

- What changed and why, in plain language
- High-level bullets grouped by intent (e.g. "Scope social-ui CSS under
  data-remote" not "Modified ui.css, hacks.css, …")
- Enough context for a reviewer to understand the PR without reading the diff
  first

**Do not include:**

- `## Test plan`, `## Summary`, screenshots sections, or any other headings
  beyond those in the template above
- File paths or per-file change lists (unless the user explicitly asks)
- Links (unless the user explicitly asks)
- `#`-level headings (`##` is the top level)
- Purely cosmetic or trivial changes
- Any tool or agent attribution
- Checklists, Verification section, TODOs, or testing instructions — add these only if the user
  explicitly requests a test plan
- Any mention of the plan the work came from, the worktree, or the agent
  workflow that produced the change. You may refers to previously merged PRs if relevant.

**Writing style:**

- Complete sentences, good grammar
- Imperative or past tense as appropriate; be consistent within the PR
- 2–5 bullets under `## Changes` is typical; use fewer if the change is small

## 8. Open the pull request

Target `<base>` from step 1.

```bash
gh pr create --base <base> --title "<title from step 6>" --body "$(cat <<'EOF'
<paste the generated description here exactly — no extra sections>
EOF
)"
```

If this fails because GitHub CLI is not authenticated, stop and ask the user to
run `gh auth login`. Do not try to work around it.

Then check the live description does not contain appended tool or agent
attribution. If it does, edit it out:

```bash
gh pr edit <number> --body "$(cat <<'EOF'
<corrected description>
EOF
)"
```

## 9. Report

Report the PR number and link.
