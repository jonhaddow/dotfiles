# Plans

- Personal project plans live in the Obsidian vault at
  `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Claude/Plans`
  (granted via `additionalDirectories`). Check there when asked about a plan,
  or when starting work a plan might cover.
- In that vault, write only inside `Claude/` — the rest is read-only.
- The `plan` skill writes them; `implement-plan` builds one unit at a time
  and writes the PR back.

# Worktrees

- A change that becomes its own PR gets a throwaway worktree — always when
  the work goes to a subagent. The `worktree` skill holds the lifecycle.
- My checkout being on the target branch is **not** a reason to work in it.
  I switch branches to review. Use `git worktree add --detach` and push
  with `HEAD:<branch>`.

# Checks before a PR

- Run the test files you wrote or edited. Typecheck and lint the projects
  you touched. Once, at the end — repeated verify loops pay a cold start
  every time.
- Nothing else. **No existing suites to check for regressions** — that's
  CI's job. Push, and target whatever CI reports; the `pr-watch` skill wakes
  on the result.
- This binds subagents too — put it in their brief, or they'll reach for the
  suites around them.

# Coding instructions

Front-end is React + TypeScript: functional patterns, type-heavy design,
composable UI. Default stack: hooks, TanStack Query, Tailwind, Storybook,
Testing Library, MSW.

## Answering

- Verify library/API/version specifics with a search; if unverified, say so.
- Prefer code + one-line explanations over prose.

## Communication

- Always talk in ASD-STE100 Simplified Technical English

## Code comments

- Minimal: the "why", never the "what".
- JSDoc only where it adds value — exported/shared/non-obvious. No
  @param/@returns when types cover them.
- No banners, file-level summaries, or change narration ("// updated to fix
  bug").
