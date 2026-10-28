# Research: how heavy is CI-agnostic support? (DO-1393)

**Date:** 2026-10-28
**Ticket:** [DO-1393](https://linear.app/mcwestling/issue/DO-1393) on the [Factory Verify](https://linear.app/mcwestling/project/factory-verify-00114d9892fe) map
**Opal sources read:** `docs/runbooks/feature-pr-ci.md`, `.github/workflows/{feature-pr-check,agent-pr-autopilot,preview-smoke-gate}.yml`, `infra/cli/shared/{agent-pr-autopilot,verification-policy}.mjs` (Opal at `6fb7af80`)

## Answer

- **Keep GitHub Actions as the only CI for now.** Build only the seam that costs almost nothing:
  1. The check runner core is CI-neutral. It takes base and head SHAs as arguments and writes JSON to stdout. It never reads `GITHUB_*`.
  2. Autopilot finds required checks by name, from any source.
- **Autopilot stays on GitHub Actions even if checks run elsewhere.** Autopilot reacts to GitHub events: PR opened, labeled, or pushed; a commit status posted; a push to `main` that might make other PRs conflict. Only Actions gets all of those events. Every other CI gets only a subset.
- **The main-branch full run moves easily.** Every CI listed can build on a push to the default branch. Once the core is CI-neutral, moving it means writing that CI's config file and adding two secrets: a GitHub token and a Linear key.
- **The iMac needs no seam at all.** A self-hosted GitHub Actions runner on the iMac is still GitHub Actions: same workflows, same `GITHUB_TOKEN`, same check runs, and the runner is free. The likely first reason to leave hosted Actions is macOS minutes for `xcodebuild`, and this covers it.
- **Don't build now:** per-CI adapters, a provider interface, CI config generators, or per-CI log scraping for hand-back prompts. Add them only when a repo actually adopts another CI.

## What in Opal's stack depends on GitHub Actions, and what depends only on GitHub

Most of the coupling is to GitHub as the code host. The PR, label, comment, status, and ready-for-review calls are plain REST and GraphQL calls. They work the same from any machine that holds a token. The Actions-specific part is small and easy to list.

### Actions-specific (would change on another CI)

| Coupling | Where in Opal | Note |
| --- | --- | --- |
| Triggers: `pull_request`, `pull_request_target`, `push`, `workflow_run`, `status`, `workflow_call`, `workflow_dispatch` | the three workflow YAMLs | The event fan-in is what autopilot depends on (see below) |
| Draft and agent-branch guard on `ci` | `feature-pr-check.yml` job `if:` | Re-expressed in each CI's own syntax |
| Reading the event and writing step outputs | `verification-policy.mjs:88` (`GITHUB_EVENT_PATH`), `:97` (`GITHUB_OUTPUT`) | **The seam:** take SHAs in, write JSON out |
| Only counts `ci` when the GitHub Actions app produced it | `agent-pr-autopilot.mjs:78` (`run.app.slug === "github-actions"`) | **The seam:** look up by name from any source, or from a configured app |
| Hand-back error extraction from job logs | `agent-pr-autopilot.mjs:763-767` (`actions/jobs/{id}`, `/logs`), `:31` (`/home/runner/work/` path prefix) | Actions-only nicety; on other CIs, fall back to linking `details_url` |
| Re-running a cancelled `ci` | `agent-pr-autopilot.mjs:864` (`actions/runs/{id}/rerun`) | Actions-only; other CIs re-run through their own API |
| Starting the smoke gate | `agent-pr-autopilot.mjs:820` (`actions/workflows/preview-smoke-gate.yml/dispatches`) | Stays on Actions, because autopilot stays on Actions |
| Step summary and run URL | `agent-pr-autopilot.mjs:841`, `:923` | Cosmetic |
| `GITHUB_TOKEN` and its recursion rule | `workflow_call` workaround in `agent-pr-autopilot.yml` | Events caused by `GITHUB_TOKEN` don't start new runs, except `workflow_dispatch` and `repository_dispatch` ([GitHub: GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)) |

### GitHub-the-code-host (same whatever runs the job)

These are listing PRs and their files, polling `mergeable`, finding PRs by commit (`commits/{sha}/pulls`), creating, adding, and removing the `ready-to-merge` label, posting and reading issue comments, the `markPullRequestReadyForReview` GraphQL mutation (`agent-pr-autopilot.mjs:896`), posting and reading commit statuses, reading check runs, and required checks in the branch ruleset. None of this changes. What changes outside Actions is the token. There's no `GITHUB_TOKEN`, so the job needs a GitHub App installation token or a PAT (see Preconditions).

## Why autopilot stays on Actions

Autopilot listens for five things: PR events, including on conflicting PRs where `pull_request` workflows never run (`pull_request_target`); `ci` finishing (`workflow_run`); a Railway or smoke status landing (`status`); every push to `main`, which re-checks all eligible PRs for new conflicts; and manual re-runs. Actions receives all of these. `status`, `check_run`, `check_suite`, and `workflow_run` workflows must live on the default branch. GitHub Actions suppresses `check_run` and `check_suite` events for suites it created itself ([GitHub: events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)).

Statuses from an external CI's app are not caused by `GITHUB_TOKEN`, so they **do** trigger an Actions `status` workflow. An Actions-hosted autopilot can therefore wait on checks that Buildkite or CircleCI report. The reverse doesn't hold. None of the other CIs below receive GitHub `status` events, so an autopilot hosted on them would need its own webhook receiver or a poller. That makes the comparison lopsided: moving checks is cheap, moving autopilot isn't.

Autopilot's own runtime is small: one `ubuntu-latest` job with `timeout-minutes: 5` per event.

## Comparison

| | Self-hosted GitHub Actions runner (iMac) | Buildkite | CircleCI | GitLab CI (for a GitHub repo) |
| --- | --- | --- | --- | --- |
| **How a run starts** | Same workflows, `runs-on: [self-hosted, macOS]` | Buildkite GitHub App plus a repo webhook (pushes, PRs, merge groups, deployments). Per-pipeline switches cover PR opened or updated, ready for review, labels changed, converted to draft, and skipping closed PRs. Labels can be filtered with `build.pull_request.labels` ([Buildkite: GitHub](https://buildkite.com/docs/pipelines/source-control/github)) | GitHub App triggers: push to default branch, PR opened, non-draft PR opened, PR marked ready, `run-ci` label added, pushes to non-draft PRs, and others. Trigger options can't be combined in one trigger. Fork PRs never trigger ([CircleCI: trigger options](https://circleci.com/docs/guides/orchestrate/github-trigger-event-options/)) | **Premium or Ultimate only.** Pull mirroring plus a GitHub webhook that starts the mirror. External-PR pipelines exist, but fork PRs are ignored, a push to a branch with an open PR creates two pipelines, and draft and label handling are not documented ([GitLab: GitHub integration](https://docs.gitlab.com/ci/ci_cd_for_external_repos/github_integration/), [external repos](https://docs.gitlab.com/ci/ci_cd_for_external_repos/)) |
| **How results reach GitHub** | Check runs from the `github-actions` app, same as today | Commit statuses ([Buildkite: GitHub](https://buildkite.com/docs/pipelines/source-control/github)) | Commit statuses per job by default, and optionally Checks per workflow through the CircleCI Checks app. App-based check names append part of the pipeline definition ID, which matters for required-check names ([CircleCI: status updates](https://circleci.com/docs/guides/integration/status-updates/), [enable Checks](https://circleci.com/docs/guides/integration/enable-checks/)) | Commit statuses, using a PAT with `repo` scope ([GitLab: GitHub integration](https://docs.gitlab.com/ci/ci_cd_for_external_repos/github_integration/)) |
| **Reading or changing PR state** (draft/ready, labels, comments) | `GITHUB_TOKEN`, unchanged | Nothing built in. The job calls the GitHub API with a token stored as a secret | Nothing built in. Same as Buildkite | Nothing built in. Same as Buildkite |
| **Work to adopt** | Install the runner as a service and change `runs-on`. No code | A pipeline YAML, the seam, and a GitHub token secret | Same as Buildkite | Same, plus Premium and keeping the mirror healthy |
| **Cost** | Free; see the self-hosted fee note under Preconditions | Free plan: 5 users, 10 concurrent self-hosted jobs, 2,000 hosted Linux vCPU-minutes, no hosted macOS. Pro: $30 per active user per month. Hosted macOS M4 costs $0.12/min ([Buildkite pricing](https://buildkite.com/pricing)) | Free plan: 30,000 credits a month (Linux Medium uses 10 credits/min, so about 3,000 minutes), 5 users, 1 concurrent macOS job, self-hosted runners included. Performance plan from $15/month ([CircleCI pricing](https://circleci.com/pricing/)) | Premium: $29 per user per month, billed annually. The Free plan's 400 compute minutes don't help, because external repos need Premium ([GitLab pricing](https://about.gitlab.com/pricing/)) |

For context on cost: hosted GitHub Actions includes 2,000 private-repo minutes a month on Free and 3,000 on Pro or Team. A macOS 3–4 core hosted runner costs $0.062/min. Self-hosted runner usage is free ([GitHub: Actions billing](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions)).

## The smallest seam

1. **CI-neutral core.** Today `verification-policy.mjs --github` reads `GITHUB_EVENT_PATH` and writes `GITHUB_OUTPUT`. Factory's version should work like this:
   - `plan --base <sha> --head <sha>` returns the triggered checks as JSON.
   - `run <check>` runs one check.
   - `run --all` runs every check, for the main-branch full run.
   - Reporting a miss takes the merge SHA and the triggered plan. It files the Linear Triage issue for any failed check the PR didn't trigger.

   The GitHub Actions workflow is a thin adapter: about ten lines that map the event to SHAs and the JSON to step outputs. Local preflight already calls the core with no CI at all, so this split costs nothing extra.
2. **Find checks by name, from any source.** Autopilot reads each required check by the name the repo declares. It accepts either a check run or a commit status with that name. It drops the `app.slug === "github-actions"` filter, or makes the app a per-repo setting. The Actions-only extras (log extraction, re-running a cancelled run, dispatching the smoke workflow) run only when the result came from `github-actions`. Otherwise the hand-back prompt links `details_url`. Opal already handles Railway's `Opal - web` this way: a status read by name.

Adding another CI later is then a config file for that CI that calls the same core, plus a token secret. No interface needs to exist ahead of time.

## Recommendation

- **Build the seam now.** Both parts are ways of writing code Factory Verify has to write anyway, and they take less code than the Actions-coupled versions. Part 2 is a one-line filter change, and it also future-proofs against non-Actions checks such as Railway or Xcode Cloud.
- **Don't build anything else now.** No other factory repo needs another CI today. Every repo is on GitHub, and the plausible need (macOS builds) is met by a self-hosted Actions runner.
- **Revisit when** a repo needs more concurrency or hardware than Actions and the iMac give, or a repo moves off GitHub as its code host. Moving the code host is a different and much larger project, because the code-host list above is the bulk of autopilot.

## Preconditions this answer depends on

- **The code host stays GitHub.** Everything in the code-host list assumes the GitHub REST and GraphQL APIs.
- **Tokens:**
  - Inside Actions, `GITHUB_TOKEN` covers everything autopilot does today.
  - Outside Actions, the job needs a GitHub App installation token or a PAT. Only GitHub Apps can create check runs ([GitHub: check runs](https://docs.github.com/en/rest/checks/runs)). Commit statuses need only push access, or the `repo:status` OAuth scope ([GitHub: commit statuses](https://docs.github.com/en/rest/commits/statuses)).
  - Prefer a GitHub App. It gives short-lived tokens, a bot identity, and can be pinned as a required check's expected source. With a PAT, autopilot's comments come from the user's own account, and @mentions of yourself may not notify you. That last point is unverified; GitHub's docs don't say how self-mentions behave.
- **Branch ruleset.** A required check can be pinned to one GitHub App as its expected source. Then a status from any other source won't satisfy it ([GitHub: ruleset rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)). Moving a check to another CI means editing that ruleset entry, and check names must stay stable. CircleCI's App-based Checks rename them, as noted in the table.
- **Paid plans:**
  - GitHub's included minutes cover hosted Linux at current volume. This is an assumption; measure it before relying on it.
  - Buildkite and CircleCI free plans would work for a single user.
  - GitLab requires Premium at $29 per user per month just to run CI for a GitHub repo.
- **Self-hosted runner fee.** GitHub announced a $0.002/min platform charge for self-hosted runners starting March 1, 2026, then postponed it "to re-evaluate", with no new date ([GitHub changelog, 2025-12-16](https://github.blog/changelog/2025-12-16-coming-soon-simpler-pricing-and-a-better-experience-for-github-actions/)). The billing docs still say self-hosted usage is free. Re-check this before counting on a free iMac runner.
- **iMac hardware and setup:**
  - It must stay on, awake, and online.
  - Run the runner as a service. One runner handles one job at a time; register more runners for parallel jobs.
  - Use it with **private repos only**. Fork PRs on public repos could run code on the machine ([GitHub: add self-hosted runners](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners)).
  - Its CPU architecture (Apple Silicon or Intel) was not checked.
  - Linux-container checks, like Opal's Docker verifier, need Docker Desktop. It is free for personal use and small businesses with fewer than 250 employees and less than $10M in revenue ([Docker licensing](https://docs.docker.com/subscription/desktop-license/)).
  - Secrets live on the machine's disk.
- **Linear.** The main-run miss reporter needs a Linear API key secret in whichever CI runs it. This is the same on every CI.
- **Unrelated to CI:** Cursor ignores `@cursor` mentions from bots, as Opal's runbook already notes. No CI choice changes that.

## Sources

- GitHub: [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token), [events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [check runs API](https://docs.github.com/en/rest/checks/runs), [commit statuses API](https://docs.github.com/en/rest/commits/statuses), [ruleset rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [Actions billing](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions), [self-hosted runners](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners), [pricing changelog](https://github.blog/changelog/2025-12-16-coming-soon-simpler-pricing-and-a-better-experience-for-github-actions/)
- Buildkite: [GitHub integration](https://buildkite.com/docs/pipelines/source-control/github), [pricing](https://buildkite.com/pricing)
- CircleCI: [GitHub trigger options](https://circleci.com/docs/guides/orchestrate/github-trigger-event-options/), [status updates](https://circleci.com/docs/guides/integration/status-updates/), [GitHub Checks](https://circleci.com/docs/guides/integration/enable-checks/), [pricing](https://circleci.com/pricing/)
- GitLab: [CI/CD for GitHub](https://docs.gitlab.com/ci/ci_cd_for_external_repos/github_integration/), [external repos](https://docs.gitlab.com/ci/ci_cd_for_external_repos/), [pricing](https://about.gitlab.com/pricing/)
- Docker: [Desktop license](https://docs.docker.com/subscription/desktop-license/)
