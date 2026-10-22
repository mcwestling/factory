# Issue tracker

This is McWestling's config; to adopt, copy it and replace the values.

The skills hold the procedure. This file holds only the values they look up, under the headings below. Keep the headings stable: skills cite them by name.

## Tracker

- **Tool:** Linear, workspace **McWestling**.
- **Access:** Linear MCP only. In an Orca workspace, the `orca linear` CLI also qualifies.

## Team

- **Name:** McWestling
- **Key:** `DO` (issue ids look like `DO-<number>`)
- **Scope:** the one team holds every product and company issue.

## Issue statuses

| Status        | Meaning                                                  |
| ------------- | -------------------------------------------------------- |
| `Triage`      | Captured, not yet reviewed. Default for new issues.      |
| `Backlog`     | In a map but not ready yet.                              |
| `Todo`        | Ready. Blockers still decide whether work can start.     |
| `In Progress` | Claimed, including draft PRs.                            |
| `In Review`   | PR marked ready. Set only by Linear's GitHub automation. |
| `Done`        | Decision resolved, or PR merged.                         |
| `Canceled`    | Declined or won't do.                                    |
| `Duplicate`   | Duplicate of another issue.                              |

## Project statuses

| Status      | Meaning                               |
| ----------- | ------------------------------------- |
| `Uncharted` | Stub map from triage, not yet charted |
| `Idea`      | Charted, not yet planned              |
| `Planned`   | Charted and planned                   |
| `Ongoing`   | Work has started                      |
| `Done`      | Destination reached                   |
| `Won't Do`  | Abandoned                             |

**Standing non-map projects:** Opal Releases.

## Priority

Not used. Leave every issue at **No priority**.

## Labels

- **Product** (group, single-select): routes an issue to its repo. See [Repo routing](#repo-routing).
- **Dispatch target** (group, single-select): the tool doing the work. See [Dispatch targets](#dispatch-targets).
- **Bug:** a concrete defect. A Triage item without it is a muse.
- **Decision types:** `wayfinder:research`, `wayfinder:grilling`, `wayfinder:prototype`, `wayfinder:task`.
- **Retired, never apply:** `ready-for-agent`, `ready-for-human`, `needs-triage`, `needs-info`, `wontfix`, `wayfinder:map`. Imported issues keep `legacy-status:wontfix`.

## Templates

- **Implementation issues:** `Clear issue` (team-scoped).

## Initiatives

Each product has an initiative with the same name as its Product label. Company work has no product initiative.

## Repo routing

Routing lives in Linear, not here. Each Product label's description ends with `→ owner/name`, the repo its issues go to; a label for a product with no repo says so instead. To route a new product, create its Product label with that ending.

A `` `[repo=owner/name]` `` tag in the issue description overrides the label. Write it as a code span; Linear escapes bare brackets to `\[repo=…\]`, which also counts. An issue with neither is unresolved: there is no default repo.

## Dispatch targets

| Label           | Use it when                              |
| --------------- | ---------------------------------------- |
| `Orca`          | Any `ORCA_*` environment variable is set |
| `Claude`        | Claude Code outside Orca                 |
| `Codex`         | Codex outside Orca                       |
| `Linear/Codex`  | Codex, delegated from Linear             |
| `Linear/Cursor` | Cursor Cloud, delegated from Linear      |

Detect the target from the host environment, not the model.

**Default target:** `Orca`, with a Claude or GPT model. `Linear/Cursor` is optional, for Cursor models only.

## Preferred models

| Model           | Target          | Use it for                                                                     |
| --------------- | --------------- | ------------------------------------------------------------------------------ |
| Claude Opus 5.5 | `Orca`          | Judgment-heavy, cross-cutting or ambiguous work; the maintainer in the session |
| GPT-6.1 Sol     | `Orca`          | Complex implementation and agentic work                                        |
| GPT-6 Luna      | `Orca`          | Focused, pattern-following tickets where a good result is clear                |
| Composer 2.5    | `Linear/Cursor` | Mechanical changes, when using Cursor                                          |
| Grok 4.6        | `Linear/Cursor` | Mechanical changes, when using Cursor                                          |

## Views

The factory expects exactly these shared views on the `DO` team. Keep them, and find them by exact name with `list_custom_views`.

| View                  | Kind     | Filters                                                                                                             |
| --------------------- | -------- | ------------------------------------------------------------------------------------------------------------------- |
| `Factory: Maps`       | Projects | Project status not `Done` or `Won't Do`; grouped by initiative (product), sub-grouped and ordered by project status |
| `Factory: Decisions`  | Issues   | Status `Todo`, no assignee, not blocked, a `wayfinder:` label, in a project                                         |
| `Factory: Ready`      | Issues   | Status `Todo`, no assignee, not blocked, no `wayfinder:` label; grouped by Product, then project                    |
| `Factory: Agent Work` | Issues   | Status `In Progress`, delegated to an agent                                                                         |
| `Factory: All Work`   | Issues   | Status `In Progress` or `In Review`                                                                                 |

## Triage

- **Queue:** every `DO` issue in `Triage`, across all products.
- **Look-back:** survey Done and Canceled issues from the last 90 days.
- **Opal scope:** new Opal feature work is in scope; Piumosso replacing Opal one day is not a routing reason.

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
- **Kickoff prompt:** a fenced `text` block

## Pull requests

- **Title:** a plain imperative subject ending with the issue id in parentheses, like `Fix the login redirect bug (DO-<number>)`.
- **Review:** no PR autopilot in this repo. PRs open as drafts; the maintainer marks them ready and merges.
