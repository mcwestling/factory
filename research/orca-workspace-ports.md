# What Orca offers for per-workspace dev-server ports

Research for DO-1362. Checked against Orca 1.4.237 (`orca --version`) on macOS, October 2026.

## Short answer

- **Orca has repo setup and archive hooks** (`orca.yaml` `scripts.setup` / `scripts.archive`) and repo-defined default tabs that can run a command. It has no per-workspace environment-variable settings for terminals.
- **Orca does not allocate ports.** It *discovers* them: it scans listening ports, attributes each to a workspace, lets you stop the process, and can proxy a port behind a `<label>.orca.localhost` URL. Nothing hands a workspace a port before the dev server starts.
- **The stable per-workspace value is the worktree path.** Hook processes get it as `ORCA_WORKTREE_PATH`, with the basename as `ORCA_WORKSPACE_NAME`. Ordinary terminals get neither, but `git rev-parse --show-toplevel` gives the same path anywhere.
- **Opal's approach generalises in part.** The probe-for-a-free-port helper is about 20 lines and fits any repo. The trigger and the wiring are Opal-specific, and the port is not sticky: it can change between runs.

## 1. Orca: hooks and per-repo config

Orca reads `orca.yaml` from the repo root. These are the accepted top-level keys, from the loader's allow-list in the app bundle (`app.asar` → `out/main/index.js`):

| Key | What it does |
| --- | --- |
| `scripts.setup` | Shell script that runs when a worktree is created. It follows the repo's setup policy (`run`, `skip` or `ask`); `orca worktree create --setup run\|skip\|inherit` overrides that. |
| `scripts.archive` | Runs when a worktree is removed, but only with `orca worktree rm --run-hooks`. A failing archive hook blocks removal. |
| `setupAgentStartupPolicy` | Whether an agent waits for setup to finish, e.g. `wait-for-setup`. |
| `defaultTabs` | List of `{ title, command, color }` terminal tabs opened in each new workspace. A tab with `command: pnpm dev` would start a dev server automatically. |
| `issueCommand` | Command run for a linked issue. |
| `environmentRecipes` | Per-workspace *runtime* recipes: a cloud sandbox, VM, SSH host or container created fresh for each workspace. These are lifecycle scripts, not env settings. See `orca skills get orca-per-workspace-env`. |
| `worktree` | Worktree options. |

Sources: `orca --help` and `orca agent-context --json` (the `worktree create`/`worktree rm` entries document `--setup` and `--run-hooks`); `orca skills get orca-cli` (the "Agent/setup flags" section); the bundled `orca.yaml` in Orca's own repo. The app settings can also hold repo-local hook scripts (`hookSettings.scripts`), with `commandSourcePolicy` deciding whether the repo file or the local script wins.

**Env passed to `setup`/`archive` hooks** (function `Zh` in `out/main/index.js`):

```
ORCA_ROOT_PATH       = repo (primary checkout) path
ORCA_WORKTREE_PATH   = this worktree's path
ORCA_WORKSPACE_NAME  = basename of the worktree path
CONDUCTOR_ROOT_PATH  = repo path (Conductor compatibility)
GHOSTX_ROOT_PATH     = repo path
```

There is no `CONDUCTOR_PORT` equivalent; nothing in the bundle sets one.

**Env in ordinary workspace terminals.** There is no per-workspace variable. A shell gets app-level values (`ORCA_APP_VERSION`, `ORCA_USER_DATA_PATH`, `ORCA_ENVIRONMENT`, agent-session ids and so on). `buildTerminalWorkspaceEnv` adds `ORCA_WORKSPACE_ID` and `ORCA_WORKSPACE_ROOT` only for *folder* workspaces, not git worktrees. Recipe lifecycle scripts get `ORCA_WORKSPACE_ID`, `ORCA_WORKSPACE_NAME`, `ORCA_VM_INSTANCE_ID` and others, but only when an `environmentRecipes` entry is in use.

## 2. Orca: ports

Orca has workspace port *management*, not allocation:

- `workspacePorts.scan` / `scanHost` lists listening ports and attributes each one to a workspace. A match on process cwd counts as confidence `cwd`, a match on command line as `command`. Unmatched ports are tagged `container` or `external` (`out/shared/rpc-contract/workspace-ports-params.js`, `_ln` in `out/main/index.js`).
- `workspacePorts.kill` sends SIGTERM to the process that owns a port.
- A localhost label proxy (`localhostWorktreeLabels:register`) listens on a random loopback port. It routes `<label>.orca.localhost` to a workspace's port, adding `-2`, `-3` and so on to labels that clash. It only accepts targets that the scan attributes to a workspace.

So Orca can show and open "whatever port this workspace happens to be on". The repo still has to pick the port. The only port flag in the CLI is `orca serve --port`, which is Orca's own runtime server.

