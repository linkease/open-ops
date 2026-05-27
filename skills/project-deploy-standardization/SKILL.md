---
name: project-deploy-standardization
description: Use when converting a business repository into a self-owned deployment project with standard `scripts/ops/*.sh`, project-local `.it-runner`, Makefile targets, and three-layer deployment metadata for test environments.
---

# Project Deploy Standardization

Use this skill when a business repo should become independently deployable for development or test environments.

## Goal

Turn a business repo into a reusable deployment unit that can:
- deploy itself to test servers without `ops-fleet`
- expose a stable deployment contract for `ops-fleet` to call later
- keep deployment behavior close to the business code that evolves over time

## Required Deliverables

Create or normalize these pieces:

1. `scripts/ops/*.sh`
   - `release.sh`
   - `init.sh`
   - `preflight.sh`
   - `deploy.sh`
   - `rollback.sh`
   - `verify.sh`

2. Project-local `.it-runner`
   - selected-target tasks rather than many duplicated host-specific tasks
   - target listing, target display, preflight, deploy, verify, rollback

3. Three-layer metadata
   - `.it-runner/meta/servers/*.env`
   - `.it-runner/meta/deployments/*.env`
   - `.it-runner/envs/010-local.env` only for local overrides

4. `Makefile` shortcuts
   - expose the project deployment workflow clearly
   - include a small self-test target for deployment contract sanity

## Contract Rules

- Script names should be stable.
- Inputs should be environment-driven and non-interactive.
- `preflight` must fail clearly on SSH/connectivity failures.
- `deploy` should prefer resumable/incremental transfer where practical.
- `rollback` should operate on a concrete release identifier.
- `verify` should validate the deployed service state, not just command success.

## Local Env Rules

Keep only local and temporary values in `.it-runner/envs/010-local.env` or a higher-priority local env file, such as:
- `TLSPROXY_TARGET`
- developer tokens
- test URLs
- tuning values

Do not keep durable server connection definitions there.

## Task Surface Recommendation

Prefer this small task surface:
- `ops-targets`
- `ops-show-selected`
- `ops-release`
- `ops-init-selected`
- `ops-preflight-selected`
- `ops-deploy-selected`
- `ops-verify-selected`
- `ops-rollback-selected`
- `test-ops`

Delete or retire older overlapping tasks once the new surface works.

## Work Sequence

1. Audit existing deploy scripts and legacy tasks.
2. Define the project contract.
3. Build `scripts/ops/*.sh` skeletons.
4. Introduce three-layer metadata.
5. Replace legacy `.it-runner` tasks with selected-target tasks.
6. Update `Makefile` and help text.
7. Add a lightweight deployment self-test.
8. Remove obsolete tasks after verifying the new workflow.

## References

- Read `references/checklist.md` when implementing or reviewing a project repo.
- Read `../it-runner-workflow/references/env-conventions.md` when designing `.it-runner/envs/`.
