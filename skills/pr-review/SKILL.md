---
name: pr-review
description: 'Full review of the current branch or a PR: triages the diff, picks the right review agent per axis (defects: quick/deep, tests: on/skip, quality: light/strict, design: on/skip), runs them in parallel, and merges the results with a disposition — mechanical or judgement — on every finding. USE WHEN: user says "review this PR", "review my branch", "review this before I raise a PR", or wants a review without choosing agents manually.'
---

# PR Review Router

Review a change along four independent axes — defects (is it broken?), tests (do they earn their place and assert the right thing?), quality (is it well-built?), and design (does the UI meet the guidelines?) — delegating each axis to the right agent. Your job in the main session is triage, dispatch, and merging; do not review the code yourself.

## 1. Triage the diff

Triage from the shape of the change, not its contents. **Do not read the full diff here** — every agent you dispatch reads it in its own context, and a second copy in yours buys nothing but costs the room you need for the merged report.

- Given a PR number or URL: `gh pr view <n>` for intent, then `gh pr diff <n> --stat`.
- Given a PR, also collect the review comments already on it — Copilot's and humans' alike: `gh api repos/{owner}/{repo}/pulls/<n>/comments --paginate` for inline comments, `gh pr view <n> --json reviews` for review summaries. Keep each comment's `file:line`, body, and author; a `position` of null means the code it sat on has since changed. Do not assess them here — the defects agent does that with the code open. A review requested on a just-raised PR may not have landed yet; take what exists, do not wait for it.
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

If you collected existing PR comments, pass them — in full, with `file:line` and author — to the **defects agent only**, and tell it to assess each one against the code: already addressed, valid, or invalid.

## 4. Merge and report

The merged report is the **only** full rendering of the review — the user never sees the agents' replies directly, so render every finding here exactly once and add nothing around it.

- Defect findings first ranked by severity, then test findings, then quality findings ranked by payoff, then design findings with accessibility first. Attribute nothing to "the agents" — present it as one review.
- Tag every finding with a disposition at the end of its line: **mechanical** or **judgement**. Mechanical means the finding names a concrete defect and a local fix a competent author would apply without discussion — no change of approach, public surface, or scope. Typical: a verified logic slip with an obvious correction, leftovers, type hygiene, a missing accessibility attribute, a test asserting the wrong thing, a missing test with a named behaviour and level. Judgement is everything else: structure and abstraction suggestions, trade-offs, performance hunches, scope questions, anything the author could reasonably decline. When in doubt, judgement — a wrongly-mechanical finding gets applied without a human looking; a wrongly-judgement one only costs the user a decision.
- Where the axes overlap (typically type hygiene, accessibility issues that are also bugs, or a test the quality reviewer also called out), keep one copy of the finding — the one from the axis that owns it. On tests specifically: a missing test is the defect axis's; the quality of an existing test is the test axis's.
- Fold in the defects agent's assessment of the existing PR comments. A comment judged valid becomes a finding like any other — deduped against the agents' own findings, ranked, and tagged with a disposition. Comments judged already addressed or invalid get one short section at the end, one line each with the reason. Whether to resolve or reply to them on GitHub is the user's; you never post there.
- Final verdict is the strictest of the agents' verdicts. State it with the single most important reason.
- Stop after the verdict. No overall summary paragraph, no recap of the process, no restatement of what the PR does.