## 3. Stable per-workspace values

| Value | Where available | Stable? | Notes |
| --- | --- | --- | --- |
| Worktree path | Everywhere, via `git rev-parse --show-toplevel`; `ORCA_WORKTREE_PATH` in hooks | Yes, for the workspace's life | The best input. Unique per workspace on a host. |
| Workspace name (path basename) | `ORCA_WORKSPACE_NAME` in hooks; `basename` of the path | Yes | Unique within one repo's workspace folder, but can repeat across repos, so hash the full path. |
| Worktree id | `orca worktree current --json` → `result.worktree.id` / `instanceId` | Yes | Needs the Orca runtime up, so it is a poor fit for a dev script. |
| Branch | git | No | Can be renamed. |

## 4. Prior art: Opal's `pnpm dev`

Opal (private repo `mcwestling/opal`; the Orca support landed in DO-1216, PR #1105):

- `package.json` maps `"dev"` to `node infra/scripts/dev.mjs`.
- `infra/scripts/dev-config.mjs` → `resolveNextPort` picks, in order: `--port` arg, then `CONDUCTOR_PORT` (Conductor *does* allocate ports), then 3000.
- `resolveAvailableNextPort` decides whether this is an Orca worktree: the path contains `/orca/workspaces/` or equals `ORCA_WORKTREE_PATH`. If so, and no port was given explicitly, it calls `findAvailablePort`. That function tries `net.createServer().listen(port, "127.0.0.1")` from 3000 upward and treats `EADDRINUSE`/`EACCES` as busy.
- `dev.mjs` then runs Storybook on the next free port after the Next port and Next.js on the chosen port. It passes Storybook's origin via `OPAL_STORYBOOK_DEV_ORIGIN` so Next can proxy `/storybook`.
- Opal's `orca.yaml` sets `scripts.setup: pnpm bootstrap`, `setupAgentStartupPolicy: wait-for-setup`, and a `Dev` default tab. The setup gives each worktree its own database (`opal_<slug>`). It does not write a port.

**Does it generalise?**

- **The probe generalises.** It is a few lines of stdlib Node with no Opal coupling, and fits any repo's dev script.
- **It is not deterministic.** The port depends on what else is running at that moment, so a workspace can get 3001 today and 3003 tomorrow. That breaks bookmarks, OAuth/webhook callback URLs, and any `.env` that holds a base URL.
- **It is racy.** The probe binds and releases, and the server binds later. Two dev servers starting at the same moment can pick the same port.
- **It detects Orca by path.** Matching `/orca/workspaces/` relies on Orca's default workspace folder, and `ORCA_WORKTREE_PATH` is only set inside hooks, not in the terminal where `pnpm dev` runs.
- **The wiring is Opal-specific.** The Next and Storybook pair, and some code and tests that fall back to `http://localhost:3000`, are Opal's own.

## 5. Options for a cross-repo approach

1. **Hash the path, then probe.** `base + hash(worktree path) % range`, then probe upward from there if that port is taken. It is deterministic in the normal case and safe when two hashes collide. It needs no Orca support and works the same under Conductor and Codex. It falls back to `CONDUCTOR_PORT` when that is set.
2. **Persist the result at setup.** In `scripts.setup`, compute the port as in option 1 and write `PORT=` into the worktree's gitignored `.env.local`. Then the dev script, tests and callback URLs all read the same value, and it never moves. This also fixes the problem of `ORCA_WORKTREE_PATH` being missing in terminals.
3. **Rely on Orca's port scan and `*.orca.localhost` labels** to find whatever port a server landed on. This works today with any port strategy, but it gives no stable URL that other config can point at.

Collisions with a pure hash follow the birthday bound. With 1000 slots and 10 live workspaces the chance of a clash is about 4.4%, so the probe in option 1 is needed rather than optional.

## Sources

- Orca CLI 1.4.237: `orca --help`, `orca agent-context --json`, `orca skills get orca-cli`, `orca skills get orca-per-workspace-env`, `orca worktree current --json` (field names only).
- Orca app bundle `app.asar` (extracted read-only): `orca.yaml`, `out/main/index.js` (`orca.yaml` key allow-list, hook runner `ag`, hook env `Zh`, `buildTerminalWorkspaceEnv`, recipe env, localhost label proxy), `out/shared/rpc-contract/workspace-ports-params.js`, `out/renderer/assets/workspace-port-localhost-label-selector-*.js`.
- Opal `origin/main`: `infra/scripts/dev-config.mjs`, `infra/scripts/dev.mjs`, `orca.yaml`, `.conductor/settings.toml`, `infra/conductor/setup.sh`, `package.json`; commit for DO-1216 (#1105).
