# API And Debugging

## Useful Endpoints

- `GET /it-runner/api/runner`
- `GET /it-runner/api/tasks`
- `GET /it-runner/api/tasks/{taskKey}`
- `GET /it-runner/api/tasks/{taskKey}/logs`
- `GET /it-runner/api/tasks/{taskKey}/envs`
- `GET /it-runner/api/tasks/{taskKey}/envs-next`
- `POST /it-runner/api/tasks/{taskKey}/run`
- `POST /it-runner/api/tasks/{taskKey}/stop`
- `POST /it-runner/api/tasks/{taskKey}/restart`

## State File Control

If a task defines `watch.stateFile`, you can control it without the HTTP API.

Recommended commands:

- restart: `echo "RESTART $(date +%s)" > <STATE_FILE>`
- stop: `echo "STOP $(date +%s)" > <STATE_FILE>`

Notes:

- Use a fresh timestamp or token each time.
- Prefer this standardized format over arbitrary echoed text.
- Use API control when you need explicit remote automation or task-key-based operations.

## Recommended Debug Sequence

1. List tasks and confirm discoverability.
2. Fetch the individual task state.
3. Fetch `envs-next` before running the task.
4. Run the task through the API.
5. Read task logs.
6. Inspect the runner logs only if task logs are insufficient.

## Example Symptoms

### Task missing from API

Check:
- directory layout
- `task.yaml`
- `version: "1"`
- project reload or runner restart if discovery is stale

### Task starts but uses wrong paths

Check:
- `project.yaml` env expansion
- `envFiles`
- `${PROJECT_ROOT}` usage
- `envs-next`

### Task writes logs to `/logs`

Likely runner-side env expansion timing bug. Confirm with `envs-next` and inspect `project.yaml` path expansion.
