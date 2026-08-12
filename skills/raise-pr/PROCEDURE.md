# Raise PR — Procedure

Single source of truth for the PR format, followed by the `raise-pr` and
`implement-pr` agents. Follow it exactly — no extra sections, checklists, or
attribution, even if other rules in context suggest a PR template.

## Subject line format

One rule for the commit subject and the PR title. Work it out once:

- Conventional commits (`<type>(<scope>): <description>`) if the repo's docs
  or recent `git log` clearly use them. Scope from the repo's own list;
  omit rather than invent.
- Otherwise: short imperative line, capitalised, no trailing period.
- Under 72 characters either way.
- Never assume an existing subject already complies — check before reusing.

## 1. Base branch and changes

Base branch, in order — never assume `main` or `dev`:

1. An explicit base in your instructions
2. `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
3. `git symbolic-ref --short refs/remotes/origin/HEAD`, `origin/` stripped

Then `git status --short`, first case that applies:

- **Staged changes** → commit those only; report anything left unstaged
- **Only unstaged** → `git add -A`, commit it all
- **Clean, commits ahead of base** → skip step 2's commit
- **Clean, nothing ahead** → nothing to raise; say so and stop

Read the diff (`git diff --cached`) — the message and description come from
it.

## 2. Branch, commit, push

- On `<base>` → create a branch: short kebab-case from the changes
  (`fix-login-redirect`). On any other branch → keep it.
- Commit with a subject in the format above — it becomes the PR title. Body
  only if the *why* isn't obvious. No attribution.
- `git push --set-upstream origin <branch>` (plain `git push` if upstream
  exists).

## 3. PR title

Always the subject format:

- You committed → reuse that subject verbatim
- One existing commit that fits → use it verbatim
- One that doesn't fit → write a fresh title; leave the commit alone
- Several commits → one title for the branch as a whole

## 4. PR description

Source: the committed diff, or `git diff origin/<base>...HEAD` (three dots).

Only these `##` sections:

- `## Problem` + `## Solution` (bug fix) or `## Overview` (anything else) —
  1–2 sentences each
- `## Changes` — 2–5 bullets grouped by intent, not per-file
- `## Screenshots` — only for visible UI changes, only from images you
  actually captured (before/after when modifying existing UI). No images →
  omit the section and flag it in your report; never describe an image you
  didn't take.

No test plans, checklists, links, file paths, attribution, or any mention of
a plan, worktree, or agent. Complete sentences, consistent tense.

## 5. Open and report

```bash
gh pr create --base <base> --title "<title>" --body "$(cat <<'EOF'
<description — nothing else>
EOF
)"
```

- `--draft` only when your instructions say so — a user asking for a PR
  wants it open.
- `gh` not authenticated → stop and ask for `gh auth login`.
- Check the live description for appended tool attribution; remove with
  `gh pr edit <number> --body`.
- Report the PR number and link.

## 6. Refresh an existing PR

After later pushes: re-read `git diff origin/<base>...HEAD` and fix only
what the new commits made wrong — usually a `## Changes` bullet; the title
only if the PR now does something different. Leave true text alone. Apply
with `gh pr edit <number> --title/--body`.
