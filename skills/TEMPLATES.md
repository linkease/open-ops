# Deployment Skill Templates

This file is a minimal engineering template checklist for future services that want to follow the same deployment model used for `tlsproxy`.

## 1. Business Repo Template

Use this when a business repository should be able to deploy to its own test servers without depending on `ops-fleet`.

### Recommended layout

```text
<project>/
  Makefile
  scripts/
    ops/
      common.sh
      release.sh
      init.sh
      preflight.sh
      deploy.sh
      rollback.sh
      verify.sh
    it-runner/
      ops_target_meta.sh
      ops_list_targets.sh
      ops_show_selected.sh
      ops_init_selected.sh
      ops_preflight_selected.sh
      ops_deploy_selected.sh
      ops_verify_selected.sh
      ops_rollback_selected.sh
  .it-runner/
    project.yaml
    envs/
      000-defaults.env
      010-local.env
      080-secret-local.env.example
    meta/
      servers/
        example-test-host.env.example
      deployments/
        example-test-host.env.example
      local.env.example
    tasks/
      ops-targets/task.yaml
      ops-show-selected/task.yaml
      ops-release/task.yaml
      ops-init-selected/task.yaml
      ops-preflight-selected/task.yaml
      ops-deploy-selected/task.yaml
      ops-verify-selected/task.yaml
      ops-rollback-selected/task.yaml
      test-ops/task.yaml
  docs/
    runbooks/
      it-runner-test-deploy.md
```

### Minimal checklist

- `scripts/ops/*.sh` exists and is non-interactive
- `.it-runner/meta/servers/*.env` only stores SSH/server connection information
- `.it-runner/meta/deployments/*.env` stores project deployment-instance information
- `.it-runner/envs/010-local.env` only stores local overrides and selectors
- `.it-runner` tasks use selected-target workflow
- `Makefile` exposes `ops-*` commands and `test-ops`

## 2. Ops-Fleet Template

Use this when a standardized business project is ready to be onboarded into production orchestration.

### Recommended layout

```text
ops-fleet/
  .it-runner/
    project.yaml
    envs/
      000-defaults.env
      080-secret-local.env.example
    meta/
      servers/
        prod-a.env
        prod-b.env
      projects/
        example-service.env
      example-service/
        deployments/
          prod-a.env
          prod-b.env
    tasks/
      manual/
        example-targets/task.yaml
        example-show-selected/task.yaml
        example-release/task.yaml
        example-preflight-selected/task.yaml
        example-deploy-selected/task.yaml
        example-verify-selected/task.yaml
        example-rollback-selected/task.yaml
  scripts/
    lib/
      project_runner.sh
      example_meta.sh
    example/
      release_target.sh
      preflight_target.sh
      deploy_target.sh
      verify_target.sh
      rollback_target.sh
  docs/
    runbooks/
      example-release.md
```

### Minimal checklist

- project registration metadata exists in `.it-runner/meta/projects/`
- shared server resources exist in `.it-runner/meta/servers/`
- production deployment instances exist in `.it-runner/meta/<service>/deployments/`
- wrapper scripts call the business repo's `scripts/ops/*.sh`
- `ops-fleet` does not duplicate project deploy implementation
- operator-facing tasks are small and intention-revealing

## 3. It-Runner Task Template

### Minimal `project.yaml`

```yaml
name: example-service
tasksDir: .it-runner/tasks
logsDir: ${DATA_ROOT}/logs
envFiles:
  - /outside/of/repo/secret-overrides.env
```

### Minimal `task.yaml`

```yaml
version: "1"
name: ops-show-selected
description: Show resolved deployment and referenced server for the selected target
tags: [ops, meta, show]
watch:
  stateFile: ${PROJECT_ROOT}/.it-runner/states/ops-show-selected.STATE
command:
  - bash
  - ./scripts/it-runner/ops_show_selected.sh
workdir: ${PROJECT_ROOT}
```

### Recommended `stateFile` control

If a task defines `watch.stateFile`, prefer these control commands:

- restart: `echo "RESTART $(date +%s)" > <STATE_FILE>`
- stop: `echo "STOP $(date +%s)" > <STATE_FILE>`

Use a fresh timestamp or token each time.

### Task authoring checklist

- task lives at `<task-dir>/task.yaml`
- `version: "1"` is present
- name is operator-friendly
- workdir points at `${PROJECT_ROOT}` when appropriate
- `watch.stateFile` is present when the task should support file-based stop/restart
- task is visible in API before deeper debugging

## 4. Standard Workflow Template

### Business repo test flow

1. `ops-targets`
2. `ops-show-selected`
3. `ops-release`
4. `ops-preflight-selected`
5. `ops-deploy-selected`
6. `ops-verify-selected`
7. `ops-rollback-selected` when needed

### Production onboarding flow

1. standardize the business repo first
2. register the project in `ops-fleet`
3. create production targets
4. create thin wrapper scripts
5. add production tasks
6. run canary preflight/deploy/verify
7. promote gradually

## 5. Reuse Rules

- Reuse the model, not necessarily the exact data files
- Keep business repo and `ops-fleet` metadata independent if needed
- Allow the same host to appear in both places when it acts as a test host in one repo and a production host in another
- Keep the deployment contract shared across repos
- Prefer removing legacy tasks after the new workflow is verified
- Add small regression tests when fixing `it-runner` behavior
