# Authoring Checklist

## Project Setup

- `.it-runner/project.yaml` exists
- `tasksDir` and `logsDir` are sensible
- `envFiles` are only for explicit special cases such as repo-external env files
- auto-loaded envs are kept in a small whitelist surface instead of scanning every `.env`
- ordered env files in `.it-runner/envs/` use `000-*.env` style prefixes when priority matters
- legacy `.it-runner/.env` and `.it-runner/.env.local` are not used
- optional env variants use one selector variable (for example `020-server@SELECT_SERVER=c-server.env`)
- secrets exposed to operators use `SECRET_` prefixes so env inspection can redact them
- project-level `010-local.env` is reserved for machine-local shared overrides, not for piling task-specific defaults

## Task Setup

- directory is `<name>/task.yaml`
- when a task needs its own defaults, prefer `tasks/<task>/envs/000-defaults.env`
- use `task.yaml -> env.autoDirs` for task-local automatic env loading
- use `task.yaml -> env.includeSets` for non-auto parameter sets such as deploy targets, assignments, and runtime profiles
- use `task.yaml -> env.required` for variables that must exist before the task runs
- if multiple task families exist, choose the task model from `task-centric-patterns.md` before creating new env layers
- if the migration spans multiple repos, check `project-rollout-status.md` before picking the next repo or pattern
- `version: "1"` present
- `name` and `description` are operator-friendly
- tags are present where useful
- command is non-interactive unless explicitly intended
- `watch.stateFile` is present when the task should support file-based stop/restart control

## Operational Usability

- logs path is stable
- task names are short enough for UI scanning
- selected-target workflows use one selector variable instead of N near-duplicate tasks
- if `watch.stateFile` is used, document the exact `RESTART <token>` / `STOP <token>` pattern

## Validation

- task appears in API list
- `envs-next` looks correct
- higher-numbered env files override lower-numbered ones as intended
- selector env files only appear when the selector variable matches
- task runs successfully
- task logs are understandable
