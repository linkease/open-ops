# Ops It-Runner Nodeagent Task Rework Design

## Summary

Refactor `ops/.it-runner` away from the old `winagent/controlapi` task model and align it with the current four-program layout under `it-runner/cmd/`:

- `it_runner`: local task orchestrator
- `agentctl`: operator and automation CLI
- `agenthub`: central control plane
- `nodeagentd`: cross-platform target node agent

The `ops` repo should expose two clear task families:

1. infrastructure tasks for bundle build, demo publish, and local `agenthub` startup
2. remote-control tasks that call `agentctl` against a visible demo remote task directory

No compatibility layer for old `winagent_*` task names is required.

## Current Problem

`ops/.it-runner` still reflects the legacy `winagent` runtime model:

- visible tasks are still named `winagent_*`
- scripts still generate or copy `agentd.exe`
- scripts still prepare `/config/demo-data/winagent`
- the long-running server task still centers around `controlapi`

This no longer matches the current `it-runner` source tree and docs:

- `make build-bundle` now builds `nodeagent-bundle`
- `make publish-demo` now publishes to `/config/demo-data/nodeagent`
- operator flows are documented around `agentctl`
- the runtime pair is `agenthub` + `nodeagentd`

As a result, the `ops` repo no longer demonstrates the current standard `.it-runner` integration model.

## Goals

- replace old `winagent`-named tasks with new task families that match current runtime boundaries
- keep infrastructure setup and remote task control separate
- make `ops/.it-runner` a reusable reference for later business-repo onboarding
- keep one visible demo remote task directory that remote-control tasks can operate on through `agentctl`

## Non-Goals

- preserve old `winagent_*` task names
- keep old `controlapi`-first operator semantics
- move business-project source-of-truth into platform device state
- redesign `it-runner` core behavior

## Chosen Approach

Adopt a task surface split by control-plane responsibility.

The `ops` repo will contain:

- an infrastructure task family for local build, publish, and `agenthub` startup
- a remote-control task family for `agentctl`-based list/apply/restart/status/logs flows

This is preferred over a single all-in-one demo task because it makes failure domains obvious:

- build/publish failures stay in infrastructure tasks
- remote task control failures stay in `agentctl` tasks
- future business repos can copy only the remote-control half without inheriting ops-specific server tasks

## Task Families

### Infrastructure Tasks

These tasks manage shared local artifacts and the local Linux-side control plane.

- `nodeagent_build_bundle`
- `nodeagent_publish_demo`
- `agenthub_linux_server`
- optional: `nodeagent_publish_manual_bundle`

Responsibilities:

- build `agentctl`, `nodeagentd`, and Linux `agenthub`
- publish the demo bundle to the new nodeagent demo data root
- prepare Linux-side runtime files needed for local testing
- run the long-lived `agenthub` process

### Remote-Control Tasks

These tasks form the visible operator surface for remote task control.

- `agentctl_agent_list`
- `agentctl_task_apply_demo`
- `agentctl_task_restart_demo`
- `agentctl_task_status_demo`
- `agentctl_task_logs_demo`

Responsibilities:

- verify that `agenthub` is reachable
- verify that the selected target agent is registered
- apply one visible demo remote task from a repo-owned directory
- restart, inspect status, and inspect logs for that same remote task through `agentctl`

## Directory Model

```text
.it-runner/
  envs/
    000-defaults.env
    010-local.env
  tasks/
    nodeagent_build_bundle/
      task.yaml
      STATE
    nodeagent_publish_demo/
      task.yaml
      STATE
    agenthub_linux_server/
      task.yaml
      STATE
    agentctl_agent_list/
      task.yaml
      STATE
    agentctl_task_apply_demo/
      task.yaml
      agent-task.yaml
      STATE
    agentctl_task_restart_demo/
      task.yaml
      STATE
    agentctl_task_status_demo/
      task.yaml
      STATE
    agentctl_task_logs_demo/
      task.yaml
      STATE
  scripts/
    run_nodeagent_build_bundle.sh
    run_nodeagent_publish_demo.sh
    run_agenthub_linux_server.sh
    check_agenthub_linux_server.sh
    agentctl-agent-list.sh
    agentctl-task-apply.sh
    agentctl-task-restart.sh
    agentctl-task-status.sh
    agentctl-task-logs.sh
```

The visible demo remote task source-of-truth lives under:

- `.it-runner/tasks/agentctl_task_apply_demo/agent-task.yaml`

The other remote-control tasks reuse the same selected task directory through env configuration rather than duplicating remote task definitions.

## Env Model

### Shared Project Env

Keep shared defaults in `.it-runner/envs/000-defaults.env`.

Expected shared variables:

- `ITRUNNER_REPO_DIR`
- `NODEAGENT_DATA_ROOT`
- `AGENTCTL_BIN`
- `AGENTCTL_SERVER`
- `AGENTHUB_ADDR`
- `AGENT_ID`
- `AGENT_API_PORT`
- `AGENT_SSH_HOST`
- `AGENT_SSH_PORT`
- `AGENT_SSH_USER`
- `AGENT_KEY_PATH`

