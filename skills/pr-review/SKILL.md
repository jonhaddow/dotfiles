---
name: pr-review
description: 'Full review of the current branch or a PR: triages the diff, checks first whether it should be split, then picks the right review agent per axis (defects: quick/deep, tests: on/skip, quality: light/strict, design: on/skip), runs them in parallel, and merges the results with a disposition — mechanical or judgement — on every finding. USE WHEN: user says "review this PR", "review my branch", "review this before I raise a PR", or wants a review without choosing agents manually.'
---

# PR Review Router

A shape gate, then four axes — defects, tests, quality, design — each
delegated to an agent. You triage, dispatch, merge. Don't review the code
yourself.

## 1. Triage

From the shape, not the contents — **don't read the full diff**; every agent
reads it in its own context.

- PR given: `gh pr view <n>` for intent, `gh pr diff <n> --stat`
- Also collect existing review comments:
  `gh api repos/{owner}/{repo}/pulls/<n>/comments --paginate` and
  `gh pr view <n> --json reviews`. Keep `file:line`, body, author (null
  `position` = the code moved). Don't assess them here. Don't wait for a
  review that hasn't landed.
- Branch: base from `gh repo view --json defaultBranchRef -q
  .defaultBranchRef.name` (fallback `git symbolic-ref --short
  refs/remotes/origin/HEAD`) — never assume `main` — then
  `git diff --stat $(git merge-base HEAD origin/<base>)...HEAD` and `git log`

Open individual files only if routing is genuinely undecided.

## 2. Pick a level per axis

- **Scope**: `review-scope` unless the diff is small and obviously one
  concern. Cheap, and the finding is worthless once the PR is open.
- **Defects**: `deep` for auth, payments, persistence/migrations,
  concurrency, public API, feature flags, many call sites, or ~400+
  non-test lines. Else `quick`.
- **Tests**: `review-tests` if the diff touches any test file. Else skip —
  whether a change *needed* a test belongs to the defect agents.
- **Quality**: `strict` for new modules/abstractions, a file grown
  substantially or past ~1000 lines, or new branching in shared code. Else
  `light`. Skip for docs/config-only or <20 lines.
- **Design**: `review-design` if the diff touches UI code. Else skip.

Borderline → escalate: a wasted deep review costs minutes, a missed one an
incident.

## 3. Shape gate

`review-scope` first, **alone**. It's a fast check, and its answer decides
whether the rest is worth running.

- Verdict `split` → report the seam and **stop**. Don't dispatch the others:
  their findings would be against a diff that's about to be rearranged, and
  a long bug list on a doomed PR is noise the user has to re-read later.
- Verdict `ship as one`, or the axis was skipped → carry on.

## 4. Dispatch the rest

One line per axis on the choice, including skips. Spawn the agents **in
parallel**: PR ref + one-line intent, replies machine-consumed (findings and
verdict only). Existing comments go to the defects agent only, to assess
each as addressed / valid / invalid.

## 5. Merge and report

The only full rendering — each finding exactly once, presented as one
review.

- Order: defects by severity, tests, quality by payoff, design with a11y
  first
- Tag each finding **mechanical** or **judgement**. Mechanical = a concrete
  defect with a local fix any author would apply: verified logic slip,
  leftovers, type hygiene, missing a11y attribute, wrong assertion, missing
  test with a named behaviour. Judgement = everything else. In doubt →
  judgement: wrongly-mechanical gets applied unseen; wrongly-judgement only
  costs a decision.
- Overlaps: one copy, from the owning axis. Missing test → defects; quality
  of an existing test → tests.
- Valid comments become findings (deduped, tagged). Addressed / invalid:
  one line each at the end. Never post to GitHub.
- Verdict: the strictest agent's, with the single most important reason.
  Stop there — no summary, no recap.
