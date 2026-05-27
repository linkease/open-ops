# New Service Deployment Runbook

This runbook turns the deployment skills in `skills/` into a practical operating sequence for future services.

It is organized into three phases:
- **Day 1**: design the deployment model
- **Day 2**: make the business repo independently deployable to test servers
- **Production**: onboard the project into `ops-fleet` and operate formal rollout

## Phase 1: Day 1 Design

### Goal

Define the deployment model before writing tasks or scripts.

### Use these skills

- `deployment-model-design`
- `it-runner-workflow` if `.it-runner` structure is already involved

### Decisions to make

1. What is a **server** in this project?
2. What is a **deployment instance** for this project?
3. What must remain in **local overrides** only?
4. What is the **artifact boundary**?
5. What rollout shape is required later: canary, promote, rollback, verify?
6. Which repo owns deployment logic? Usually: the business repo.
7. Which repo owns production resources? Usually: `ops-fleet`.
8. Can the same physical host appear in both business-repo test metadata and `ops-fleet` production metadata? If yes, keep the data independent but keep the model consistent.

### Expected output

- a clear model for:
  - `server`
  - `deployment`
  - `local overrides`
  - `release`
  - `rollout`
- a repo responsibility split
- a folder layout direction

### Exit criteria

- no mixed “server + deployment” files remain in the design
- business repo and `ops-fleet` responsibilities are explicit
- action contract is decided: `release/init/preflight/deploy/rollback/verify`

## Phase 2: Day 2 Business Repo Standardization

### Goal

Make the business repo independently deployable to test servers.

### Use these skills

- `project-deploy-standardization`
- `it-runner-workflow`

### Create in the business repo

#### Standard scripts

- `scripts/ops/common.sh`
- `scripts/ops/release.sh`
- `scripts/ops/init.sh`
- `scripts/ops/preflight.sh`
- `scripts/ops/deploy.sh`
- `scripts/ops/rollback.sh`
- `scripts/ops/verify.sh`

#### Project-local `.it-runner`

- `.it-runner/project.yaml`
- `.it-runner/envs/000-defaults.env`
- `.it-runner/envs/010-local.env`
- `.it-runner/meta/servers/*.env`
- `.it-runner/meta/deployments/*.env`
- selected-target tasks under `.it-runner/tasks/*/task.yaml`

#### `Makefile` entries

- `ops-targets`
- `ops-show-selected`
- `ops-release`
- `ops-init-selected`
- `ops-preflight-selected`
- `ops-deploy-selected`
- `ops-verify-selected`
- `ops-rollback-selected`
- `test-ops`

### Recommended test flow

1. `ops-targets`
2. `ops-show-selected`
3. `ops-release`
4. `ops-preflight-selected`
5. `ops-deploy-selected`
6. `ops-verify-selected`

### Validation checklist

- project can deploy to one real test server without `ops-fleet`
- `010-local.env` only contains local overrides
- `preflight` fails clearly on SSH or path problems
- `verify` checks real service state
- old duplicate legacy tasks are removed after the new flow is proven

### Exit criteria

- the business repo is the source of deployment truth
- one selected-target flow is working end to end on a test machine
- the project is ready for `ops-fleet` onboarding

## Phase 3: Production Onboarding And Rollout

### Goal

Connect the standardized business repo into `ops-fleet` without copying its deployment logic.

### Use these skills

- `ops-fleet-project-onboarding`
- `it-runner-workflow`

### Create in `ops-fleet`

#### Project metadata

- `.it-runner/meta/projects/<project>.env`

#### Production targets

- `.it-runner/meta/servers/*.env`
- `.it-runner/meta/<service>/deployments/*.env`

#### Thin wrappers

- `scripts/lib/project_runner.sh`
- `scripts/lib/<project>_meta.sh`
- `scripts/<project>/release_target.sh`
- `scripts/<project>/preflight_target.sh`
- `scripts/<project>/deploy_target.sh`
- `scripts/<project>/verify_target.sh`
- `scripts/<project>/rollback_target.sh`

#### Operator tasks

- `[Release] <service>`
- `[Project] targets`
- `[Project] show-selected`
- `[Project] preflight-selected`
- `[Project] deploy-selected`
- `[Project] verify-selected`
- `[Project] rollback-selected`

Optional ergonomic shortcuts:

- `[Canary] <service>-<first-host>`
- `[Promote] <service>-<next-host>`

### Recommended production flow

1. release artifact
2. select canary target
3. preflight canary
4. deploy canary
5. verify canary
6. promote to additional targets
7. rollback by release ID if needed

### Validation checklist

- wrapper tasks call business repo scripts rather than reimplementing deploy logic
- target metadata is production-specific and independent from business-repo test metadata
- production server resources are separated from per-service deployment instances
- canary path is proven before broad rollout
- rollback path is documented and tested at least once

### Exit criteria

- production task surface is small and operator-friendly
- project rollout is controlled by `ops-fleet`
- project deployment logic still lives in the business repo

## Troubleshooting Track

Use `it-runner-workflow` whenever any of these appear:
- task missing from UI/API
- `task.version missing`
- `envs-next` is wrong
- `logsDir` or `tasksDir` expands incorrectly
- task exists on disk but is not discoverable
- need to inspect or patch `it-runner` itself

## Suggested Sequence For New Services

1. Read `skills/INDEX.md`
2. Use `skills/TRIGGERS.md` to choose the first skill
3. Use `skills/TEMPLATES.md` to create the first folder layout
4. Follow this runbook to move from design → test deploy → production onboarding

## Related Files

- `skills/INDEX.md`
- `skills/TRIGGERS.md`
- `skills/TEMPLATES.md`
- `skills/SECOND-SERVICE-CHECKLIST.md`
- `skills/deployment-model-design/SKILL.md`
- `skills/project-deploy-standardization/SKILL.md`
- `skills/ops-fleet-project-onboarding/SKILL.md`
- `skills/it-runner-workflow/SKILL.md`