Keep machine-local overrides and secrets in `.it-runner/envs/010-local.env`.

### Task-Specific Rules

Infrastructure tasks should consume only the values needed for:

- local bundle output
- local publish path
- local `agenthub` bind address
- generated demo config content

Remote-control tasks should depend on a smaller operator surface:

- `AGENTCTL_BIN`
- `AGENTCTL_SERVER`
- `AGENT_ID`
- `AGENT_TASK_DIR`

`AGENT_TASK_DIR` should point at the visible demo remote task directory so that all `agentctl_task_*` wrappers operate on the same remote task.

## Task Behavior

### `nodeagent_build_bundle`

- runs `make -C "$ITRUNNER_REPO_DIR" build-bundle`
- replaces legacy `winagent_build_bundle`
- validates the new bundle output shape

### `nodeagent_publish_demo`

- runs `make -C "$ITRUNNER_REPO_DIR" publish-demo`
- publishes to `/config/demo-data/nodeagent` by default
- replaces legacy `winagent_publish_demo`

### `agenthub_linux_server`

- ensures bundle artifacts exist before startup
- prepares Linux-side runtime files for nodeagent demo use
- starts the Linux `agenthub` process
- performs a readiness check against the configured `agenthub` endpoint
- replaces legacy `winagent_linux_server`

### `agentctl_agent_list`

- runs `agentctl agent list`
- verifies the selected `AGENTCTL_SERVER` is reachable
- verifies at least operator-level visibility into registered agents

### `agentctl_task_apply_demo`

- owns the visible `agent-task.yaml`
- runs `agentctl task apply --task-dir "$AGENT_TASK_DIR"`

### `agentctl_task_restart_demo`

- runs `agentctl task restart --task-dir "$AGENT_TASK_DIR"`

### `agentctl_task_status_demo`

- runs `agentctl task status --task-dir "$AGENT_TASK_DIR"`

### `agentctl_task_logs_demo`

- runs `agentctl task logs --task-dir "$AGENT_TASK_DIR"`

## Script Migration

Map the legacy helper scripts to the new names and responsibilities:

- `run_winagent_build_bundle.sh` -> `run_nodeagent_build_bundle.sh`
- `run_winagent_publish_demo.sh` -> `run_nodeagent_publish_demo.sh`
- `run_winagent_linux_server.sh` -> `run_agenthub_linux_server.sh`
- `check_winagent_linux_server.sh` -> `check_agenthub_linux_server.sh`

`run_winagent_publish_manual_bundle.sh` should be kept only if there is still a real operator need for a manual-bundle-only publication path. Otherwise it should be deleted instead of carried forward under a new name.

## Naming and Semantic Changes

The rework must make these changes explicit:

- stop generating or copying `agentd.exe`; generate or copy `nodeagentd.exe`
- stop publishing to `/config/demo-data/winagent`; publish to `/config/demo-data/nodeagent`
- stop presenting the server task as a `controlapi` task; present it as an `agenthub` task
- stop mixing remote task control logic into infrastructure scripts; route remote control through `agentctl`

## Implementation Sequence

1. rewrite infrastructure tasks, scripts, and task descriptions around `nodeagent` and `agenthub`
2. add the `agentctl_*` remote-control task family around one visible demo `agent-task.yaml`
3. remove old `winagent_*` tasks, scripts, and README/env references

## Acceptance Criteria

- `nodeagent_build_bundle` produces the new artifact layout:
  - `bin/agentctl`
  - `bin/nodeagent-bundle/windows/nodeagentd.exe`
  - `bin/nodeagent-bundle/linux/agenthub`
- `nodeagent_publish_demo` publishes into `/config/demo-data/nodeagent`
- `agenthub_linux_server` starts successfully and the configured `AGENTCTL_SERVER` is usable for control flows
- `agentctl_agent_list` returns an agent list through `agentctl`
- `agentctl_task_apply_demo`
- `agentctl_task_restart_demo`
- `agentctl_task_status_demo`
- `agentctl_task_logs_demo`

The four demo control tasks above must all operate against the same selected demo remote task directory.

Also:

- no visible `winagent_*` task entry remains under `ops/.it-runner/tasks`
- no `.it-runner` README or script description still describes the old model as current

## Risks and Guardrails

- avoid reintroducing hidden remote-task assumptions into infrastructure scripts
- avoid duplicating `agent-task.yaml` across multiple visible control tasks
- avoid hardcoding machine-specific values into checked-in task configs
- keep `agentctl` wrappers thin; reusable protocol stays in `agentctl`, not project shell logic

## Result

After this rework, `ops/.it-runner` becomes a current reference implementation for:

- local `nodeagent` infrastructure setup in the ops repo
- standard visible `agentctl` remote-control tasks
- the modern `it_runner -> agentctl -> agenthub -> nodeagentd` operator model
