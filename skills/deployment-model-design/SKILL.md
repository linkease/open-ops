---
name: deployment-model-design
description: Use when designing or refactoring how projects deploy across test and production environments, especially when separating server resources, per-project deployment config, local overrides, releases, and rollout strategy.
---

# Deployment Model Design

Use this skill before changing deployment structure, repo responsibilities, or environment modeling.

## Goal

Produce a stable deployment model that:
- keeps business deployment logic in the business repo
- keeps environment resources and rollout orchestration in `ops-fleet`
- supports both project-local test deployment and multi-server production deployment
- avoids mixing server connection data with per-project deployment instance data

## Core Principles

- Treat the **business repo as the source of deployment logic truth**.
- Treat `ops-fleet` as the **production resource and orchestration layer**.
- Keep **model unified, data independent** across repos.
- Allow the **same physical host** to appear in both business-repo test metadata and `ops-fleet` production metadata; duplication is acceptable when the purpose differs.
- Prefer **one deployment contract** shared across repos over copied scripts.
- Use **released artifacts** for production deploys; do not rely on ad-hoc source-tree outputs in production.

## Required Model

Always design with these separate concepts unless the user explicitly asks for a simpler one-off setup:

1. **Server**
   - Connection-only data: `ssh_target`, `ssh_port`, `ssh_opts`, optional username semantics.
   - Must not contain business deployment paths or service config.

2. **Deployment**
   - A single project instance on a server.
   - Contains `server_ref`, `deploy_base`, config file path, token path, binary path, service name, ports, domains, and app-specific settings.

3. **Local Overrides**
   - Temporary local settings for developer/test convenience.
   - Examples: token defaults, smoke-test URLs, tuning parameters, target selectors.
   - Must not hold durable server resource definitions.

4. **Release**
   - A deployable artifact set.
   - Must be independently addressable for rollback.

5. **Rollout**
   - The ordered production promotion strategy.
   - Examples: canary, promote, rollback, verify.

## Repo Boundaries

### Business Repo

Should own:
- build and release logic
- deploy/init/preflight/rollback/verify logic
- project-local `.it-runner` tasks for dev/test environments
- test-server metadata

### `ops-fleet`

Should own:
- production server resources
- production deployment target metadata
- release orchestration and multi-host rollout tasks
- runbooks for formal production use

`ops-fleet` should also split **server resources** from **per-service deployment instances** when multiple services may land on the same machine.

## Standard Contract

Recommend a stable action contract in each business repo:

- `scripts/ops/release.sh`
- `scripts/ops/init.sh`
- `scripts/ops/preflight.sh`
- `scripts/ops/deploy.sh`
- `scripts/ops/rollback.sh`
- `scripts/ops/verify.sh`

Keep action names fixed. Let project-specific details live behind the contract.

## Design Process

1. Identify whether the user is solving **project-local test deployment**, **production onboarding**, or both.
2. List current mixed concepts and where they are incorrectly combined.
3. Propose the three-layer split: `server`, `deployment`, `local overrides`.
4. Define which repo owns which data.
5. Define the business-repo action contract.
6. Define release and rollout expectations.
7. Write a concise spec before implementation when changes are broad.

## Anti-Patterns

Avoid these unless the user explicitly requests them:

- one file that mixes server SSH data and project deployment instance data
- copying full deploy logic into `ops-fleet`
- making production depend on a project's ad-hoc current working directory outputs
- generating many host-specific tasks when a small target-selected workflow will do
- stuffing deployment resource data into project-local override env files such as `.it-runner/envs/010-local.env`

## References

- Read `references/examples.md` when you want concrete patterns and example folder layouts.
- Read `../it-runner-workflow/references/env-conventions.md` when the design includes `.it-runner` env layering.
