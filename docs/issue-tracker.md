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

A `` `[repo=owner/name]` `` tag in the issue description overrides the Product label. Write it as a code span; Linear escapes bare brackets to `\[repo=…\]`, which also counts.

| Product label       | Repo                                |
| ------------------- | ----------------------------------- |
| Factory             | `mcwestling/factory`                |
| Opal                | `mcwestling/opal`                   |
| Piumosso            | `mcwestling/piumosso`               |
| Domino Night        | `mcwestling/domino-night`           |
| ODOT                | `mcwestling/odot`                   |
| aw.com              | `andrewwestling/andrewwestling.com` |
| Music Library       | `andrewwestling/andrewwestling.com` |
| Timeline            | None yet; needs a tag               |
| No label and no tag | Unresolved; there is no default     |

## Dispatch targets

| Label           | Use it when                                                                    |
| --------------- | ------------------------------------------------------------------------------ |
| `Conductor`     | `CONDUCTOR_WORKSPACE_ID` or `CONDUCTOR_WORKSPACE_PATH` is set (local or cloud) |
| `Orca`          | `ORCA_WORKSPACE_ID`, or any other `ORCA_*` variable, is set                    |
| `Claude`        | Claude Code outside Conductor and Orca                                         |
| `Codex`         | Codex outside Conductor and Orca                                               |
| `Linear/Cursor` | Cursor Cloud, delegated from Linear                                            |
| `Linear/Codex`  | Codex, delegated from Linear                                                   |

Detect the target from the host environment, not the model. Check Conductor first, then Orca.

**Target follows the model:** Cursor models (Composer, Grok) run on `Linear/Cursor`. Claude and GPT models run on `Orca`. **Default target:** a Cursor model on `Linear/Cursor`. `Orca` when the work needs a Claude or GPT model, a local stack, the maintainer in the session, or a tool-specific capability.

## Preferred models

- Claude Opus 5.5
- GPT-5.6 Sol
- GPT-5.6 Luna
- GPT-6 Astra
- Composer 2.5
- Grok 4.6

## Views

Shared views on the `DO` team. Find them by exact name with `list_custom_views`.

| View                   | Shows                                                 |
| ---------------------- | ----------------------------------------------------- |
| `Ready to Dispatch`    | Todo, unassigned, unblocked implementation issues     |
| `Decisions to Resolve` | Todo, unassigned, unblocked decision tickets in a map |
| `Maps to Chart`        | Stub maps (projects) waiting to be charted            |
| `In Progress: All`     | Issues in In Progress or In Review                    |
| `In Progress: Agent`   | In-progress issues delegated to an agent              |
| `By Product/Project`   | Issues grouped by Product, then project               |

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
