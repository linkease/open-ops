# Deskwin Winagent Run Example

## Canonical Example

Current example project:

- `.it-runner` root: `/projects/workspace-linkease-ubuntu/linkease-github/sdkapptunnel/.it-runner`
- task definition: `/projects/workspace-linkease-ubuntu/linkease-github/sdkapptunnel/.it-runner/projects/apptunnel/tasks/deskwin_winagent/task.yaml`
- remote task payload: `/projects/workspace-linkease-ubuntu/linkease-github/sdkapptunnel/.it-runner/projects/apptunnel/tasks/deskwin_winagent/agent-task.yaml`
- helper library: `/projects/workspace-linkease-ubuntu/linkease-github/sdkapptunnel/.it-runner/projects/apptunnel/scripts/lib_deskwin_winagent.sh`

Use that example as the current golden path until a better generalized template appears.

## Local Task Shape

The local `.it-runner` task does four important things:

- pulls target-specific env from `../../envsets/winagent-targets/${WINAGENT_PROFILE}`
- uses `watch.stateFile` for local task control
- exports `AGENT_TASK_DIR` to the shared helper script
- calls one shared shell entry that packages, applies, restarts, and follows the remote task

Observed wrapper flow inside the helper scripts:

1. validate required envs and binaries
2. package `deskwin.exe` and optional UI assets into `deskwin-winagent.zip`
3. probe the agent with `agentctl agent ping`
4. apply the remote task with `agentctl task apply`
5. restart the task with `agentctl task restart`
6. poll `task status`
7. fetch `task logs`
8. persist JSON outputs and a text log projection under the local task log directory

Key file:

- `/projects/workspace-linkease-ubuntu/linkease-github/sdkapptunnel/.it-runner/projects/apptunnel/tasks/deskwin_winagent/task.yaml:1`

## Remote Payload Shape

The remote payload expresses the Windows-side runtime contract:

- package name: `deskwin-winagent.zip`
- work dir: `data/tasks/deskwin_winagent/current`
- command: `.\\deskwin.exe`
- log dir: `data/logs/deskwin_winagent`

Key file:

- `/projects/workspace-linkease-ubuntu/linkease-github/sdkapptunnel/.it-runner/projects/apptunnel/tasks/deskwin_winagent/agent-task.yaml:1`

## Shared Env Names In The Example

The current sample relies on these envs:

- `WINAGENT_CONTROLAPI_BASE_URL`
- `WINAGENT_AGENT_ID`
- `WINAGENT_DATA_ROOT`
- `WINAGENT_PROFILE`
- `AGENTCTL_BIN`
- `DESKWIN_WINAGENT_PACKAGE_NAME`
- `DESKWIN_WINAGENT_BINARY`
- `DESKWIN_WINAGENT_WEB_ZIP`
- `DESKWIN_WINAGENT_STATUS_WAIT_SECONDS`
- `DESKWIN_WINAGENT_FOLLOW_INTERVAL_SECONDS`
- `DESKWIN_WINAGENT_TRANSIENT_RETRIES`

Task defaults live at:

- `/projects/workspace-linkease-ubuntu/linkease-github/sdkapptunnel/.it-runner/projects/apptunnel/tasks/deskwin_winagent/envs/000-defaults.env:1`

Target selection currently uses:

- `/projects/workspace-linkease-ubuntu/linkease-github/sdkapptunnel/.it-runner/projects/apptunnel/envsets/winagent-targets/local-dev/000-base.env:1`

## Why This Example Matters

This example already demonstrates the full integration chain:

- local packaging
- package publication path
- remote task apply
- remote restart
- status and log follow

It also captures two valuable production rules:

- detect and skip a placeholder `web.zip` instead of silently packaging the wrong UI
- store `agentctl` JSON payloads beside the local task logs so later debugging is evidence-based

Future projects should start from this shape, then simplify only after proving the simpler variant still preserves observability.

## Reusable Patterns To Copy

Patterns in this example that are worth standardizing across repos:

- keep one task-local helper library for package/apply/follow logic
- keep target selection in `.it-runner/envsets/winagent-targets/`
- keep remote `agent-task.yaml` next to the visible `task.yaml`
- write structured outputs such as `agentctl-status.json` and `agentctl-logs.json`
- generate a human-readable `remote-program.log` from the returned log lines
