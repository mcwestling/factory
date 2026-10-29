# Research: how can Orca launch a Cursor Cloud agent? (DO-1357)

**Date:** 2026-10-29
**Ticket:** [DO-1357](https://linear.app/mcwestling/issue/DO-1357) on the Factory Dispatch map
**Checked locally (read-only):** Orca CLI 1.4.242 (`orca --help`, `orca agent launch --help`, `orca agent-context --json`, `orca skills get orca-cli`), Cursor CLI `agent` 2026.10.22 (`agent --help`, `agent worker --help`, `agent models`). No agent was launched and nothing was spent.

## Answer

- **Use the Cursor Cloud Agents API v1 (`POST https://api.cursor.com/v1/agents`), called from a small Orca-side script.** It is the only surface that takes repo, starting branch, model, prompt and PR behaviour as parameters [C1].
- **The branch can be exactly the issue's `gitBranchName`, but only in one way.** Create that branch on GitHub first, then launch with `repos[0].startingRef = <gitBranchName>` and `workOnCurrentBranch: true`. With the default `false`, Cursor always pushes to a new `cursor/...` branch, and the API has no field to name the output branch [C1].
- **The Cursor CLI isn't a launcher.** Its only cloud path is typing `&` before a message in an interactive session, which hands the conversation off to a Cloud Agent. It has no flags for repo, branch or model [C2]. `agent --help` shows no cloud flag. `agent worker` does the reverse: it runs a cloud agent's tool calls on your own machine.
- **Orca has no Cursor Cloud support.** `orca agent launch --agent cursor` runs the local Cursor CLI in a terminal or chat. Nothing in the CLI, its bundled skill or its docs reaches Cursor's cloud. The only reference upstream is an open proposal for a multi-provider "cloud task" workflow, Qoder first, that names Cursor as a later target [O1].
- **Follow and steer in Cursor's own surfaces, not Orca.** The agent's `url` opens it at cursor.com/agents. The same agent shows up in the Cursor iOS app (push notifications, live follow-ups) and the Android PWA [C3][C4]. Orca can still watch and steer through the API (run status, SSE stream, `delivery: "steer"`), but only if someone builds that UI.
- **Detect the PR the DO-1282 way, unchanged.** The PR opens from `andrew/do-…`, a branch containing the issue id, so Linear's GitHub integration attaches it to the issue, and the existing attachment poll finds it. The API also returns the PR directly in `git.branches[].prUrl` [C1], which works as a cross-check or a fallback.

## How a launch would look

1. Resolve the repo as `docs/issue-tracker.md` already says (the `[repo=…]` tag, else the Product initiative's `Repo:` line). Read `gitBranchName` from `get_issue`.
2. Create the branch if it's missing: `gh api repos/<owner>/<name>/git/refs -f ref=refs/heads/<gitBranchName> -f sha=<default-branch sha>`.
3. Launch:

   ```json
   POST https://api.cursor.com/v1/agents
   {
     "prompt": { "text": "<issue prompt>" },
     "model": { "id": "composer-2.5" },
     "repos": [{ "url": "https://github.com/<owner>/<name>", "startingRef": "<gitBranchName>" }],
     "workOnCurrentBranch": true,
     "autoCreatePR": true,
     "name": "ABC-123 <title>"
   }
   ```

   The response returns `agent.id` (`bc-…`), `agent.url` and `run.id` [C1].
4. Set the `Orca` dispatch label and add `agent.url` to the issue as a link, so a tap opens the agent on any device.
5. Poll the issue's attachments for the PR (DO-1282). Optionally read `GET /v1/agents/{id}` and the run for status and `git.branches[].prUrl`.

## Each question

| Question | Answer | Source |
| --- | --- | --- |
| Which surface? | Cloud Agents API v1 (public beta). The TypeScript and Python SDKs wrap it (`Agent.create({ cloud: {…} })`, same `CURSOR_API_KEY`). The CLI only offers interactive `&` handoff. | [C1][C2][C5] |
| Repo | `repos[0].url`, any repo on a connected provider. | [C1] |
| Branch | `startingRef` plus `workOnCurrentBranch: true` pushes to that branch. Default `false` gives `cursor/...`. No output-branch field. | [C1] |
| Model | `model.id`, with valid values from `GET /v1/models`. The local CLI lists `composer-2.5` and `grok-4.7-{low,medium,high,xhigh}[-fast]`. Confirm the cloud ids with `/v1/models` before hard-coding them. | [C1], `agent models` |
| Prompt | `prompt.text` (required), plus up to 5 images. `mode: "plan"` is optional. | [C1] |
| Auth | Basic (`-u KEY:`) or Bearer, with a **user API key** from Dashboard → API Keys or a team service-account key. Team API keys aren't accepted. | [C1][C6] |
| Follow from Orca | Agent `status` (`ACTIVE`/`IDLE`/`ARCHIVED`). Run `status` goes from `CREATING`/`RUNNING`/`WAITING_FOR_BACKGROUND_WORK` to `FINISHED`/`ERROR`/`CANCELLED`/`EXPIRED`. SSE `GET /v1/agents/{id}/runs/{runId}/stream` emits `status`, `assistant`, `tool_call`, `result` and more. v1 has no webhooks yet; legacy v0 has `statusChange` webhooks on `FINISHED`/`ERROR`. | [C1][C7] |
| Steer | `POST /v1/agents/{id}/runs` starts a follow-up (`409 agent_busy` while a run is active). Adding `delivery: "steer"` injects the prompt into the running turn. That can return `403 feature_unavailable` on some accounts. | [C1] |
| Mobile | Cursor iOS app or the cursor.com/agents PWA: live chat, follow-ups, push notifications, PR review and merge. Orca mobile has nothing here: Orca's mobile Chat UI is "a view over the paired desktop session, not a separate cloud agent". | [C3][C4][O2] |
| PR detection | Linear attachment poll (DO-1282), since the branch carries the issue id. `git.branches[].prUrl` comes straight from the API. | [C1] |
| Rate limit | Cloud Agents endpoints say "standard rate limiting"; the API default is 20 requests/min. | [C6] |
| Cost | Plan usage at the model's token rate, no separate API fee. Composer 2.5 is $0.50 in / $2.50 out per 1M tokens; Grok 4.7 is $2 / $6 (Fast is 2x, long context over 256k is 2x). On legacy request plans: API rate plus the Max Mode upcharge. A spend limit is set on first use. | [C3][C8][C9] |

## Preconditions

- **Paid plan with Cloud Agents:** Premium ($30/mo) or higher, Teams, Enterprise, or a legacy paid plan. Free and Plus ($8) don't include Cloud Agents or the API [C3][C9].
- **Cursor GitHub app** installed on the repo's account or org, and connected to the Cursor account that owns the key, with read-write access [C3][C10].
- **A Cursor user API key** stored on the Orca host. It's a secret, so it stays out of this repo. A cloud environment for the repo (`.cursor/environment.json` or one made in the dashboard) is optional, but without one each agent sets itself up from scratch [C11].
- **`gh` auth** on the Orca host, to create the branch before launch.
- **Unverified, needs one paid trial run:** (a) whether `autoCreatePR: true` opens a PR when `workOnCurrentBranch: true` (the docs don't say); (b) whether `startingRef` must already exist (assume yes, and create it); (c) whether Cursor's PR opens as a draft, as `docs/issue-tracker.md` requires (the API has no draft field). If (a) fails, the prompt can tell the agent to run `gh pr create --draft`, or the dispatcher opens the draft PR itself when the run reaches `FINISHED`.
- **The API is public beta** and "may change before general availability" [C1].

## Not recommended

- Driving the interactive CLI and typing `&` from an Orca terminal: no repo, branch or model control, and nothing comes back that a script can read.
- `agent worker` (My Machines): the agent's tool calls run on the Mac, which defeats the point of a cloud agent for mechanical tickets.
- Building a Cursor cloud viewer inside Orca now: Cursor's web and iOS surfaces already cover following and steering. Wait for upstream Orca's cloud-task work [O1].

## Sources

- [C1] Cursor docs, Cloud Agents API v1 endpoints: https://cursor.com/docs/cloud-agent/api/endpoints
- [C2] Cursor docs, CLI overview ("Cloud Agent handoff"): https://cursor.com/docs/cli/overview
- [C3] Cursor docs, Cloud Agents (plans, billing, surfaces): https://cursor.com/docs/cloud-agent
- [C4] Cursor docs, Cursor for iOS: https://cursor.com/docs/cloud-agent/mobile
- [C5] Cursor docs, TypeScript SDK: https://cursor.com/docs/sdk/typescript
- [C6] Cursor docs, API overview (auth, rate limits, plan per API): https://cursor.com/docs/api
- [C7] Cursor docs, v0 webhooks: https://cursor.com/docs/cloud-agent/api/webhooks
- [C8] Cursor docs, Models and pricing: https://cursor.com/docs/models
- [C9] Cursor pricing: https://cursor.com/pricing
- [C10] Cursor docs, GitHub integration: https://cursor.com/docs/integrations/github
- [C11] Cursor docs, Cloud agent setup: https://cursor.com/docs/cloud-agent/setup
- [O1] stablyai/orca issue #33469, "Qoder Cloud Agents and a reusable multi-provider cloud-task workflow" (open): https://github.com/stablyai/orca/issues/33469
- [O2] stablyai/orca `docs/site/content/docs/mobile.mdx`: https://github.com/stablyai/orca/blob/main/docs/site/content/docs/mobile.mdx
- Local: `orca --help`, `orca agent launch --help`, `orca agent-context --json` (agent ids include `cursor`, a local TUI), `agent --help`, `agent worker --help`, `agent models`.
