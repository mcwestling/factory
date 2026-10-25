---
name: do-factory-setup
description: Set up a repo for the factory skills. Writes the repo's values-only tracker doc (`docs/issue-tracker.md`) from Linear and opinionated defaults, asking only what neither settles. It points AGENTS.md at it, and writes the README's non-developer intro if it has none. Re-running fills gaps only.
disable-model-invocation: true
---

The other factory skills (`do-post-its`, `do-triage`, `do-refine`, `do-implement`) hold all of the procedure and none of the workspace values. Each repo keeps those values in one short **tracker doc**. Your job is to write that doc for the repo you are in, so the other skills can run here.

The doc holds **values only**: names, labels, statuses, views and the rules that pick between them. It holds no step-by-step procedure, and it never links to another repo.

## Linear

Use the Linear MCP server for every read (in an Orca workspace, `orca linear` also qualifies). If it is unavailable or unauthorized, stop and report that; don't fall back to a browser, the app, or the API. Never write to Linear unless the user says yes to that specific change.

## 1. Find what exists

1. **Tracker doc path:** if `AGENTS.md` names a tracker doc, use that path. Otherwise use `docs/issue-tracker.md`.
2. **Existing doc:** if it exists, read it. Every value already in it is settled: you never overwrite it, only fill gaps. A **gap** is a heading from the shape below that is missing or empty, or a line starting `TODO:`. Angle-bracket text in a written doc (like `<KEY>-<number>` or `<reason>`) is a value, not a gap.
3. **AGENTS.md:** note whether it links the tracker doc.
4. **README:** read `README.md`, if any, and note whether it opens with a non-developer intro (see step 6).

If the doc has no gaps, AGENTS.md links it and the README has its intro, the repo is set up: do step 2 only to check for drift, report, and write nothing.

## 2. Read Linear

Read in parallel:

- **Workspace and team:** `get_workspace` for its name; `list_teams`. Ignore retired teams. If several remain, ask which one this repo's issues live in. Record its name and key.
- **Issue statuses:** `list_issue_statuses` for that team, in workflow order.
- **Labels:** `list_issue_labels` with groups included, for the team and the workspace. Find the Product group (one label per product), the Dispatch target group (one label per tool doing the work), a Bug label, the `wayfinder:` decision labels, and retired labels (those with `retiredAt`). Report any other active label that fits none of these; don't add it to the doc.
- **Project statuses:** read them from the team's projects (`list_projects`). Projects only show statuses in use, so the default set fills in the rest.
- **Initiatives:** `list_initiatives`, with each description's first line.
- **Views:** `list_custom_views`. Record views by exact name, never by URL: URLs carry workspace ids.
- **Templates:** `list_templates`, for the implementation-issue template.

If the doc already exists, compare it with what you read. Where Linear disagrees with a value in the doc (a renamed status, a deleted view), report the drift and leave the doc alone.

## 3. Settle the values

