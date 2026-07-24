---
name: raise-pr
model: haiku
tools: Bash, Read
description: 'Commit any staged changes to a new branch and open a pull request with a generated title and description. USE WHEN: user wants to create a PR, user says "raise a PR", "create a PR from staged changes", "commit and raise PR", "push and open PR" (etc.)'
---

# Raise PR from Staged Changes

If there are staged changes, commit them to a new branch, and raise a PR.
If there are no staged changes, raise a PR with the existing branch.

When raising a PR, generate a PR title, generate a PR description, and open the pull request.

**This skill defines the complete PR format.** When invoked (e.g. via `/raise-pr`), follow it exactly. Do not add extra sections, checklists, or attribution that are not specified below — even if other rules suggest a different PR template.

## Procedure

### 1. Check staged changes

Run `git diff --cached --stat` to confirm there are staged changes.

If you need a summary of the changes to help name the branch and generate a title/description, run `git diff --cached`.

If there are no staged changes, skip steps 3–4 and raise the PR from the current branch using `git diff origin/dev...HEAD` (or the repo's default branch) as the source for the description.

### 2. Determine branch name and commit message

Derive a short, kebab-case branch name from the nature of the changes (e.g. `feat-add-user-avatar`, `fix-login-redirect`). Avoid generic names like `my-feature`.

Generate a commit message for the staged changes, and decide the message style here — its subject line is reused verbatim as the PR title (step 5), so it must be correct. Use the **conventional commit** format (`<type>(<scope>): <description>`) if the repo's `AGENTS.md`, `CLAUDE.md`, `README`, or `CONTRIBUTING` mentions conventional commits, or the recent `git log` clearly follows it; otherwise write a short imperative message (capitalised, no trailing period). Keep the subject line under 72 characters.

### 3. Create the branch and commit

```bash
git checkout -b <branch-name>
git commit -m "<conventional-commit-message>"
```

Do not add `Made-with: Cursor`, `Co-authored-by: Cursor`, or any other Cursor attribution to commit messages unless the user explicitly asks for it.

### 4. Push the branch

```bash
git push --set-upstream origin <branch-name>
```

### 5. Generate the PR title

The PR title **is the subject line (first line) of the commit message from step 2** — use it verbatim. Do not re-decide the format or rewrite it: reusing the commit subject keeps the title and commit consistent and satisfies any PR-title lint the repo enforces (the format decision was already made in step 2).

If there were no staged changes (no new commit was created), derive the title from the branch's existing commits: use the sole commit's subject if there is exactly one, otherwise write a single summary line in the **same style the repo's recent `git log` uses** (conventional `<type>(<scope>): <description>` if the log follows it, else a short imperative line), under 72 characters.

### 6. Generate the PR description

Use the staged diff (or branch diff if no staged changes) as the source. Do not re-run `gh pr diff` unless needed.

Pick **one** of the two formats below based on whether the change is a bug fix or a feature/refactor. The PR body must contain **only** the sections shown — no additional headings.

#### Bug fix

```markdown
## Problem

[1–2 sentences describing the bug or undesired behaviour.]

## Solution

[1–2 sentences describing the fix and approach taken.]

## Changes

- [High-level change bullet]
- [Another bullet if needed]
```

#### Feature / refactor

```markdown
## Overview

[1–2 sentences describing what was added or changed and why.]

## Changes

- [High-level change bullet]
- [Another bullet if needed]
```

#### Content rules

**Include:**

- What changed and why, in plain language
- High-level bullets grouped by intent (e.g. "Scope social-ui CSS under data-remote" not "Modified ui.css, hacks.css, …")
- Enough context for a reviewer to understand the PR without reading the diff first

**Do not include:**

- `## Test plan`, `## Summary`, screenshots sections, or any other headings beyond those in the template above
- File paths or per-file change lists (unless the user explicitly asks)
- Links (unless the user explicitly asks)
- `#`-level headings (`##` is the top level)
- Purely cosmetic or trivial changes
- "Made with Cursor", "Co-authored-by: Cursor", or any Cursor/tool attribution
- Checklists, TODOs, or testing instructions — add these only if the user explicitly requests a test plan

**Writing style:**

- Complete sentences, good grammar
- Imperative or past tense as appropriate; be consistent within the PR
- 2–5 bullets under `## Changes` is typical; use fewer if the change is small

### 7. Open the pull request

Target the repository's default branch (`dev`) unless the user specifies otherwise.

First check whether GitHub CLI is already authenticated:

```bash
gh auth status
```

If that succeeds, create the PR normally:

```bash
gh pr create --base dev --title "<commit-subject-title>" --body "$(cat <<'EOF'
<paste the generated description here exactly — no extra sections>
EOF
)"
```

#### Git credential helper fallback

If `git push` succeeds but `gh auth status` fails, Git is authenticated through a credential helper that GitHub CLI is not using. Do not stop and ask the user to authenticate again. Read the existing credential into shell variables, pass it to `gh` only for the current command, and never print or persist it:

```bash
credentials="$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill)"
token="$(printf '%s\n' "$credentials" | awk -F= '$1 == "password" { sub(/^password=/, ""); print; exit }')"

if [ -z "$token" ]; then
  unset credentials token
  echo "Git's credential helper did not return a GitHub token." >&2
  exit 1
fi

GH_TOKEN="$token" gh pr create --base dev --title "<commit-subject-title>" --body "$(cat <<'EOF'
<paste the generated description here exactly — no extra sections>
EOF
)"
```

This fallback uses `git credential fill` to invoke the repository's configured credential helper. `GH_TOKEN="$token"` applies only to that `gh` process; it does not modify GitHub CLI configuration. Never echo the credential variables, include the token directly in command arguments, write it to a file, or pipe it into `gh auth login`.

After creating the PR, verify the live description on GitHub does not contain appended attribution (e.g. "Made with Cursor"). If it does, edit the PR to remove it:

```bash
gh pr edit <number> --body "$(cat <<'EOF'
<corrected description>
EOF
)"
```

When the credential-helper fallback was required, use the same per-command token for verification or editing:

```bash
GH_TOKEN="$token" gh pr view <number-or-url> --json number,url,title,baseRefName,headRefName,body
GH_TOKEN="$token" gh pr edit <number-or-url> --body "$(cat <<'EOF'
<corrected description>
EOF
)"
unset credentials token
```

If the credential helper does not return a token, then ask the user to run `gh auth login`.

Report the PR number and link to the user.
