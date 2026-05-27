---
name: ops-fleet-project-onboarding
description: Use when onboarding a standardized business repository into `ops-fleet` for production release orchestration, target metadata management, and thin wrapper tasks that call the business repo's standard deployment contract.
---

# Ops-Fleet Project Onboarding

Use this skill once a business repo already owns its deployment logic.

## Goal

Integrate a project into `ops-fleet` without copying the project's deploy implementation.

## Required Outcome

`ops-fleet` should provide:
- production server resources
- production deployment target metadata
- thin wrapper scripts/tasks that call the business repo contract
- release, preflight, deploy, verify, rollback entry points for production operations

## Rules

- `ops-fleet` should not reimplement business deployment details.
- Business repo script paths should be explicit and centralized.
- Production metadata may duplicate business-repo test metadata; this is acceptable.
- The same physical host may exist in both the business repo and `ops-fleet`, but the copies serve different purposes and should remain independently editable.
- Within `ops-fleet`, prefer a split between shared `servers/` metadata and per-service deployment metadata when hosts may run multiple services.
- Prefer target-selected tasks over many generated per-host manual tasks unless UI or process truly requires per-host entries.

## Onboarding Flow

1. Confirm the business repo has a stable `scripts/ops/*.sh` contract.
2. Register the business repo in `ops-fleet` project metadata.
3. Add production targets for that project.
4. Build thin wrapper scripts that:
   - load selected target metadata
   - map metadata to the business contract env vars
   - execute the business repo script
5. Create the small production task surface.
6. Add runbook guidance for canary, promote, rollback, verify.

## Recommended Files

- `.it-runner/meta/projects/<project>.env`
- `.it-runner/meta/<service>/targets/*.env`
- `scripts/lib/project_runner.sh`
- `scripts/lib/<project>_meta.sh`
- `scripts/<project>/release_target.sh`
- `scripts/<project>/preflight_target.sh`
- `scripts/<project>/deploy_target.sh`
- `scripts/<project>/verify_target.sh`
- `scripts/<project>/rollback_target.sh`

## Recommended Task Surface

- `[Release] <service>`
- `[Releases] <service>` if release listing exists
- `[Project] targets`
- `[Project] show-selected`
- `[Project] init-selected`
- `[Project] preflight-selected`
- `[Project] deploy-selected`
- `[Project] verify-selected`
- `[Project] rollback-selected`

When operator ergonomics matter, it is also acceptable to add a very small number of explicit rollout shortcuts such as:

- `[Canary] <service>-<host>`
- `[Promote] <service>-<host>`

These shortcuts should call the same selected-target wrappers or business-repo contract, not duplicate deployment logic.

## Validation

- verify generated or manual tasks are visible in `it-runner`
- verify wrapper tasks pass the right env vars to the business repo
- verify canary target first
- verify rollback path before broad rollout use

## References

- Read `references/checklist.md` when actually onboarding a project.
- Read `../it-runner-workflow/references/env-conventions.md` when wrapper tasks or project-local env layouts are involved.
