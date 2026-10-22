---
name: do-factory-setup
description: Set up a repo for the factory skills. Writes the repo's values-only tracker doc (`docs/issue-tracker.md`) from Linear plus a short interview, points AGENTS.md at it, and writes the README's non-developer intro if it has none. Re-running fills gaps only. Use when adopting the factory in a repo, or when a skill reports a missing tracker value.
---

The factory skills (`do-post-its`, `do-triage`, `do-refine`, `do-implement`) hold all of the procedure and none of the workspace values. Each repo keeps those values in one short **tracker doc**. Your job is to write that doc for the repo you are in, so the other skills can run here. Install all the factory skills together; they link to each other.

The doc holds **values only**: names, labels, statuses, views and tables. It holds no procedure, and it never links to another repo.

## Linear

Use the Linear MCP server for every read. If it is unavailable or unauthorized, stop and report that; don't fall back to a browser, the app, or the API. This skill writes to the repo, never to Linear, unless the user asks for a specific Linear change in the interview.

## 1. Find what exists

1. **Tracker doc path:** if `AGENTS.md` names a tracker doc, use that path. Otherwise use `docs/issue-tracker.md`.
2. **Existing doc:** if it exists, read it. Every value already in it is settled: you will **never overwrite it**, only fill gaps. A gap is a heading from the shape below that is missing, or one that is present but empty or still holds a placeholder.
3. **README:** read `README.md`, if any, and note whether it opens with a non-developer intro (see step 6).
4. If the doc is complete, AGENTS.md already points at it, and the README has its intro, say so and stop. A re-run on a finished repo changes nothing.

## 2. Read Linear

Read in parallel, then summarize what you found in one short message before interviewing:

- **Teams:** `list_teams`. If there are several, ask which team this repo's issues live in. Record its name and key.
- **Issue statuses:** `list_issue_statuses` for that team, in workflow order.
- **Labels:** `list_issue_labels` with groups included, for the team and the workspace. Find the Product group, a Dispatch target group, a Bug label, the `wayfinder:` decision labels, and retired labels (those with `retiredAt`).
- **Project statuses:** read them from the team's projects (`list_projects`) and confirm the full set and their meanings with the user; projects only show statuses in use.
- **Initiatives:** `list_initiatives`, with each description's first line.
- **Views:** `list_custom_views`. Record views by exact name, never by URL: URLs carry workspace ids.
- **Templates:** `list_templates`, for the implementation-issue template.

Only read what fills a gap. On a re-run, if Linear disagrees with a value already in the doc (a renamed status, a deleted view), report the drift and leave the doc alone.

## 3. Interview

Ask only about gaps, using AskUserQuestion when it is available (at most 4 questions per call; repeat rounds as needed). Offer concrete options drawn from what you read in Linear, with a recommended default first.

