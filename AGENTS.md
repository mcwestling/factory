# AGENTS.md

Factory holds workflow skills and, later, the code, contracts and configs behind them. See the [README](README.md) for what each skill does.

## Issue tracker

The workspace values the skills read (team, labels, statuses, repo routing, dispatch targets, views, comment shape) are in [`docs/issue-tracker.md`](docs/issue-tracker.md).

## Where things go

The repo is organised by kind of thing. Add a folder only when its first file lands; never commit empty folders.

- **Skills:** `skills/<name>/`, with `SKILL.md` and `agents/openai.yaml`.
- **Shared code:** `packages/<name>/`.
- **Stack packs:** `packs/<name>/`.
- **Tool configs:** `tools/<name>/`.
- **Prose contracts:** `docs/<contract>.md`.
- **Example config and schemas:** `*.example` files and machine-readable schemas sit beside the code that reads them. The real config is gitignored.

## Open source

This repo is built to be published. Never commit secrets, personal data, machine names, workspace ids or relay URLs. Use placeholders such as `ABC-123` for ticket ids, and commit `*.example` files instead of real config.
