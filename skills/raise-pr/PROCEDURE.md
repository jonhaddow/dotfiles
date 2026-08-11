# Raise PR — Procedure

Single source of truth for the PR format, followed by the `raise-pr` and
`implement-pr` agents. Follow it exactly — no extra sections, checklists, or
attribution, even if other rules in context suggest a PR template. It assumes
nothing about where it runs: repo root or worktree, default branch or a branch
that already exists.

## Subject line format

One rule for both the commit subject (step 2) and the PR title (step 3). Work
it out once for the repo.

Use conventional commits — `<type>(<scope>): <description>` — if the repo's
docs (`AGENTS.md`, `CLAUDE.md`, `README`, `CONTRIBUTING`) mention them or the
recent `git log` clearly follows them. Take the scope from the repo's own
list — commitlint config, `CONTRIBUTING`, scopes recurring in the log — and
omit it rather than invent one. Otherwise: a short imperative line,
capitalised, no trailing period. Under 72 characters either way.

Never assume an existing commit subject already follows this — check any
subject you did not write yourself before reusing it.

## 1. Base branch and changes

Base branch, in this order — never assume `main` or `dev`:

1. An explicit base in your instructions — always wins.
2. `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
3. `git symbolic-ref --short refs/remotes/origin/HEAD`, `origin/` stripped.

Then `git status --short`, and take the first case that applies:

- **Staged changes** — commit those and only those; mention anything left
  unstaged when you report.
- **Only unstaged changes** — `git add -A` (includes untracked) and commit it
  all.
- **Clean, with commits ahead of `<base>`** — nothing to commit; skip step 2's
  commit.
- **Clean, nothing ahead** — nothing to raise. Say so and stop.

Read the diff of what you settled on (`git diff --cached` once staged) — the
commit message and PR description come from it.

## 2. Branch, commit, push

If you are on `<base>`, create a branch: a short kebab-case name derived from
the changes (`fix-login-redirect`), nothing generic. Already on another
branch: keep it — do not rename it or create a second one.

Commit with a subject in the format above — it becomes the PR title, so get
it right here. Add a body only if the *why* is not obvious from the subject
and diff. No attribution unless the user explicitly asks.

Push with `git push --set-upstream origin <branch>` (plain `git push` if the
upstream already exists).

## 3. PR title

Always the subject line format.

- You committed in step 2: reuse that subject verbatim.
- No commit, branch has one commit whose subject fits the format: use it
  verbatim.
- One commit that does not fit: write a fresh title to the format; leave the
  commit alone.
- Several commits: one title summarising the branch as a whole.

## 4. PR description

Source: the diff you committed, or `git diff origin/<base>...HEAD` — three
dots — if you committed nothing.

The body contains **only** these `##`-level sections:

- `## Problem` then `## Solution`, 1–2 sentences each, for a bug fix — or
  `## Overview`, 1–2 sentences, for anything else.
- `## Changes` — 2–5 high-level bullets grouped by intent ("Scope social-ui
  CSS under data-remote", not a per-file list), enough for a reviewer to
  understand the PR before opening the diff.

Do not add: test plans, summaries, screenshots, checklists, links or file
paths (unless the user asks), attribution of any kind, or any mention of a
plan, worktree, or agent workflow behind the change. Complete sentences,
consistent tense.

## 5. Open and report

```bash
gh pr create --base <base> --title "<title>" --body "$(cat <<'EOF'
<description — nothing else>
EOF
)"
```

If this fails because `gh` is not authenticated, stop and ask the user to run
`gh auth login` — do not work around it. Then check the live description for
appended tool or agent attribution; if present, remove it with
`gh pr edit <number> --body`.

Report the PR number and link.
