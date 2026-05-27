# Agentd Reference

## Goal

Document the observed runtime model for remote Windows execution under `agentd.exe`.

## Startup Model

Current `winagent-agentd` behavior:

- loads `agent.yaml` from the current working directory
- defaults `dataRoot` to `data`
- defaults `tasksFile` to `tasks.yaml`
- starts a local HTTP API on `127.0.0.1:47831` unless configured otherwise
- optionally loads initial tasks from `tasks.yaml`
- optionally establishes SSH tunnels when SSH and `controlApiBaseUrl` are configured

If you launch `agentd.exe` from the wrong working directory, it may fail to find `agent.yaml` or `tasks.yaml`.

## Agent Config Schema

Current `agent.yaml` fields:

- `agentId`
- `dataRoot`
- `tasksFile`
- `controlApiBaseUrl`
- `localApi.bindAddress`
- `localApi.port`
- `ssh.serverAddr`
- `ssh.username`
- `ssh.privateKeyPath`
- `ssh.privateKeyPassphrase`
- `ssh.remoteBindHost`
- `ssh.remoteBindPort`
- `ssh.tunnels[]`

Current explicit tunnel fields:

- `name`
- `mode`: `local` or `remote`
- `localBind`
- `remoteTarget`
- `remoteBind`
- `localTarget`

If `ssh.tunnels` is omitted, `agentd.exe` can derive two default tunnels:

- `agentapi` remote tunnel from `ssh.remoteBindHost` + `ssh.remoteBindPort`
- `controlapi` local tunnel when `controlApiBaseUrl` is a loopback URL with an explicit port

## Remote Task Model

The remote agent consumes an `agent-task.yaml` that describes:

- `taskId`
- `displayName`
- `packageName`
- `version`
- `workDir`
- `command`
- `args`
- `env`
- `logDir`
- `stopMode`

Example fields appear in `skills/it-runner-agentd-control/assets/deskwin-winagent-template/agent-task.yaml:1`.

Current validation is intentionally small:

- `taskId` is required
- `command` is required

This means business repos should impose stricter conventions than the runtime does.

## Supported Variable Expansion

Current expansion support is limited to these variables inside the remote spec:

- `${AGENT_DATA}`
- `${TASK_ID}`
- `${TASK_LOG_DIR}`

Expansion applies to:

- `logDir`
- `workDir`
- `args[]`
- `env.*`

Do not assume arbitrary `${VAR}` expansion. Unsupported variables fail task application.

## Local Agent API

Current agent-local routes:

- `GET /v1/agent/info`
- `GET /v1/agent/status`
- `GET /v1/agent/capabilities`
- `GET /v1/agent/fs/stat?path=...`
- `GET /v1/agent/fs/list?path=...`
- `GET /v1/agent/fs/read?path=...`
- `PUT /v1/tasks/{taskId}`
- `GET /v1/tasks/{taskId}`
- `POST /v1/tasks/{taskId}/start`
- `POST /v1/tasks/{taskId}/stop`
- `POST /v1/tasks/{taskId}/restart`
- `GET /v1/tasks/{taskId}/status`
- `GET /v1/tasks/{taskId}/logs`

`controlapi` proxies only the task and fs routes, not the raw `/v1/agent/...` paths.

## Observed Runtime States

The current polling logic already treats these states as meaningful:

- `starting`
- `downloading`
- `installed`
- `running`
- `stopping`
- `stopped`
- `idle`
- `failed`

Operational meaning used by current automation:

- continue polling for `starting`, `downloading`, `installed`, `running`, `stopping`
- fail the local task on `failed`
- treat `stopped` and `idle` as terminal success states unless the business scenario says otherwise

If future versions of `agentd.exe` add or rename states, update this file and the polling logic together.

Current state transitions are driven by the service layer:

- `idle` after first task registration
- `downloading` before package fetch and install
- `installed` after package install succeeds
- `starting` before process start
- `running` after process start succeeds
- `stopping` during explicit stop
- `stopped` after process exit or successful stop
- `failed` after package, start, or wait failure

## Execution Expectations

- package files are downloaded or resolved by package name
- the command runs inside `workDir`
- stdout or captured log lines should become readable via `task logs`
- task-level environment values come from `agent-task.yaml`

Current implementation details that matter operationally:

- the process is launched directly with `exec.CommandContext`, not through a shell
- if you need shell semantics, use an explicit shell command such as `cmd.exe /c ...`
- remote env vars are appended to the current process environment
- `stdout.log` and `stderr.log` are created under `logDir`
- `task logs` returns an in-memory ring buffer, not the entire historical log set
- current ring buffer depth is `200` lines

## Package Install Layout

Current package manager behavior for a task `<taskId>` and version `<version>`:

- downloads zip to `dataRoot/tasks/<taskId>/downloads/<version>-<packageName>`
- extracts into `dataRoot/tasks/<taskId>/packages/<version>/`
- copies that version into `dataRoot/tasks/<taskId>/current/`
- overlays persistent UI files from `dataRoot/tasks/<taskId>/ui/` onto `current/ui/` when present

This overlay behavior is why some tasks can preserve a manual or separately deployed `ui/` bundle across package updates.

## Stop Behavior

Current implementation detail:

- `StopTask` kills the process directly
- `stopMode` exists in the spec but is not currently interpreted by the process runner

Treat `stopMode` as future-facing metadata unless the runtime implementation changes.

## Capabilities

Current `agentd.exe` capabilities exposed through the API are:

- `taskApply`
- `taskLifecycle`
- `taskLogs`
- `packageInstall`
- `fsReadOnly`
- `logStreaming: false`
