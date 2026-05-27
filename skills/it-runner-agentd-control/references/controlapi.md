# Controlapi Reference

## Scope

This file documents the `controlapi` role in the `agentd.exe` remote execution path.

Use this reference when you need to explain or implement:

- where remote packages are published
- how `agentctl` reaches the control surface
- how local `.it-runner` tasks map to remote Windows task application

## Current Practical Contract

In the current workflow, the safest integration contract is the `agentctl` CLI, not handwritten direct HTTP calls.

Observed command pattern:

- `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json agent ping --agent-id "$WINAGENT_AGENT_ID"`
- `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task apply --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task restart --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task status --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`
- `agentctl --server "$WINAGENT_CONTROLAPI_BASE_URL" --output json task logs --agent-id "$WINAGENT_AGENT_ID" --task-dir "$AGENT_TASK_DIR"`

If a project must call `controlapi` directly, use the routes below. Do not invent a parallel contract.

## HTTP Surface

Current routes exposed by `winagent-controlapi`:

- `POST /internal/agents/register`
- `GET /v1/agents`
- `GET /v1/agents/{agentId}`
- `GET /v1/agents/{agentId}/capabilities`
- `GET /v1/agents/{agentId}/tasks/{taskId}`
- `PUT /v1/agents/{agentId}/tasks/{taskId}`
- `POST /v1/agents/{agentId}/tasks/{taskId}/start`
- `POST /v1/agents/{agentId}/tasks/{taskId}/stop`
- `POST /v1/agents/{agentId}/tasks/{taskId}/restart`
- `GET /v1/agents/{agentId}/tasks/{taskId}/status`
- `GET /v1/agents/{agentId}/tasks/{taskId}/logs`
- `GET /v1/agents/{agentId}/fs/stat?path=...`
- `GET /v1/agents/{agentId}/fs/list?path=...`
- `GET /v1/agents/{agentId}/fs/read?path=...`
- `GET /packages/{packageName}`

## Registration Model

Remote agents register into `controlapi` through:

- `POST /internal/agents/register`

Request body shape:

```json
{
  "agentId": "devbox-01",
  "proxyBaseUrl": "http://127.0.0.1:49080",
  "hostname": "optional-hostname"
}
```

Observed behavior:

- `agentId` and `proxyBaseUrl` are required
- `online` is forced to `true` by the registry store
- success returns HTTP `202 Accepted`

`proxyBaseUrl` is the agent-side HTTP endpoint that `controlapi` proxies to.

## Proxy Model

`controlapi` does not fully mirror every agent-local route. Current behavior is:

- `GET /v1/agents/{agentId}` is synthesized by `controlapi`
- `GET /v1/agents/{agentId}/capabilities` is synthesized by `controlapi`
- `/v1/agents/{agentId}/tasks/...` is proxied to the agent-local `/v1/tasks/...`
- `/v1/agents/{agentId}/fs/...` is proxied to the agent-local `/v1/agent/fs/...`

This means:

- `agent ping` works by combining synthesized `info` and `capabilities`
- task and file-system operations depend on the registered `proxyBaseUrl`
- if registration is stale or missing, list/info may differ from actual task reachability

## Package Serving Model

Observed package convention:

- local task builds `PACKAGE_DIR/PACKAGE_NAME`
- the remote package is expected at `${WINAGENT_CONTROLAPI_BASE_URL%/}/packages/$PACKAGE_NAME`
- `agent-task.yaml` references `packageName`, not a full absolute URL

This implies `controlapi` is expected to expose a stable package namespace rooted at `/packages/`.

Current implementation details:

- package files are served directly from the `packages/` directory under the `winagent-controlapi` working directory
- nested package paths are allowed because package names are path-escaped per segment
- there is no observed auth layer in the current server implementation

## Defaults And Deployment Notes

Observed defaults:

- `winagent-controlapi` listens on `:18080` when `CONTROLAPI_ADDR` is unset
- many examples point `WINAGENT_CONTROLAPI_BASE_URL` at `http://127.0.0.1:18080`

Be aware that `agentctl` itself defaults to `http://127.0.0.1:28080`, so serious automation should always pass `--server` explicitly.

## Error Semantics

Current observed server behavior is intentionally simple:

- unknown agent returns HTTP `404` with `agent not found`
- invalid register payload returns HTTP `400`
- upstream agent proxy failures return HTTP `502`
- proxied task or fs errors are returned from the agent-local API

Because the current implementation is thin, operators should save the raw JSON or body text for failures instead of relying on a normalized error schema.
