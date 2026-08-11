---
name: pr-watch
description: 'Watch a PR for a bounded window: wake when review comments or CI results land, assess new comments against the code, fix the mechanical ones, and surface the rest. Always terminates on its own. USE WHEN: user says "watch this PR", "watch PR <n>", "babysit the PR", or the implement flow arms its post-report watch.'
---

# Watch a PR — bounded

Copilot's review and CI both land a few minutes after a PR goes up. Arm a
background watch so those arrivals wake the session, then leave it alone.
Never sit in a foreground polling loop.

## 1. Arm the monitor

Use the Monitor tool: `persistent: false`, `timeout_ms: 900000`. The script
polls with `gh` every 30 seconds and:

- emits one line per new inline review comment and per new review
- emits one line per check run reaching a terminal state
- exits on its own when there is nothing left to wait for — every check
  terminal and no reviewer still requested — or at its own ~14-minute
  deadline, whichever is first. The Monitor timeout is only the backstop; the
  script's exit is the normal end, so an untouched PR stops the polling by
  itself.

Reference script — fill `repo` and `pr`, adapt as needed:

```bash
repo=<owner/repo>; pr=<n>; end=$((SECONDS + 840)); nc=0; nr=0; prev=""
while [ $SECONDS -lt $end ]; do
  c=$(gh api "repos/$repo/pulls/$pr/comments?per_page=100" 2>/dev/null) || c='[]'
  t=$(jq length <<<"$c")
  [ "$t" -gt "$nc" ] && jq -r --argjson n "$nc" '.[$n:][] |
    "comment by \(.user.login) — \(.path):\(.line // 0) — \(.body | gsub("[\r\n]+"; " ") | .[0:400])"' <<<"$c"
  nc=$t
  r=$(gh api "repos/$repo/pulls/$pr/reviews" 2>/dev/null) || r='[]'
  t=$(jq length <<<"$r")
  [ "$t" -gt "$nr" ] && jq -r --argjson n "$nr" '.[$n:][] |
    "review by \(.user.login): \(.state)"' <<<"$r"
  nr=$t
  s=$(gh pr checks "$pr" --json name,bucket 2>/dev/null) || s='[]'
  cur=$(jq -r '.[] | select(.bucket != "pending") | "check \(.name): \(.bucket)"' <<<"$s" | sort)
  comm -13 <(printf '%s\n' "$prev") <(printf '%s\n' "$cur")
  prev=$cur
  pending=$(gh pr view "$pr" --json reviewRequests --jq '.reviewRequests | length' 2>/dev/null || echo 1)
  jq -e 'length > 0 and all(.bucket != "pending")' <<<"$s" >/dev/null \
    && [ "$pending" -eq 0 ] && [ $SECONDS -gt 120 ] && break
  sleep 30
done
echo "watch over"
```

The 120-second floor stops an instant all-green from closing the watch before
Copilot has even been requested. A repo with no checks at all never satisfies
the early exit and simply runs to the deadline — still bounded.

## 2. Handle events as they arrive

- **New comments** — refetch their full bodies with `gh`, then dispatch the
  defects agent to judge each one addressed, valid, or invalid, passing the
  comments and PR number. Use the level a review already picked this session;
  with no prior review, route by pr-review's rule (deep for risky changes,
  quick otherwise). Tag the valid ones mechanical or judgement by pr-review's
  disposition rule. If any are mechanical: `git fetch origin`, re-create a
  worktree on the existing branch — `git worktree add
  .claude/worktrees/<branch> <branch>`, fast-forwarded to `origin/<branch>`;
  if it will not fast-forward, stop and tell the user — dispatch
  `apply-review-fixes`, then remove the worktree per part 4 of the worktree
  skill. Report the whole assessment in chat: fixed and pushed, for the
  user's judgement, addressed, invalid.
- **A failed check** — surface it: the check name and a line or two from
  `gh run view --log-failed`. Do not fix it; say what you would look at
  first.
- **The watch ends** — one line. If nothing arrived, say the watch closed
  quietly.

## 3. One round only

A fix push starts fresh CI and may draw a new Copilot review; do not re-arm
the watch for those, and never restart a watch that has ended. Every path
through this skill terminates. Whatever lands after the watch closes is the
user's, in a separate session.
