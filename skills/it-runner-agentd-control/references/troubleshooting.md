# Troubleshooting

## Fast Checks

Run these checks in order:

1. local binary exists
2. `agentctl` exists and is executable
3. package zip is created where expected
4. package URL is reachable through `controlapi`
5. `agent ping` succeeds
6. `task apply` succeeds
7. `task status` changes after restart
8. `task logs` returns data

## Recommended Evidence Collection

Before changing code, try to collect all of these:

- `agentctl-ping.json`
- `agentctl-apply.json`
- `agentctl-restart.json`
- `agentctl-status.json`
- `agentctl-logs.json`
- local packaged zip path
- remote `stdout.log` and `stderr.log` if accessible through `fs read`

When possible, debug from recorded JSON and remote files instead of rerunning blindly.

## Common Failures

### `agentctl` missing or not executable

Symptoms:

- local task fails before remote activity starts

Check:

- `AGENTCTL_BIN`
- current `it-runner` build artifacts
- executable bit on the binary

The current example explicitly treats this as a prereq failure.

### Windows package not found

Symptoms:

- local package build succeeds
- remote apply or restart later fails

Check:

- package output directory
- package name in `agent-task.yaml`
- expected served URL `${WINAGENT_CONTROLAPI_BASE_URL%/}/packages/$PACKAGE_NAME`
- whether `controlapi` is actually serving the same working-directory `packages/` tree you wrote into

Remember that `winagent-controlapi` serves the relative `packages/` directory from its own process working directory.

### `task apply` fails immediately

Symptoms:

- `agentctl task apply` fails before remote restart happens

Check:

- local `agent-task.yaml` exists
- file extension is `.yaml`
- `taskId` is present in the YAML
- only supported variables are used: `${AGENT_DATA}`, `${TASK_ID}`, `${TASK_LOG_DIR}`
- `taskId` implied by `--task-dir` matches the intended remote task

Because `agentctl` loads the YAML locally first, some failures never reach the remote agent.

### Remote task never becomes `running`

Symptoms:

- status oscillates or stalls in transitional states

Check:

- `task apply` response JSON
- `task status` JSON snapshots
- package contents
- remote `workDir`, `command`, and `logDir`
- whether `command` requires shell semantics but was configured as a raw executable

Important current runtime behavior:

- the agent runs `command` directly
- it does not automatically wrap commands in `cmd.exe`

If your task is effectively a shell snippet, convert it to an explicit `cmd.exe /c ...` command.

### Remote logs empty

Symptoms:

- status changes but `task logs` returns empty or incomplete lines

Check:

- remote program really writes to stdout or configured logs
- `logDir` is valid on Windows
- local follow loop is preserving the latest `agentctl-logs.json`
- whether you are expecting more than the current in-memory ring buffer depth

Remember that `task logs` returns the live in-memory ring buffer, while the agent also writes `stdout.log` and `stderr.log` under `logDir`.

### Stop or restart semantics look wrong

Symptoms:

- task stops abruptly
- `stopMode` appears ignored

Check:

- current runtime implementation still kills the process directly
- the business task tolerates kill-style shutdowns

At the moment, `stopMode` is not meaningfully interpreted by the process runner, so graceful-stop assumptions are unsafe.

### Agent is listed but task proxy calls fail

Symptoms:

- `agent list` or `agent info` works
- task status, logs, or fs requests fail

Check:

- agent registration freshness
- registered `proxyBaseUrl`
- SSH remote bind for the agent-local API
- whether the agent-local API is actually listening on the expected port

`controlapi` synthesizes list/info responses, but task and fs operations still depend on a working proxy path to the agent-local API.

### Placeholder web bundle packaged accidentally

Symptoms:

- desktop shell starts but business UI is missing or wrong

Check:

- whether `web.zip` is a placeholder shell bundle
- whether the task should package an external business web bundle instead

The current `sdkapptunnel` helper already guards against a known placeholder bundle pattern.

## Local `.it-runner` Control

If the outer local task defines `watch.stateFile`, use the normal `.STATE` control rules from `skills/it-runner-workflow/SKILL.md:1` for restarting or stopping the local orchestrator task.

Remember this is separate from the remote Windows process lifecycle.