Setup is opinionated: the same Linear workspace always gives the same doc. Settle every gap from what you read in Linear plus the [defaults](#defaults), without asking. Ask only where neither can settle it:

- **Team:** several active teams, so ask which one this repo uses.
- **Repo routing:** a product initiative whose first description line isn't exactly `Repo: owner/name` or `Repo: none`. Ask what each one should say, and offer to write those lines to the initiatives; only do it if the user says yes.
- **Unknown names:** an issue status, project status or Dispatch target label the defaults don't cover. Ask for a one-line meaning.

Ask these together in one AskUserQuestion call when it is available. If the user doesn't know an answer, write a one-line `TODO:` under its heading; a later run fills it.

## 4. Write the tracker doc

Write the doc with exactly the headings below, in this order. Headings are keys the other skills look up by name: never rename them. Every `<…>` slot below is filled with a value or replaced by a `TODO:` line; none is copied into the doc as-is. Fill only the gaps and keep every existing line as it was. Show the user the full draft for a new doc, or the diff for an existing one, and save once they approve. Corrections at that point are their only edits; don't turn the review into questions.

Keep it public-safe: no secrets, internal URLs, workspace ids, machine names or personal data. Write example ids with the team's key, like `<KEY>-<number>`.

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

- **Product** (group, single-select): <meaning>
- **Dispatch target** (group, single-select): <meaning>
- **Bug:** <meaning>
- **Decision types:** <the `wayfinder:` labels>
- **Retired, never apply:** <the workflow labels agents might reach for>. Any other label with `retiredAt` is retired too.

## Templates

- **Implementation issues:** `<template name>`

## Initiatives

<How products map to initiatives.>

## Repo routing

<Source, On the issue, Lookup, Cross-check, Unresolved: see the default.>

## Dispatch targets

<Table: Label | Use it when. Then how the label is set, and the default target.>

## Preferred models

**Checked:** <YYYY-MM-DD>. <When to re-check.>

<Table: Model | Use it for.>

**Sources:**

- <vendor model page>

## Views

<Table: View | Kind | Filters, by exact name.>

## Triage

- **Queue:** <which issues>
- **Look-back:** <how far back to survey Done and Canceled issues>

## Comment shape

<Table and datelines; see the default.>

## Pull requests

- **Title:** <format, ending with the issue id in parentheses>
- **Branch:** <naming rule>
- **Review:** <who marks PRs ready and merges>
```

### Defaults

Use these wherever Linear doesn't settle a value. Replace `<KEY>` with the team's key and `<workspace>` with the workspace name.

- **Tracker:** the opening line is "This is `<workspace>`'s config; to adopt, copy it and replace the values." Access is Linear MCP only; in an Orca workspace, the `orca linear` CLI also qualifies.
- **Team scope:** the one team holds every product and company issue. With several active teams, it holds this repo's products.
- **Issue statuses:** keep the team's workflow order. Use these meanings for the names that match:
  - `Triage`: captured, not yet reviewed. Default for new issues.
  - `Backlog`: in a map but not ready yet.
  - `Todo`: ready. Blockers still decide whether work can start.
  - `In Progress`: claimed, including draft PRs.
  - `In Review`: PR out of draft and ready to merge. A draft PR stays `In Progress`. Set only by Linear's GitHub automation, never by agents.
  - `Done`: decision resolved, or PR merged.
  - `Canceled`: declined or won't do.
  - `Duplicate`: duplicate of another issue.
- **Project statuses:** the factory uses all six, whether or not a project is in one yet:
  - `Uncharted`: stub map from triage, not yet charted.
  - `Idea`: charted with a Destination; decisions still open, nothing sliced.
  - `Planned`: enough decisions made that implementation issues are sliced or ready to slice.
  - `Ongoing`: work has started.
  - `Done`: Destination reached.
  - `Won't Do`: abandoned.
- **Labels:** Product is the product an issue belongs to and matches its initiative. Dispatch target is the tool doing the work. Bug is a concrete defect; a Triage item without it is a muse. For retired labels, list the workflow labels agents might reach for, then add "Any other label with `retiredAt` is retired too."
- **Templates:** the team template whose name says it is for implementation issues; otherwise a `TODO:`.
- **Initiatives:** each product has an initiative with the same name as its Product label, and its description opens with a `Repo:` line. If some initiatives have no Product label, or the reverse, say so in the doc and in the report.
- **Dispatch targets:** one row per active label in the Dispatch target group, "Work dispatched from <label>", plus any note the label's description gives. Then: "The label records where the work was dispatched from, not where the session runs or which model ran. Set it when work starts." The default target is the label for the tool running this setup, if there is one; otherwise the first label.
- **Preferred models:** for each vendor behind a Dispatch target, fetch its model page, follow redirects and record the final URL under Sources. Write one row for its strongest model and one for its fastest capable coding model, each with a one-line "use it for". Record today's date as **Checked**.

- **Repo routing:**
  - **Source:** each product initiative's description opens with exactly `Repo: owner/name`, or `Repo: none` for a product with no repo yet. Several products may share a repo. This is the only product-to-repo mapping.
  - **On the issue:** a `` `[repo=owner/name]` `` tag in the issue description, written as a code span. Linear escapes bare brackets to `\[repo=…\]`, which also counts. It is the same syntax Cursor's Linear integration reads, and it overrides everything else.
  - **Lookup:** Product label → the initiative with the same name → its `Repo:` line. One hop; never inferred from anything else.
  - **Cross-check:** PRs already linked to other issues of the same product. A mismatch stops the work.
  - **Unresolved:** no tag and `Repo: none` (or no `Repo:` line). There is no default repo.
- **Views:** introduce the table with "The factory expects exactly these shared views on the `<KEY>` team. Keep them, and find them by exact name with `list_custom_views`." The factory skills look for five:
  - `Factory: Maps` (projects): project status not finished; grouped by initiative, sub-grouped and ordered by project status.
  - `Factory: Decisions` (issues): `Todo`, no assignee, not blocked, a `wayfinder:` label, in a project.
  - `Factory: Ready` (issues): `Todo`, no assignee, not blocked, no `wayfinder:` label; grouped by Product, then project.
  - `Factory: Agent Work` (issues): `In Progress` or `In Review`, and either delegated to an agent or carrying a Dispatch target label; grouped by Product, then project.
  - `Factory: All Work` (issues): `In Progress` or `In Review`.

  If any are missing in Linear, list them for the user to create; the MCP can't create views.
- **Preferred models:** re-check when the Checked date is over 90 days old or a listed model retires.
- **Triage:** every `<KEY>` issue in `Triage`; look back 90 days.
- **Pull requests:** title like `Fix the login redirect bug (<KEY>-<number>)`; branch exactly the issue's Linear branch name (`gitBranchName` from `get_issue`), never invented or prefixed; no PR autopilot, so PRs open as drafts and a person marks them ready and merges.
- **Priority:** not used; leave every issue at No priority.
- **Comment shape:**

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
  - **Kickoff prompt:** a fenced `text` block reading `To kick this off, run /do-implement <KEY>-<number>`

## 5. Point AGENTS.md at it

The other skills find the tracker doc through `AGENTS.md`. If `AGENTS.md` doesn't already link the doc, add one line under an `## Issue tracker` heading, using the path from step 1:

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
