---
name: it-runner-workflow
description: Use when creating, debugging, or refactoring `.it-runner` projects and tasks, inspecting `it-runner` APIs, troubleshooting task discovery and env expansion issues, or making targeted fixes in the `it-runner` codebase itself.
---

# It-Runner Workflow

Use this skill for everything related to `.it-runner` structure, task authoring, API debugging, and `it-runner` runtime troubleshooting.

If the task is specifically about remote Windows program control through `agentd.exe`, `controlapi`, `agentctl`, or `agent-task.yaml`, use `../it-runner-agentd-control/SKILL.md` first, then return here for generic `.it-runner` issues.

If the main task is specifically migrating a legacy project from old env naming to the new numbered env convention, prefer `it-runner-convention-upgrade` first, then come back here for runtime verification.

## Goal

Create `.it-runner` setups that are discoverable, debuggable, and stable across business repos and `ops-fleet`.

## What This Skill Covers

- project-level `.it-runner` layout
- `project.yaml` conventions
- `task.yaml` conventions
- env file loading and debugging
- task visibility and task discovery failures
- API-based debugging of tasks
- targeted `it-runner` core fixes when behavior is clearly in the runner itself

## Required Directory Model

At minimum, expect:

```text
.it-runner/
  project.yaml
  envs/
    000-defaults.env
    010-local.env
  tasks/
    <task-name>/task.yaml
  logs/
  states/
```

Important rule: tasks should normally be discovered as **task directories containing `task.yaml`**, not loose YAML files.

## Project Rules

- `project.yaml` is the discovery root.
- Prefer `${PROJECT_ROOT}` when composing paths.
- Keep `logsDir`, `tasksDir`, and `envFiles` explicit when needed.
- Be careful with env expansion order when using values like `${DATA_ROOT}`.

## Task Rules

- Every task must include `version: "1"`.
- Prefer a small, intentional task surface.
- Use clear names that reflect operator intent.
- For families of tasks, prefer selected-target tasks over excessive duplication.
- Prefer `watch.stateFile` as the file-based control entry for stop/restart behavior.
- Prefer task-local env plans over pushing task-specific parameters into project-wide `010-local.env`.

## Task-Centric Design Rule

When the repo has more than trivial tasks, prefer task-centered env assembly:

- shared project defaults stay in `.it-runner/envs/000-defaults.env`
- machine-local overrides stay in `.it-runner/envs/010-local.env`
- task defaults move into `tasks/<task>/envs/000-defaults.env`
- reusable parameter sets move into `.it-runner/envsets/`
- `task.yaml` should declare `env.autoDirs`, `env.includeSets`, and `env.required` whenever a task has real parameter needs

Do not assume one universal pattern. Choose the smallest viable task-centric pattern for the repo.

## State File Control

When a task defines `watch.stateFile`, there are two supported ways to trigger it:

1. Use the HTTP API
2. Write a control command into the task's `.STATE` file

Recommended file-based control commands are:

- `echo "RESTART $(date +%s)" > <STATE_FILE>`
- `echo "STOP $(date +%s)" > <STATE_FILE>`

Important notes:

- Include a changing token such as a timestamp so each command is treated as new.
- The recommended control words are `RESTART` and `STOP`.
- Do not assume arbitrary text has meaningful semantics; prefer the runner's documented control format.
- A plain write that changes the file may still trigger behavior in some setups, but standardize on `RESTART <token>` / `STOP <token>`.

## API Debugging Workflow

When a task is missing or failing, use this sequence:

1. Confirm the task file exists in the right directory structure.
2. Confirm the task appears in the task listing API.
3. Inspect `envs-next` to see the next resolved environment.
4. Trigger the task via API.
5. Inspect task status and logs.
6. Only after that decide whether the bug is in task config, env files, or `it-runner` itself.

## Common Failure Modes

- `task.version missing`
- task file exists but is not discovered because it is not in `<task-dir>/task.yaml` form
- env values missing from `envs-next`
- `logsDir` or `tasksDir` expands incorrectly due to env expansion timing
- generated task includes point at missing include files
- UI caches older task lists and needs project reload

## When To Patch `it-runner` Itself

Only patch `it-runner` when:
- the task file is valid
- API discovery shows mismatched or missing behavior inconsistent with config
- `envs-next` or task execution proves the runner is transforming config incorrectly
- you can explain the bug in terms of `project.yaml`, task discovery, env expansion, or API behavior

When patching `it-runner`, add a small regression test if practical.

## References

- Read `../it-runner-agentd-control/SKILL.md` when the work targets remote Windows program control through `agentd.exe` and `agentctl`.
- Read `references/api-and-debugging.md` when troubleshooting via API.
- Read `references/authoring-checklist.md` when creating or reviewing `.it-runner` tasks.
- Read `references/env-conventions.md` when designing or refactoring `.it-runner` env layouts.
- Read `references/task-reading-and-naming.md` when the problem is understanding task names, task summaries, or cross-project task ambiguity.
- Read `references/log-reading-and-paths.md` when the problem is choosing between `latest` and one concrete run directory, or deciding which log file to read first.
- Read `references/ui-semantics.md` when interpreting task detail statuses, frontend copy behavior, or HTTP-safe copy flows.
- Read `references/task-centric-patterns.md` when choosing between target/meta, lightweight build/dev, app dev+deploy, or control-hub task models.
- Read `references/project-rollout-status.md` when choosing the next repo to migrate or the closest existing repo template.
