# Agentctl Reference

## Goal

Use `agentctl` as the preferred operator and automation surface for remote Windows agent control.

## Command Shape

Current root usage:

- `agentctl [--server URL] [--output text|json] <agent|task|fs> <subcommand>`

Observed defaults:

- `--server` default: `http://127.0.0.1:28080`
- `--output` default: `text`

For automation, prefer `--output json` and pass `--server` explicitly.

## Core Commands

Assume these flags are almost always required:

- `--server "$WINAGENT_CONTROLAPI_BASE_URL"`
- `--output json`
- `--agent-id "$WINAGENT_AGENT_ID"`

Observed commands in the current flow:

- ping agent
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json agent ping --agent-id "$WINAGENT_AGENT_ID"`
- apply task
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task apply --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- restart task
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task restart --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- stop task
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task stop --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- start task
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task start --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- read task spec
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task get --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- inspect status
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task status --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- fetch logs
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task logs --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- list agents
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json agent list`
- read agent info
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json agent info --agent-id "$WINAGENT_AGENT_ID"`
- read capabilities
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json agent capabilities --agent-id "$WINAGENT_AGENT_ID"`
- probe remote files
  - `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json fs stat --agent-id "$WINAGENT_AGENT_ID" --path data/logs/deskwin_winagent/stdout.log`

## Suggested Sequence

Use this order unless there is a clear reason not to:

1. `agent ping`
2. `task apply`
3. `task restart`
4. repeated `task status`
5. repeated `task logs`

This sequence isolates connectivity, task-definition, runtime, and logging failures.

Use `task get` before `task restart` when you need to prove the remote side already holds the expected spec.

## Output Handling

Prefer `--output json` and store the raw responses under the task log directory, for example:

- `agentctl-ping.json`
- `agentctl-apply.json`
- `agentctl-restart.json`
- `agentctl-status.json`
- `agentctl-logs.json`

Avoid relying only on terminal text because later debugging usually needs the raw JSON payloads.

## Task Directory Semantics

`--task-dir` points to the local directory containing the remote task payload, typically including:

- `agent-task.yaml`
- optional packaged assets or scripts staged by the local task

Keep this directory deterministic so `task apply` is reproducible.

Current CLI behavior:

- `task apply --task-dir <dir>` loads `<dir>/agent-task.yaml`
- `task get|status|logs|start|stop|restart --task-dir <dir>` also resolves task identity from `<dir>/agent-task.yaml`
- `--task-id` and `--task-dir` are mutually exclusive
- `--file` and `--task-dir` are mutually exclusive for `task apply`

The loaded task file must contain `taskId`, otherwise `agentctl` fails before making the remote request.

## Task File Rules

Current parser rules:

- local task spec files must use the `.yaml` extension
- `.json` task files are explicitly rejected
- `task apply` sends the parsed YAML as JSON to `controlapi`

Because `task apply` forwards the file contents directly, keep field names aligned with the `agent-task.yaml` schema.

## FS Commands

Current supported file-system subcommands are:

- `fs stat --agent-id ... --path ...`
- `fs list --agent-id ... --path ...`
- `fs read --agent-id ... --path ... [--offset N] [--length N]`

Use these when task logs are insufficient and you need to inspect downloaded packages, current work directories, or persisted log files on the remote Windows side.
