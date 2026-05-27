# Second Service Onboarding Checklist

This checklist is for the next business project that wants to follow the same model proven with `tlsproxy`.

Validated real services so far:

- `tlsproxy`
- `ddns-server`

Use it after reading:
- `skills/INDEX.md`
- `skills/TRIGGERS.md`
- `skills/TEMPLATES.md`
- `skills/NEW-SERVICE-RUNBOOK.md`

## Goal

Onboard a second service with the same engineering pattern:
- business repo owns deployment logic
- business repo can deploy to its own test server(s)
- `ops-fleet` owns production resources and rollout entry points
- `.it-runner` remains small, discoverable, and debuggable

## Stage 1: Model Check

- Identify one or more **test servers** for the business repo.
- Identify one or more **production servers** for `ops-fleet`.
- Decide whether any physical host appears in both places.
- Split data into:
  - `server`
  - `deployment`
  - `local overrides`
  - `release`
  - `rollout`
- Decide the standard action contract:
  - `release`
  - `init`
  - `preflight`
  - `deploy`
  - `rollback`
  - `verify`

## Stage 2: Business Repo Setup

### Files to create

- `scripts/ops/common.sh`
- `scripts/ops/release.sh`
- `scripts/ops/init.sh`
- `scripts/ops/preflight.sh`
- `scripts/ops/deploy.sh`
- `scripts/ops/rollback.sh`
- `scripts/ops/verify.sh`
- `.it-runner/project.yaml`
- `.it-runner/envs/010-local.env`
- `.it-runner/meta/servers/*.env`
- `.it-runner/meta/deployments/*.env`
- `.it-runner/tasks/*/task.yaml`
- `Makefile` entries for `ops-*`

### Required checks

- `010-local.env` contains only local overrides
- server data is not mixed into deployment files
- tasks are selected-target oriented
- `version: "1"` exists in every task
- `ops-targets` works
- `ops-show-selected` works
- `ops-release` works
- `ops-preflight-selected` works
- `ops-deploy-selected` works
- `ops-verify-selected` works

### Exit condition

- one real test deployment succeeds end to end without `ops-fleet`

## Stage 3: Ops-Fleet Setup

### Files to create

- `.it-runner/meta/projects/<service>.env`
- `.it-runner/meta/servers/*.env`
- `.it-runner/meta/<service>/deployments/*.env`
- `scripts/lib/<service>_meta.sh`
- `scripts/<service>/release_target.sh`
- `scripts/<service>/preflight_target.sh`
- `scripts/<service>/deploy_target.sh`
- `scripts/<service>/verify_target.sh`
- `scripts/<service>/rollback_target.sh`
- operator tasks under `.it-runner/tasks/manual/`

### Required checks

- wrapper scripts call business-repo `scripts/ops/*.sh`
- no deploy logic is reimplemented in `ops-fleet`
- production metadata is independent from business-repo test metadata
- selected-target tasks work
- optional `[Canary]` / `[Promote]` shortcuts are thin wrappers only

### Exit condition

- one canary production deployment succeeds end to end

## Stage 4: It-Runner Checks

- task directory layout is `<task-name>/task.yaml`
- every task has `version: "1"`
- task appears in API list
- `envs-next` is sane for selected-target tasks
- logs go to the expected `logsDir`
- if behavior is wrong, debug `it-runner` before guessing at env files

## Stage 5: Operational Readiness

- publish artifact
- canary first host
- verify canary
- promote next host(s)
- verify promoted hosts
- document rollback release ID procedure

## What to copy from `tlsproxy`

Copy the pattern, not the business-specific values:

- three-layer model in the business repo
- `servers + deployments` model in `ops-fleet`
- standard `scripts/ops/*.sh` action contract
- selected-target task surface
- optional explicit `[Canary]` / `[Promote]` operator tasks
- small test targets such as `test-ops`

## What not to copy blindly

- hostnames
- deploy paths
- config file paths
- service names
- verification details
- artifact names
- init-time token details

## Final success signal

The second service is considered successfully onboarded when:

- developers can deploy it from the business repo to a real test server
- operators can deploy it from `ops-fleet` to at least one production server
- both repos use the same deployment contract
- `it-runner` tasks are small, visible, and debuggable
