---
name: jira
description: 'Create and update Jira work items with acli — tickets, subtasks, comments, transitions, links to PRs and other tickets. USE WHEN: user says "raise a Jira ticket", "create subtasks for this", "update the ticket", "put the PR on the ticket", or another skill (plan) points here for the Jira work.'
---

# Jira work items

`acli` is the only way in. Everything here writes to a board other people
read — say what you will create, and wait for a yes, before the first write.

## 1. Preflight

```bash
command -v acli && acli jira auth status
```

- No `acli` → **stop**. It installs with `brew install atlassian/acli/acli`.
- Not authenticated → **stop**. `acli jira auth login`.
- Don't improvise around a missing CLI — no REST calls, no browser.

## 2. What belongs on a ticket

- Jira holds **what and why**. The plan holds the how; the code and the PR
  hold the detail.
- **Never reference a plan document** — no file name, no vault path, no
  Obsidian link, no "see the plan". A reader outside my notes must still
  understand the ticket on its own.
- Link freely to **PR URLs** and **other Jira keys** — a bare `ABC-12`
  auto-links.

## 3. Wording

**Summary** — imperative, one line, under ~80 characters, no trailing full
stop. No `PR1 —` prefixes, no project tag: Jira already shows the key.

**Description** — plain text, in this order, skipping what doesn't apply:

- One sentence on the outcome — what is true once this is done.
- The why, only when it isn't obvious from the outcome.
- Scope: what is in, and what is deliberately out.
- Dependencies as bare keys — `Depends on ABC-12`.

Leave out file lists, code sketches, step sequences and status narration —
they rot, and the PR says it better. Multi-line descriptions go through
`--description-file` rather than shell escaping.

## 4. Create

Read the parent first — its type decides the child's:

```bash
acli jira workitem view ABC-123 --fields summary,issuetype,status --json
```

- Parent is a Story / Task / Bug → children are subtasks.
- Parent is an Epic → children are Stories or Tasks, same `--parent`.

```bash
acli jira workitem create --project ABC --type Subtask --parent ABC-123 \
  --summary "<one line>" --description-file <file>
```

- Type names vary by site (`Subtask` vs `Sub-task`) — a rejected type means
  read the project's types, not guess again.
- One create per unit, in order. A create fails → stop and report; don't
  carry on and leave a half-built tree.

## 5. Update

- Summary or description: `acli jira workitem edit --key ABC-124 -s "<...>" --yes`.
  Edit **replaces** — view the current value before overwriting one.
- Status: `acli jira workitem transition --key ABC-124 --status "In Progress" --yes`.
- Progress, PR links, decisions: a **comment**, never the description —
  `acli jira workitem comment create --key ABC-124 --body "PR: <url>"`.
- Between tickets: `acli jira workitem link create --out ABC-1 --in ABC-2 --type Blocks`.

## 6. Report

Every key you touched, with its browse URL
(`https://<site>.atlassian.net/browse/ABC-124`), one line each.