- **Repo routing:** for each product initiative, show its first description line. It must be exactly `Repo: owner/name`, or `Repo: none` for a product with no repo yet. List the ones that are missing or malformed and ask what each should say. Offer to write those lines to the initiatives; only do it if the user says yes.
- **Dispatch targets:** which tools do the work (for example Claude Code, Codex, Cursor, Conductor, Orca), the label for each, when each applies, and the default.
- **Preferred models:** which model to use for which kind of work. Record today's date as **Checked** and the vendor pages the user names as **Sources**.
- **Comment shape:** offer the default in [the shape](#comment-shape-default) below; ask only whether to change it.
- **Pull requests, triage and priority:** offer the defaults in the shape below; ask only whether to change them.
- **Meanings:** for each status and view, propose a one-line meaning from its name and filters, and let the user correct them in one pass.

If an answer is unknown, leave the heading with a one-line `TODO:` and move on; a later run fills it.

## 4. Write the tracker doc

Write the doc with exactly the headings below, in this order. Headings are keys the other skills look up by name: never rename them. Fill only the gaps; keep every existing line as it was. Show the user the diff before saving.

Keep it public-safe: no secrets, internal URLs, workspace ids, machine names or personal data. Use placeholders like `ABC-123` in examples.

```markdown
# Issue tracker

<One line: whose config this is.>

The skills hold the procedure. This file holds only the values they look up, under the headings below. Keep the headings stable: skills cite them by name.

## Tracker

- **Tool:** Linear, workspace **<name>**.
- **Access:** Linear MCP only. <Any other client that qualifies.>

## Team

- **Name:** <team name>
- **Key:** `<KEY>` (issue ids look like `<KEY>-<number>`)
- **Scope:** <what the team holds>

## Issue statuses

<Table: Status | Meaning, in workflow order. Say which status agents never set.>

## Project statuses

<Table: Status | Meaning.>

## Priority

<How priority is used, or "Not used.">

## Labels

- **Product** (group, single-select): <...>
- **Dispatch target** (group, single-select): <...>
- **Bug:** <...>
- **Decision types:** <the `wayfinder:` labels>
- **Retired, never apply:** <...>

## Templates

- **Implementation issues:** `<template name>`

## Initiatives

<How products map to initiatives.>

## Repo routing

- **Source:** <where the `Repo:` line lives>
- **On the issue:** a `` `[repo=owner/name]` `` tag in the issue description, written as a code span. Linear escapes bare brackets to `\[repo=…\]`, which also counts. It overrides everything else.
- **Lookup:** Product label → the initiative with the same name → its `Repo:` line.
- **Cross-check:** PRs already linked to other issues of the same product. A mismatch stops the work.
- **Unresolved:** no tag and `Repo: none` (or no `Repo:` line). There is no default repo.

## Dispatch targets

<Table: Label | Use it when. Then how the label is set, and the default target.>

## Preferred models

**Checked:** <YYYY-MM-DD>. <When to re-check.>

<Table: Model | Use it for.>

**Sources:** <vendor model pages>

## Views

<Table: View | Kind | Filters, by exact name.>

## Triage

- **Queue:** <which issues>
- **Look-back:** <how far back to survey Done and Canceled issues>

## Comment shape

<Table and datelines; see the default below.>

## Pull requests

- **Title:** <format, ending with the issue id in parentheses>
- **Branch:** <naming rule>
- **Review:** <who marks PRs ready and merges>
```

### Defaults

Offer these where the shape above leaves a choice.

- **Views:** the factory skills look for five views on the team, by exact name: `Factory: Maps` (projects not finished, grouped by initiative and status), `Factory: Decisions` (unassigned, unblocked `Todo` issues with a `wayfinder:` label, in a project), `Factory: Ready` (the same, without a `wayfinder:` label), `Factory: Agent Work` (`In Progress` or `In Review`, delegated to an agent or carrying a Dispatch target label) and `Factory: All Work` (`In Progress` or `In Review`). If any are missing in Linear, list them for the user to create; the MCP can't create views.
- **Triage:** every team issue in `Triage`; look back 90 days.
- **Pull requests:** title `Fix the login redirect bug (ABC-123)`; branch exactly the issue's Linear branch name (`gitBranchName`); PRs open as drafts, and a person marks them ready and merges.
- **Priority:** not used; leave every issue at No priority.

#### Comment shape default

| Element            | Markdown                 | Notes                   |
| ------------------ | ------------------------ | ----------------------- |
| Dateline           | `YYYY-MM-DD —` summary   | First line of a comment |
| Section label      | `**Label:**` text        | Bold label inline       |
| Paths, keys, enums | `` `like-this` ``        | Monospace               |
| Bullets            | `- item` on its own line | Standard list           |
| Steps              | `1. item`                | Numbered line           |

Datelines in use:

- **Triage route:** `YYYY-MM-DD — Triage: <Route>. <reason>. <links>`
- **PR opened:** `YYYY-MM-DD — PR opened: <link>`
- **Back to Triage:** `YYYY-MM-DD — Back to Triage: <reason>.`
- **Decision resolved:** a `## Resolution (YYYY-MM-DD)` heading
- **Kickoff prompt:** a fenced `text` block reading `To kick this off, run /do-implement ABC-123`

## 5. Point AGENTS.md at it

The other skills find the tracker doc through `AGENTS.md`. If `AGENTS.md` doesn't already link the doc, add one line under an `## Issue tracker` heading:

```markdown
The workspace values the skills read are in [`docs/issue-tracker.md`](docs/issue-tracker.md).
```

Create `AGENTS.md` with just that heading and line if the repo has none. Never touch anything else in it.

## 6. Write the README intro

Skip this step if `README.md` already opens with an intro for non-developers: a plain description of what the product does and who it's for, before any setup or code.

Otherwise, draft one and put it at the top of the README, above any developer sections, which you leave as they are. It has a loose, fixed shape, plain headings and no machine markers:

1. **Name and one-line pitch:** the `#` title, then one sentence on what it is.
2. **What it does:** a short paragraph or a few bullets, in plain words.
3. **Who it's for:** one short paragraph.
4. **Links:** to deeper docs in the repo (setup, contributing, license).

Draft it from the repo itself (code, existing docs, the product's initiative description) and ask the user for anything you can't tell. Show the draft and get the user's approval before writing.

**Public safety:** say what it does and who it's for. Never include secrets, internal URLs, workspace or machine ids, personal data, or client details, unless the client is already public about it.

## 7. Report

Tell the user what you wrote (tracker doc gaps filled, AGENTS.md line, README intro), what you left as `TODO:`, any drift between Linear and the doc, and any views or `Repo:` lines still missing in Linear. Don't commit unless asked.

## Boundaries

- Never overwrite a value already in the tracker doc. Report drift instead.
- Never write to Linear without the user's yes for that specific change.
- Never put procedure in the tracker doc; that belongs in the skills.
- Never link the tracker doc to another repo; it stands alone.
