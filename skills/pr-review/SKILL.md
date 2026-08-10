---
name: pr-review
description: 'Full review of the current branch or a PR: triages the diff, picks the right review agent per axis (defects: quick/deep, tests: on/skip, quality: light/strict, design: on/skip), runs them in parallel, and merges the results. USE WHEN: user says "review this PR", "review my branch", "review this before I raise a PR", or wants a review without choosing agents manually.'
---

# PR Review Router

Review a change along four independent axes — defects (is it broken?), tests (do they earn their place and assert the right thing?), quality (is it well-built?), and design (does the UI meet the guidelines?) — delegating each axis to the right agent. Your job in the main session is triage, dispatch, and merging; do not review the code yourself.

## 1. Triage the diff

Triage from the shape of the change, not its contents. **Do not read the full diff here** — every agent you dispatch reads it in its own context, and a second copy in yours buys nothing but costs the room you need for the merged report.

- Given a PR number or URL: `gh pr view <n>` for intent, then `gh pr diff <n> --stat`.
- Otherwise resolve the base branch with `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, falling back to `git symbolic-ref --short refs/remotes/origin/HEAD` with the `origin/` prefix stripped — never assume `dev` or `main` — then `git diff --stat $(git merge-base HEAD origin/<base>)...HEAD` and `git log` for intent.

Collect: total lines changed (excluding lockfiles and generated code), files touched, and what the change does. Open individual files only when the stat and the intent leave the routing genuinely undecided.

## 2. Pick a level per axis

**Defects axis:**
- `review-defects-deep` if the change touches auth, payments, data persistence or migrations, concurrency, public API surface, feature flags, or many call sites — or exceeds roughly 400 changed lines of non-test code.
- `review-defects-quick` otherwise.

**Tests axis:**
- `review-tests` if the diff adds or changes any test file — spec, unit, integration, e2e, or the shared test setup.
- Skip this axis otherwise. It reviews the tests that are there; the defect agents own whether a change needed a test in the first place, on every diff.

**Quality axis:**
- `review-quality-strict` if the change adds new modules, components, or abstractions; grows any file substantially (or past 1000 lines); or adds branching to existing shared code.
- `review-quality-light` otherwise.
- Skip this axis entirely for docs/config-only changes or diffs under roughly 20 lines.

**Design axis:**
- `review-design` if the diff touches UI code: components, pages, markup, styles, or anything affecting rendered output or accessibility.
- Skip this axis otherwise (pure logic, API, config, or test changes).

Borderline cases: escalate. A wasted deep review costs minutes; a missed one costs an incident.

## 3. Dispatch

Tell the user which level was chosen for each axis and why (one line per axis, including skipped axes). Then spawn the chosen agents **in parallel** with the Agent tool, passing each one the PR number/URL or branch ref and a one-sentence summary of the change's intent. Remind each agent that its reply is machine-consumed: findings and verdict only. Wait for all of them to finish.

## 4. Merge and report

The merged report is the **only** full rendering of the review — the user never sees the agents' replies directly, so render every finding here exactly once and add nothing around it.

- Defect findings first ranked by severity, then test findings, then quality findings ranked by payoff, then design findings with accessibility first. Attribute nothing to "the agents" — present it as one review.
- Where the axes overlap (typically type hygiene, accessibility issues that are also bugs, or a test the quality reviewer also called out), keep one copy of the finding — the one from the axis that owns it. On tests specifically: a missing test is the defect axis's; the quality of an existing test is the test axis's.
- Final verdict is the strictest of the agents' verdicts. State it with the single most important reason.
- Stop after the verdict. No overall summary paragraph, no recap of the process, no restatement of what the PR does.
