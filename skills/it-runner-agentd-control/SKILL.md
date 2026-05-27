---
name: it-runner-agentd-control
description: Use when controlling remote Windows programs through `agentd.exe`, `controlapi`, and `agentctl`, or when building `.it-runner` tasks that package binaries, publish packages, apply remote agent tasks, restart them, and inspect remote status/logs.
---

# It-Runner Agentd Control

Use this skill when the work is specifically about the remote Windows agent control path, not just generic `.it-runner` authoring.

If the task is mainly about `.it-runner` structure, env layering, or task discovery, start with `../it-runner-workflow/SKILL.md` and come back here for the remote control portion.

## Goal

Create or debug a reliable flow that:

- packages a Windows program and companion assets
- publishes the package where `controlapi` can serve it
- applies an `agent-task.yaml` definition to a remote `agentd.exe`
- restarts or stops the remote task through `agentctl`
- captures status and logs back into the local `.it-runner` task run

## System Model

Treat the system as four layers:

1. local `.it-runner` task orchestration
2. local packaging and publish step
3. `controlapi` as the remote control and package distribution surface
4. remote Windows `agentd.exe` executing an `agent-task.yaml`

Prefer documenting and automating the boundaries between these layers instead of hiding them in one large shell script.

## Primary Workflow

1. Confirm the local binary or package inputs exist.
2. Confirm `agentctl` exists and is executable.
3. Package the Windows program into a stable zip artifact.
4. Confirm the package lands in the directory served by `controlapi`.
5. Probe the remote agent with `agentctl agent ping`.
6. Apply the remote task with `agentctl task apply`.
7. Restart or stop it with `agentctl task restart` or `agentctl task stop`.
8. Poll `agentctl task status` and `agentctl task logs` until terminal state.
9. Save structured outputs to the local task log directory.

## Required Inputs

Expect most task implementations to define these explicitly:

- `WINAGENT_CONTROLAPI_BASE_URL`
- `WINAGENT_AGENT_ID`
- `AGENTCTL_BIN`
- `AGENT_TASK_DIR`
- package name and package output directory
- remote task work dir and log dir

Do not rely on hidden defaults when the task will be reused across projects.

## Design Rules

- Prefer `agentctl` as the stable operator interface.
- Keep `agent-task.yaml` checked into the repo or generated deterministically.
- Keep packaging and remote apply as separate functions even if one task calls both.
- Save `agentctl` JSON outputs as artifacts so failures are inspectable after the run.
- Prefer polling state transitions over assuming a restart succeeded.
- Treat package publication and remote apply as two distinct failure domains.

## Recommended Task Surface

For a serious integration, prefer a small but explicit task family:

- publish package only
- apply remote task only
- restart remote task only
- full publish + apply + restart flow
- status/log inspection only

The full end-to-end task may call the same shared helper functions as the smaller tasks.

## Validation Checklist

- local package exists and contains expected files
- package URL matches the `controlapi`-served path
- `agent ping` succeeds for the target `agentId`
- `task apply` returns success
- `task status` reaches the expected state
- remote program logs are readable from the local task output

## References

- Read `references/controlapi.md` for the package serving and control surface.
- Read `references/agentctl.md` for the operator commands and suggested sequencing.
- Read `references/agentd.md` for the remote runtime model and observed states.
- Read `references/deskwin-winagent-run.md` for the current `sdkapptunnel` example.
- Read `references/troubleshooting.md` when the remote task does not start or report logs correctly.
- Reuse files under `assets/deskwin-winagent-template/` when starting a new task family or a new `agentd.exe` host bootstrap.
