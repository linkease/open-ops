# It-Runner Cheatsheet

A practical quick-reference for operators and AI agents working with `.it-runner` tasks.

## 1. Find Tasks

### List all tasks

```bash
curl -s http://127.0.0.1:19090/it-runner/api/tasks | jq .
```

### List tasks for one workspace/project

```bash
curl -s http://127.0.0.1:19090/it-runner/api/workspaces/<workspaceKey>/projects/<projectKey>/tasks | jq .
```

### Inspect one task

```bash
curl -s http://127.0.0.1:19090/it-runner/api/tasks/<taskKey> | jq .
```

## 2. Start / Stop / Restart

### Start or trigger a task by task key

```bash
curl -X POST http://127.0.0.1:19090/it-runner/api/tasks/<taskKey>/run
```

### Restart a task by task key

```bash
curl -X POST http://127.0.0.1:19090/it-runner/api/tasks/<taskKey>/restart
```

### Stop a task by task key

```bash
curl -X POST http://127.0.0.1:19090/it-runner/api/tasks/<taskKey>/stop
```

### Start from workspace/project/taskName

```bash
curl -X POST http://127.0.0.1:19090/it-runner/api/workspaces/<workspaceKey>/projects/<projectKey>/tasks/<taskName>/run
```

## 3. Control Through `.STATE`

When a task defines `watch.stateFile`, you can control it via the state file.

### Restart

```bash
echo "RESTART $(date +%s)" > <STATE_FILE>
```

### Stop

```bash
echo "STOP $(date +%s)" > <STATE_FILE>
```

### Notes

- Always use a fresh token such as `$(date +%s)`.
- Prefer `RESTART` / `STOP` over arbitrary echoed text.
- Use API control when you need explicit remote automation by task key.

## 4. Inspect Environment Resolution

### Current resolved envs

```bash
curl -s http://127.0.0.1:19090/it-runner/api/tasks/<taskKey>/envs | jq .
```

### Next-run resolved envs

```bash
curl -s http://127.0.0.1:19090/it-runner/api/tasks/<taskKey>/envs-next | jq .
```

### Use cases

- check whether `TLSPROXY_TARGET` is set
- check whether `DATA_ROOT` expanded correctly
- check whether `PROJECT_ROOT` and artifact paths are what you expect

## 5. Read Logs

### Get task state and logDir

```bash
curl -s http://127.0.0.1:19090/it-runner/api/tasks/<taskKey> | jq '{status,lastError,logDir}'
```

### List task log files

```bash
curl -s http://127.0.0.1:19090/it-runner/api/tasks/<taskKey>/logs | jq .
```

### Read the main log file directly

```bash
sed -n '1,200p' <logDir>/it-runner.log
```

### Tail the latest log

```bash
tail -n 100 <logDir>/it-runner.log
```

## 5.5 AI Quick Read For Task / Log / UI

When an AI agent needs to explain one task quickly, prefer this order:

1. `project`
2. `name`
3. `description`
4. `tags`
5. `key`

Preferred display form when ambiguity is possible:

- `<project>: <task-name>`

When an AI agent needs to explain the task detail UI, separate these layers:

- runtime status such as `已停止` / `运行中`
- readiness status such as `可启动` / `缺参数`
- stream status such as `实时流: SSE` / `实时流: Polling`

Important:

- `可启动` means config/env context is ready, not already running
- `Polling` means the UI fell back from SSE, not that the task failed

When an AI agent needs to explain or copy log paths:

- prefer copying `latest/...` paths for reuse
- mention the concrete timestamped run directory only as current context
- read `it-runner.log` before stdout/stderr when debugging task orchestration

## 6. Common Failure Patterns

### Task missing from UI/API

Check:
- task is stored as `<task-name>/task.yaml`
- `version: "1"` is present
- project has `.it-runner/project.yaml`
- runner has reloaded the project

### Task exists but wrong env values

Check:
- `envs-next`
- `envFiles`
- numbered env files in `.it-runner/envs/`
- `${PROJECT_ROOT}` usage
- `logsDir` / `tasksDir` expansion

### Check env conventions quickly

Run:
- `go run ./it-runner/cmd/it_runner --project <project-root> --check-project-envs`
- `go run ./it-runner/cmd/it_runner --projects-root <dir> --check-project-envs`
- `go run ./it-runner/cmd/it_runner --project <project-root> --check-project-envs=json`
- `go run ./it-runner/cmd/it_runner --project <project-root> --check-project-envs --json`

### Task logs go to `/logs`

Likely runner-side env expansion timing issue. Verify `project.yaml` and `envs-next`; patch `it-runner` if config is valid but runner transforms it incorrectly.

### Task fails with missing selected target

Check:
- selector env var such as `TLSPROXY_TARGET`
- project-local `.it-runner/envs/010-local.env` or higher-priority selector file
- `envs-next`

## 7. Authoring Checklist

Before debugging deeply, confirm:

- task file path is `<task-dir>/task.yaml`
- `version: "1"` exists
- `watch.stateFile` exists if file-based control is expected
- `workdir` is correct
- task appears in API list
- `envs-next` looks sane

## 8. Recommended Debug Sequence

1. confirm task file exists
2. confirm task appears in API
3. inspect `envs-next`
4. run the task via API
5. inspect `status`, `lastError`, `logDir`
6. read `it-runner.log`
7. only then decide whether to patch task config, env files, or `it-runner` core

## 9. Related Skill Files

- `skills/it-runner-workflow/SKILL.md`
- `skills/it-runner-workflow/references/api-and-debugging.md`
- `skills/it-runner-workflow/references/authoring-checklist.md`
- `skills/it-runner-workflow/references/env-conventions.md`
- `skills/it-runner-workflow/references/task-reading-and-naming.md`
- `skills/it-runner-workflow/references/log-reading-and-paths.md`
- `skills/it-runner-workflow/references/ui-semantics.md`
- `skills/TEMPLATES.md`
