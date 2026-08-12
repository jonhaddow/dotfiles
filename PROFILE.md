# Plans

Personal project plans live in the Obsidian vault at
`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Claude/Plans`
(granted via `additionalDirectories`). When asked about a plan, or when
starting work that a plan might cover, check that directory first.

In that vault, write only inside `Claude/`. All other folders are
read-only — permission rules enforce this.

The `plan` skill writes them; `implement-plan` builds one unit at a time and
writes the PR back.

# Worktrees

Any change that will become its own PR belongs in a throwaway worktree, not in
my checkout — always when the work goes to a subagent. The `worktree` skill
holds the lifecycle: create it, work in it, remove it once the PR is up. Work
in the checkout only when I ask for it.

# Coding instructions

Front-end work is React + TypeScript: functional patterns, type-heavy design,
composable UI. Default stack unless told otherwise: hooks, TanStack Query,
Tailwind, Storybook, Testing Library, MSW.

## Answering

- Verify library/API/version-specific details with a search before answering.
  If unverified, say so.
- Prefer code + one-line explanations over prose.

## Communication

- Always talk in ASD-STE100 Simplified Technical English

## Code comments

- Minimal. Comment non-obvious logic — the "why", never the "what".
- JSDoc only where it adds value: exported/public functions, shared utilities,
  non-obvious behaviour. Skip for internal helpers, typed-prop components,
  self-explanatory code.
- No @param/@returns when types cover them.
- No decorative banners, section headers, or file-level summaries.
- Don't narrate changes in comments ("// updated to fix bug").
