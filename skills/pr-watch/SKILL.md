---
name: pr-watch
description: 'Watch a PR for a bounded window: wake when review comments or CI results land, assess new comments against the code, fix the mechanical ones, and surface the rest. Always terminates on its own. USE WHEN: user says "watch this PR", "watch PR <n>", "babysit the PR", or the implement flow arms its post-report watch.'
---

# Watch a PR — bounded

Reviews and CI land minutes after a PR opens or a push. Arm a background
watch that wakes the session — never poll in the foreground.

## 1. Arm

Monitor tool: `persistent: false`, `timeout_ms: 900000`. The script polls
`gh` every 30s, emits a line per new comment / review / finished check, and
exits when nothing is left to wait for, or at ~14 min. The Monitor timeout
is only the backstop.

Reference script — fill `repo` and `pr`:

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

The 120s floor keeps an instant all-green from closing the watch before
reviewers register. A repo with no checks runs to the deadline — still
bounded.

## 2. On events

- **Comments** → refetch full bodies. Defects agent judges each addressed /
  valid / invalid — pass it the PR number and the findings the user already
  saw, so nothing repeats. Valid → mechanical or judgement (pr-review's
  rule). Mechanical → reacquire the branch (worktree part 5),
  `apply-review-fixes`, remove (part 4). Report: fixed, judgement,
  addressed, invalid — judgement in pr-review's short form, four lines each.
- **Red check** → PR owns it (lint, typecheck, its tests) → mechanical, one
  fix attempt through the same path. Flake / infra / unrelated → surface the
  name + a line from `gh run view --log-failed`.
- **End** → one line. Nothing arrived → say it closed quietly.

## 3. One round

A fix push restarts CI — don't re-arm for it, never restart an ended watch.
Whatever lands later is the user's, in a new session.
