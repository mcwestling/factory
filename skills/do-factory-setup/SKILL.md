---
name: do-factory-setup
description: Set up a repo for the factory skills. Writes the repo's values-only tracker doc (`docs/issue-tracker.md`) from Linear and a fixed template, asking only what neither settles. It points AGENTS.md at it, writes the README's non-developer intro if it has none, and installs the dev-port convention in a repo with a dev server. Re-running fills gaps only.
disable-model-invocation: true
---

The other factory skills (`do-post-its`, `do-triage`, `do-refine`, `do-implement`) hold all of the procedure and none of the workspace values. Each repo keeps those values in one short **tracker doc**. Your job is to write that doc for the repo you are in, so the other skills can run here. If the repo has a dev server, you also install the [dev-port convention](https://github.com/mcwestling/factory/blob/main/tools/orca/README.md), so parallel Orca workspaces each get their own ports.

Setup is opinionated and deterministic: the same Linear workspace always gives the same doc. The doc is the [template](#template) below, copied verbatim, with only its `{{…}}` slots filled from Linear. Never reword, reorder or add to the template's text.

The run ends in one of two ways: one round of easy questions, or "Looks good, we're set up!" Never end with a list of notes for the user to parse.

## Linear

Use the Linear MCP server for every read (in an Orca workspace, `orca linear` also qualifies). If it is unavailable or unauthorized, stop and report that; don't fall back to a browser, the app, or the API. Write to Linear only when the user picks that option in a question.

## 1. Find what exists

1. **Tracker doc path:** if `AGENTS.md` names a tracker doc, use that path. Otherwise use `docs/issue-tracker.md`.
2. **Existing doc:** if it exists, read it. Every value already in it is settled: you never overwrite it, only fill gaps. A **gap** is a template heading that is missing or empty, or a line starting `TODO:`.
3. **AGENTS.md:** note whether it links the tracker doc.
4. **README:** read `README.md`, if any, and note whether it opens with a non-developer intro (see step 5).
5. **Dev server:** read the `dev` script in the root `package.json` (the workspace root's, in a monorepo), `scripts/dev-port`, and `orca.yaml`. No `package.json` or no `dev` script means no dev server: skip [Dev ports](#6-dev-ports).
6. **Setup version:** the doc's `**Setup version:**` line records which version of this template wrote it; this skill's version is the one in its template. The same version means fill gaps only. A doc with no such line predates versioning: treat it as `2026-10-25` and add the line as a gap. A doc with a newer version than the skill means the skill is out of date: stop and tell the user to update the factory skills.

## 2. Read Linear

Read in parallel:

- **Workspace and team:** `get_workspace` for its name; `list_teams`, ignoring retired teams.
- **Issue statuses:** `list_issue_statuses` for the team, in workflow order.
- **Labels:** `list_issue_labels` with groups included, for the team and the workspace.
- **Initiatives:** `list_initiatives`, with each description's first line.
- **Views:** `list_custom_views`.
- **Templates:** `list_templates` for the team, type `issue`.
- **Tool stack:** `list_documents` with query `Tool Stack`.
- **Models:** fetch each page under the template's Sources, following redirects, and check every model in the template's table is still listed.

## 3. Ask, once

Collect everything below that applies, and ask it all in one AskUserQuestion round (at most 4 questions per call; more calls only if needed). Write each question for someone new to the factory: say what you found in plain words, say what each option will do, and put the recommended one first. If someone new couldn't answer it, don't ask: use the default. Skip anything the existing doc already settles.

- **Team:** more than one active team. Which one does this repo's work live in?
- **Repo line:** a product initiative whose first description line isn't exactly `Repo: owner/name` or `Repo: none`. Offer the likely repo (this one, if the name fits), `Repo: none`, and leaving it for later. Offer to write the answer to the initiative.
- **Product label:** an initiative with no Product label of the same name, or the reverse. Offer to create the missing label or skip.
- **Unknown names:** an issue status, or a label in the Dispatch target group, that the template doesn't have a row for. Ask what it's for, with your best guess as the first option.
- **Default target:** the Dispatch target group has no `Orca` label. Which tool should do work by default?
- **Missing views:** a `Factory:` view from the template that Linear doesn't have. Say the user needs to create it in Linear (the MCP can't), with the filters from the template; offer "I'll do it" or "Skip for now".
- **Stale models:** a model the vendor page no longer lists. Offer to drop its row or keep it.
- **Dev command:** the `dev` script doesn't start the server itself (it calls a custom wrapper such as `node infra/scripts/dev-config.mjs`, or a task runner like `turbo dev`), so you can't tell with confidence how the server takes its port. Say in one sentence which file picks the port, then offer to edit that file so each workspace gets its own port, or to skip for now (every workspace keeps the current port). Never guess.
- **Template:** the team has issue templates, but not exactly one whose name or description says "implementation". Which one do agents use to write implementation issues? Offer each template by name, plus "None" (agents write them without a Linear template).
- **Drift:** on a re-run, a value in the doc that Linear contradicts (a renamed status, a deleted view). Offer to update the doc line or keep it.

Labels Linear has that the template doesn't use (like a `Release` label) are fine: say nothing about them.

If the user skips a question that fills a slot, write `TODO:` and the question in place of the slot's line.

## 4. Write

1. **Tracker doc:** fill only its gaps from the template, keeping every existing line as it was. For a new doc, write the whole template. Keep tables column-aligned.
2. **AGENTS.md:** if it doesn't link the doc, add this under an `## Issue tracker` heading, using the path from step 1, and touch nothing else. Create `AGENTS.md` with just that if the repo has none.

   ```markdown
   The workspace values the skills read are in [`docs/issue-tracker.md`](docs/issue-tracker.md).
   ```

3. **Linear:** make the changes the user picked in step 3, and nothing else.

Don't commit unless asked.

## 5. README intro

Skip this step if `README.md` already opens with an intro for non-developers: a plain description of what the product does and who it's for, before any setup or code.

Otherwise, write one at the top of the README, above any developer sections, which you leave as they are. It has a loose, fixed shape, plain headings and no machine markers:

1. **Name and one-line pitch:** the `#` title, then one sentence on what it is.
2. **What it does:** a short paragraph or a few bullets, in plain words.
3. **Who it's for:** one short paragraph.
4. **Links:** to deeper docs in the repo (setup, contributing, license).

Draft it from the repo itself (code, existing docs, the product's initiative description). If you can't tell what the product does or who it's for, ask in step 3.

**Public safety:** say what it does and who it's for. Never include secrets, internal URLs, workspace or machine ids, personal data, or client details, unless the client is already public about it.

## 6. Dev ports

Skip this step if step 1 found no dev server. Otherwise do each part that isn't already in place. Never touch the per-machine registry; the script manages it.

1. **Vendor:** copy the `dev-port` beside this file to `scripts/dev-port`, executable. If `scripts/dev-port` exists and differs (`cmp`), replace it: the skill's copy is the canonical one.
2. **Claim early:** make sure `orca.yaml` `scripts.setup` runs `./scripts/dev-port`, so the worktree claims its ports when Orca creates it. If `orca.yaml` is missing, create it with just:

   ```yaml
   scripts:
     setup: ./scripts/dev-port
   ```

   If `scripts.setup` already has a command, chain after it (`<existing> && ./scripts/dev-port`, or a new last line in a block scalar). Never replace it.

3. **Wrap the dev command:** in place when the `dev` script already mentions `scripts/dev-port`. Otherwise prefix the server command so it starts on the workspace's port, passing it the way the server takes one:

   ```sh
   PORT="${PORT:-$(./scripts/dev-port)}" && export PORT && next dev -p "$PORT"
   ```

   Use `vite --port "$PORT"` for Vite, and no flag for a server that reads `PORT` itself. Keep the rest of the command as it was. If the [questions](#3-ask-once) covered the dev command and the user said edit, change that file to take its port from `PORT` and start the `dev` script with the `PORT=…` prefix above. If they skipped, leave it.

## 7. Finish

Say "Looks good, we're set up!". If you wrote anything, add one line naming the files, so the user can review them with `git diff`. Add a few words if dev ports were skipped for having no dev server, or if you replaced a `scripts/dev-port` that had drifted. Nothing else.

## Template

Slots are `{{…}}`. Fill them from Linear; everything else is copied exactly, including the `<…>` placeholders in the comment shape and pull request lines. Where a slot is a table row or list item, repeat it for each match, in the order given.

- `{{workspace}}`, `{{team}}`, `{{KEY}}`: the workspace name, team name and team key.
- **Issue status rows:** one row per team status, in workflow order, using the meaning from this table. A status not in it gets the meaning the user gave in step 3.

  | Status        | Meaning                                                                                                                      |
  | ------------- | ---------------------------------------------------------------------------------------------------------------------------- |
  | `Triage`      | Captured, not yet reviewed. Default for new issues.                                                                          |
  | `Backlog`     | In a map but not ready yet.                                                                                                  |
  | `Todo`        | Ready. Blockers still decide whether work can start.                                                                         |
  | `In Progress` | Claimed, including draft PRs.                                                                                                |
  | `In Review`   | PR out of draft and ready to merge. A draft PR stays `In Progress`. Set only by Linear's GitHub automation, never by agents. |
  | `Done`        | Decision resolved, or PR merged.                                                                                             |
  | `Canceled`    | Declined or won't do.                                                                                                        |
  | `Duplicate`   | Duplicate of another issue.                                                                                                  |

- `{{decision labels}}`: the team's `wayfinder:` labels that exist, in this order: `wayfinder:research`, `wayfinder:grilling`, `wayfinder:prototype`, `wayfinder:task`. Each in backticks, comma-separated.
- `{{retired labels}}`: in this order, comma-separated: the retired labels among `ready-for-agent`, `ready-for-human`, `needs-triage`, `needs-info`, `wontfix`, `wayfinder:map` (in that order); then each retired label group as "the `<name>` group"; then retired Dispatch target labels, alphabetically, as "and the `A`, `B` and `C` dispatch targets".
- `{{template}}`: the one team issue template whose name or description says "implementation", as `` `<name>` (team-scoped) `` or `` `<name>` (workspace) ``. If the team has no issue templates, write `None. Agents write implementation issues without a Linear template` and don't ask. If none matches or several do, use the user's answer from step 3: the template they picked, or the `None` line.
- `{{tool stack}}`: the Linear document titled exactly `Tool Stack`, as `[Tool Stack](<url>)`. If there is none, write `None yet` and don't ask.
- **Dispatch target rows:** one row per active label in the Dispatch target group, in this table's order, then any others with the meaning the user gave in step 3.

  | Label           | Use it when                                                                      |
  | --------------- | -------------------------------------------------------------------------------- |
  | `Orca`          | Dispatched from Orca, including Cursor Cloud agents it launches                  |
  | `Claude`        | Claude Code outside Orca                                                         |
  | `Codex`         | Codex outside Orca                                                               |
  | `Linear/Cursor` | Cursor Cloud, delegated from Linear. Legacy; retired when Factory Dispatch ships |

- `{{orca rule}}`: if there is an `Orca` label, ": a session with any `ORCA_*` environment variable set is `Orca`, and Orca sets the label itself on the Cursor Cloud agents it launches"; otherwise nothing.
- `{{default target}}`: `Orca` if that label exists; otherwise the user's answer in step 3.

The model table and its Checked date are the factory's curated pick. Copy them as they are; step 3 handles models a vendor has dropped.

```markdown
# Issue tracker

This is {{workspace}}'s config; to adopt, copy it and replace the values.

**Setup version:** 2026-10-25

The skills hold the procedure. This file holds only the values they look up, under the headings below. Keep the headings stable: skills cite them by name.

## Tracker

- **Tool:** Linear, workspace **{{workspace}}**.
- **Access:** Linear MCP only. In an Orca workspace, the `orca linear` CLI also qualifies.

## Team

- **Name:** {{team}}
- **Key:** `{{KEY}}` (issue ids look like `{{KEY}}-<number>`)
- **Scope:** the one team holds every product and company issue.

## Issue statuses

| Status        | Meaning                                                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------- |
{{issue status rows}}

## Project statuses

| Status      | Meaning                                                                       |
| ----------- | ----------------------------------------------------------------------------- |
| `Uncharted` | Stub map from triage, not yet charted                                         |
| `Idea`      | Charted with a Destination; decisions still open, nothing sliced              |
| `Planned`   | Enough decisions made that implementation issues are sliced or ready to slice |
| `Ongoing`   | Work has started                                                              |
| `Done`      | Destination reached                                                           |
| `Won't Do`  | Abandoned                                                                     |

## Priority

Not used. Leave every issue at **No priority**.

## Labels

- **Product** (group, single-select): the product an issue belongs to; matches its initiative.
- **Dispatch target** (group, single-select): the tool doing the work. See [Dispatch targets](#dispatch-targets).
- **Bug:** a concrete defect. A Triage item without it is a muse.
- **Decision types:** {{decision labels}}.
- **Retired, never apply:** {{retired labels}}. Any other label with `retiredAt` is retired too.

## Templates

- **Implementation issues:** {{template}}.

## Tool stack

A Linear document lists the services {{workspace}} uses. **(default)** marks the one new products use when a row offers a choice. A linked service has its own page with setup details. Read it before choosing infrastructure for a product.

- **Document:** {{tool stack}}.

## Initiatives

Each product has an initiative with the same name as its Product label. Its description opens with a `Repo:` line; see [Repo routing](#repo-routing). Company work has no product initiative.

## Repo routing

- **Source:** each product initiative's description opens with exactly `Repo: owner/name`, or `Repo: none` for a product with no repo yet. Several products may share a repo. This is the only product-to-repo mapping.
- **On the issue:** a `` `[repo=owner/name]` `` tag in the issue description, written as a code span. Linear escapes bare brackets to `\[repo=…\]`, which also counts. It is the same syntax Cursor's Linear integration reads, and it overrides everything else.
- **Lookup:** Product label → the initiative with the same name → its `Repo:` line. One hop; never inferred from anything else.
- **Cross-check:** PRs already linked to other issues of the same product. A mismatch stops the work.
- **Unresolved:** no tag and `Repo: none` (or no `Repo:` line). There is no default repo.

## Dispatch targets

| Label           | Use it when                                                                      |
| --------------- | -------------------------------------------------------------------------------- |
{{dispatch target rows}}

The label records where the work was dispatched from, not where the session runs or which model ran. Set it when work starts{{orca rule}}. The issue's Suggested dispatch line is the plan; the label records what actually ran.

**Default target:** `{{default target}}`, for every model below.

## Preferred models

**Checked:** 2026-10-25, against the vendor pages under Sources. Re-check when this date is over 90 days old or a listed model retires.

| Model            | Use it for                                                                     |
| ---------------- | ------------------------------------------------------------------------------ |
| Claude Opus 5.5  | Judgment-heavy, cross-cutting or ambiguous work; the maintainer in the session |
| Claude Fable 5.1 | Long-horizon or hardest work, when Opus 5.5 at higher effort falls short       |
| GPT-6 Astra      | Hardest end-to-end work in Codex, when GPT-6.1 Sol falls short                 |
| GPT-6.1 Sol      | Complex implementation and agentic work                                        |
| GPT-6 Luna       | Focused, pattern-following tickets where a good result is clear                |
| Composer 2.5     | Mechanical changes, as a Cursor Cloud agent                                    |
| Grok 4.7         | Mechanical changes, as a Cursor Cloud agent                                    |

**Sources:**

- Claude: <https://platform.claude.com/docs/en/about-claude/models/overview>
- Codex: <https://learn.chatgpt.com/docs/models>
- Cursor: <https://cursor.com/docs/models>

## Views

The factory expects exactly these shared views on the `{{KEY}}` team. Keep them, and find them by exact name with `list_custom_views`.

| View                  | Kind     | Filters                                                                                                                                       |
| --------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `Factory: Maps`       | Projects | Project status not `Done` or `Won't Do`; grouped by initiative (product), sub-grouped and ordered by project status                           |
| `Factory: Decisions`  | Issues   | Status `Todo`, no assignee, not blocked, a `wayfinder:` label, in a project                                                                   |
| `Factory: Ready`      | Issues   | Status `Todo`, no assignee, not blocked, no `wayfinder:` label; grouped by Product, then project                                              |
| `Factory: Agent Work` | Issues   | Status `In Progress` or `In Review`, and either delegated to an agent or carrying a `Dispatch target` label; grouped by Product, then project |
| `Factory: All Work`   | Issues   | Status `In Progress` or `In Review`                                                                                                           |

## Triage

- **Queue:** every `{{KEY}}` issue in `Triage`, across all products.
- **Look-back:** survey Done and Canceled issues from the last 90 days.

## Comment shape

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
- **Kickoff prompt:** a fenced `text` block reading `To kick this off, run /do-implement {{KEY}}-<number>`

## Pull requests

- **Title:** a plain imperative subject ending with the issue id in parentheses, like `Fix the login redirect bug ({{KEY}}-<number>)`.
- **Branch:** exactly the issue's Linear branch name (`gitBranchName` from `get_issue`). Never invent or prefix one.
- **Review:** no PR autopilot in this repo. PRs open as drafts; the maintainer marks them ready and merges.
```
