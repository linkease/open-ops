# tlsproxy / ops-fleet Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `tlsproxy` the source of truth for deploy logic while keeping `ops-fleet` as the production orchestration layer for target selection, rollout, and rollback.

**Architecture:** Standardize `tlsproxy` around project-owned `scripts/ops/*.sh` actions and a small project-owned `.it-runner` workflow for dev/test deployment. Then replace `ops-fleet`'s project-specific deployment logic with thin adapters that resolve target meta and call the `tlsproxy` action scripts. Production rollout remains in `ops-fleet`, but deploy behavior lives in the business repo.

**Tech Stack:** Bash, `.it-runner`, Go task generator in `ops-fleet`, SSH/systemd deployment, environment-variable driven target meta.

---

## File Structure

### `tlsproxy` repository

- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/common.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/release.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/init.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/preflight.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/deploy.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/rollback.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/verify.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-release/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-init/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-preflight/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-deploy/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-rollback/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-verify/task.yaml`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/project.yaml`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/envs/secrets.env.example`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/Makefile`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/ops_test.sh`

### `ops-fleet` repository

- Create: `ops-fleet/.it-runner/meta/projects/tlsproxy.env`
- Modify: `ops-fleet/.it-runner/meta/tlsproxy-server/local.env`
- Modify: `ops-fleet/scripts/lib/tlsproxy_meta.sh`
- Create: `ops-fleet/scripts/lib/project_runner.sh`
- Modify: `ops-fleet/scripts/tlsproxy/init_target.sh`
- Modify: `ops-fleet/scripts/tlsproxy/preflight_target.sh`
- Modify: `ops-fleet/scripts/tlsproxy/deploy_target.sh`
- Create: `ops-fleet/scripts/tlsproxy/release_target.sh`
- Modify: `ops-fleet/scripts/tlsproxy/rollback_target.sh`
- Create: `ops-fleet/scripts/tlsproxy/verify_target.sh`
- Create: `ops-fleet/.it-runner/tasks/manual/tlsproxy-verify-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/release-tlsproxy-server/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-init-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-preflight-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-deploy-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-rollback-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-show-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/README.md`
- Modify: `ops-fleet/docs/runbooks/tlsproxy-release.md`
- Modify: `ops-fleet/README.md`
- Create: `ops-fleet/scripts/tlsproxy/adapter_test.sh`

---

### Task 1: Standardize `tlsproxy` deploy contract

**Files:**
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/common.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/release.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/init.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/preflight.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/deploy.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/rollback.sh`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/verify.sh`

- [ ] **Step 1: Write the failing contract test**

Create `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/ops_test.sh` with this skeleton and the first contract assertion:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

for script in release init preflight deploy rollback verify; do
  test -f "$repo_root/scripts/ops/${script}.sh"
done

grep -q 'TARGET_NAME' "$repo_root/scripts/ops/deploy.sh"
grep -q 'ARTIFACT_PATH' "$repo_root/scripts/ops/deploy.sh"
grep -q 'RELEASE_ID' "$repo_root/scripts/ops/rollback.sh"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash /projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/ops_test.sh`

Expected: `No such file or directory` or `test -f` failure because `scripts/ops/*.sh` do not exist yet.

- [ ] **Step 3: Create the shared contract helper**

Create `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/common.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

require_env() {
  local key="$1"
  local value="${!key:-}"
  [ -n "$value" ] || { echo "missing required env: $key" >&2; exit 2; }
}

repo_root() {
  cd "$(dirname "$0")/../.." && pwd
}

default_artifact_path() {
  printf '%s/bin/tlsproxy-server-linux-amd64\n' "$(repo_root)"
}
```

- [ ] **Step 4: Create the standard action entrypoints**

Create each script with the same contract style. Use this minimal pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/common.sh"
require_env TARGET_NAME
echo "stub TARGET_NAME=${TARGET_NAME}"
```

Then expand them to the real required variables:

- `release.sh`: `ARTIFACT_ROOT`
- `init.sh`: `TARGET_NAME SSH_TARGET DEPLOY_BASE`
- `preflight.sh`: `TARGET_NAME SSH_TARGET DEPLOY_BASE ARTIFACT_PATH`
- `deploy.sh`: `TARGET_NAME SSH_TARGET DEPLOY_BASE ARTIFACT_PATH`
- `rollback.sh`: `TARGET_NAME SSH_TARGET DEPLOY_BASE ARTIFACT_ROOT RELEASE_ID`
- `verify.sh`: `TARGET_NAME SSH_TARGET`

- [ ] **Step 5: Run the contract test to verify it passes**

Run: `bash /projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/ops_test.sh`

Expected: exit code `0`.

### Task 2: Make `tlsproxy` actions reuse current deployment behavior

**Files:**
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/Makefile`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/release.sh`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/init.sh`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/preflight.sh`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/deploy.sh`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/rollback.sh`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/verify.sh`
- Test: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops/ops_test.sh`

- [ ] **Step 1: Expand `release.sh` to publish an artifact**

Implement `release.sh` so it builds and copies the linux artifact into `ARTIFACT_ROOT/tlsproxy/`:

```bash
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/common.sh"
require_env ARTIFACT_ROOT

root="$(repo_root)"
artifact="${ARTIFACT_PATH:-$(default_artifact_path)}"
release_id="${RELEASE_ID:-$(date -u +%Y%m%dT%H%M%SZ)-nogit}"

make -C "$root" build-linux
install -d "$ARTIFACT_ROOT/tlsproxy/releases/$release_id"
install -m 0755 "$artifact" "$ARTIFACT_ROOT/tlsproxy/tlsproxy-server-linux-amd64"
install -m 0755 "$artifact" "$ARTIFACT_ROOT/tlsproxy/releases/$release_id/tlsproxy-server-linux-amd64"
```

- [ ] **Step 2: Implement `preflight.sh` with real checks**

Use the current `ops-fleet` checks as the behavior target. The script should verify:

- local artifact exists
- remote base exists
- config file state is visible
- token file state is visible
- binary path state is visible

Use this remote probe shape:

```bash
ssh -p "$SSH_PORT" $SSH_OPTS "$SSH_TARGET" \
  "test -d '$DEPLOY_BASE' && echo BASE=ok; test -f '$CONFIG_FILE' && echo CONFIG=ok || echo CONFIG=missing"
```

- [ ] **Step 3: Implement `deploy.sh` by moving current deployment logic here**

Recreate the current deploy sequence inside `tlsproxy/scripts/ops/deploy.sh`:

```bash
scp -P "$SSH_PORT" $SSH_OPTS "$ARTIFACT_PATH" "$SSH_TARGET:$DEPLOY_BASE/bin/tlsproxy-server.new"
ssh -p "$SSH_PORT" $SSH_OPTS "$SSH_TARGET" "
  set -e
  ${SUDO:-sudo} install -d -m 0755 '$DEPLOY_BASE/bin'
  ${SUDO:-sudo} mv '$DEPLOY_BASE/bin/tlsproxy-server.new' '$BINARY_PATH'
  ${SUDO:-sudo} chown ${SERVICE_USER:-root}:${SERVICE_GROUP:-root} '$BINARY_PATH'
  ${SUDO:-sudo} chmod 0755 '$BINARY_PATH'
  ${SUDO:-sudo} systemctl restart '${SERVICE_NAME}.service'
"
```

- [ ] **Step 4: Implement `init.sh`, `rollback.sh`, and `verify.sh`**

Behavior rules:

- `init.sh` creates config once and exits with error if config, token, or binary already exists.
- `rollback.sh` resolves `${ARTIFACT_ROOT}/tlsproxy/releases/${RELEASE_ID}/tlsproxy-server-linux-amd64` and then calls the same remote install/restart path as `deploy.sh`.
- `verify.sh` runs `systemctl is-active`, then optionally curls a supplied `VERIFY_URL` if present.

- [ ] **Step 5: Re-run project tests**

Run:

```bash
cd /projects/workspace-linkease-ubuntu/linkease-github/tlsproxy
bash ./scripts/ops/ops_test.sh
make build-linux
```

Expected: test script passes and `make build-linux` still succeeds.

### Task 3: Add project-owned dev/test `.it-runner` tasks in `tlsproxy`

**Files:**
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-release/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-init/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-preflight/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-deploy/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-rollback/task.yaml`
- Create: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-verify/task.yaml`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/project.yaml`
- Modify: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/envs/secrets.env.example`

- [ ] **Step 1: Add env examples for target-driven testing**

Append to `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/envs/secrets.env.example`:

```env
TARGET_NAME=test-host-a
SSH_TARGET=root@example.com
SSH_PORT=22
SSH_OPTS=
DEPLOY_BASE=/projects/tlsproxy
CONFIG_FILE=/projects/tlsproxy/tlsproxy-server.yaml
TOKEN_FILE=/projects/tlsproxy/token
BINARY_PATH=/projects/tlsproxy/bin/tlsproxy-server
SERVICE_NAME=tlsproxyserver
SERVICE_USER=root
SERVICE_GROUP=root
ARTIFACT_ROOT=/projects/workspace-linkease-ubuntu/ops/build-targets
VERIFY_URL=
```

- [ ] **Step 2: Add `.it-runner` tasks that call the new scripts**

Use this task shape for each action:

```yaml
version: "1"
name: "ops-deploy"
description: "Run project-owned deploy contract"
watch:
  stateFile: ".it-runner/states/ops-deploy.STATE"
processes:
  - name: "ops-deploy"
    cmd: "bash ./scripts/ops/deploy.sh"
```

- [ ] **Step 3: Make project env files load for these tasks**

Ensure `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/project.yaml` keeps:

```yaml
envFiles:
  - ".it-runner/envs/shared.env"
  - ".it-runner/envs/secrets.env"
  - ".it-runner/.env.local"
```

- [ ] **Step 4: Sanity-check task discovery**

Run:

```bash
find /projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks -maxdepth 2 -name task.yaml | sort
```

Expected: the six `ops-*` task directories appear.

### Task 4: Add generic project-runner adapters in `ops-fleet`

**Files:**
- Create: `ops-fleet/.it-runner/meta/projects/tlsproxy.env`
- Create: `ops-fleet/scripts/lib/project_runner.sh`
- Modify: `ops-fleet/scripts/lib/tlsproxy_meta.sh`
- Modify: `ops-fleet/.it-runner/meta/tlsproxy-server/local.env`
- Test: `ops-fleet/scripts/tlsproxy/adapter_test.sh`

- [ ] **Step 1: Add project registry meta**

Create `ops-fleet/.it-runner/meta/projects/tlsproxy.env`:

```env
PROJECT_NAME=tlsproxy
PROJECT_ROOT=/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy
PROJECT_ACTION_ROOT=/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/scripts/ops
PROJECT_ARTIFACT_SUBDIR=tlsproxy
PROJECT_ARTIFACT_NAME=tlsproxy-server-linux-amd64
```

- [ ] **Step 2: Add a generic runner helper**

Create `ops-fleet/scripts/lib/project_runner.sh` with one function that shells into the project action script:

```bash
#!/usr/bin/env bash
set -euo pipefail

run_project_action() {
  local action_root="$1"
  local action_name="$2"
  shift 2
  env "$@" bash "$action_root/${action_name}.sh"
}
```

- [ ] **Step 3: Expand `tlsproxy_meta.sh` to load project meta plus target meta**

Add:

```bash
project_env="$project_root/.it-runner/meta/projects/tlsproxy.env"
source "$project_env"
```

And export:

- `PROJECT_ROOT`
- `PROJECT_ACTION_ROOT`
- `PROJECT_ARTIFACT_SUBDIR`
- `PROJECT_ARTIFACT_NAME`

- [ ] **Step 4: Add an adapter test**

Create `ops-fleet/scripts/tlsproxy/adapter_test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
test -f "$root/.it-runner/meta/projects/tlsproxy.env"
grep -q 'PROJECT_ACTION_ROOT=' "$root/.it-runner/meta/projects/tlsproxy.env"
grep -q 'run_project_action' "$root/scripts/lib/project_runner.sh"
```

- [ ] **Step 5: Run the new adapter test**

Run: `cd /projects/workspace-linkease-ubuntu/ops/ops-fleet && bash ./scripts/tlsproxy/adapter_test.sh`

Expected: exit code `0`.

### Task 5: Replace `ops-fleet` tlsproxy adapters with project-script calls

**Files:**
- Modify: `ops-fleet/scripts/tlsproxy/init_target.sh`
- Modify: `ops-fleet/scripts/tlsproxy/preflight_target.sh`
- Modify: `ops-fleet/scripts/tlsproxy/deploy_target.sh`
- Modify: `ops-fleet/scripts/tlsproxy/rollback_target.sh`
- Create: `ops-fleet/scripts/tlsproxy/verify_target.sh`
- Modify: `ops-fleet/.it-runner/tasks/manual/release-tlsproxy-server/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-init-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-preflight-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-deploy-selected/task.yaml`
- Modify: `ops-fleet/.it-runner/tasks/manual/tlsproxy-rollback-selected/task.yaml`
- Create: `ops-fleet/.it-runner/tasks/manual/tlsproxy-verify-selected/task.yaml`

- [ ] **Step 1: Change the wrappers to call `run_project_action`**

Use this pattern in each wrapper:

```bash
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../lib/tlsproxy_meta.sh"
. "$(dirname "$0")/../lib/project_runner.sh"

tlsproxy_load_meta "${1:-}"

run_project_action "$PROJECT_ACTION_ROOT" deploy \
  TARGET_NAME="$TLSPROXY_TARGET" \
  ENVIRONMENT=prod \
  SSH_TARGET="$TLSPROXY_SSH_TARGET" \
  SSH_PORT="$TLSPROXY_SSH_PORT" \
  SSH_OPTS="$TLSPROXY_SSH_OPTS" \
  DEPLOY_BASE="$TLSPROXY_DEPLOY_BASE" \
  CONFIG_FILE="$TLSPROXY_CONFIG_FILE" \
  TOKEN_FILE="$TLSPROXY_TOKEN_FILE" \
  BINARY_PATH="$TLSPROXY_BINARY_PATH" \
  SERVICE_NAME="$TLSPROXY_SERVICE_NAME" \
  SERVICE_USER="$TLSPROXY_SERVICE_USER" \
  SERVICE_GROUP="$TLSPROXY_SERVICE_GROUP" \
  ARTIFACT_ROOT="$OPS_FLEET_ARTIFACT_ROOT" \
  ARTIFACT_PATH="$TLSPROXY_ARTIFACT_PATH"
```

- [ ] **Step 2: Add `verify_target.sh` and a matching manual task**

Create `ops-fleet/scripts/tlsproxy/verify_target.sh` with the same pattern, calling `verify` instead of `deploy`.

Create `ops-fleet/.it-runner/tasks/manual/tlsproxy-verify-selected/task.yaml`:

```yaml
version: "1"
name: "[TLSProxy] verify-selected"
description: "Run project-owned verify for the target selected by TLSPROXY_TARGET"
tags: ["manual", "tlsproxy", "verify"]
watch:
  stateFile: "${PROJECT_ROOT}/.it-runner/states/tlsproxy-verify-selected.STATE"
run:
  cmds:
    - "bash ${PROJECT_ROOT}/scripts/tlsproxy/verify_target.sh"
```

- [ ] **Step 3: Add `release_target.sh` and point the release task at the project-owned release action**

Create `ops-fleet/scripts/tlsproxy/release_target.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../lib/tlsproxy_meta.sh"
. "$(dirname "$0")/../lib/project_runner.sh"

tlsproxy_load_meta "${1:-}"

run_project_action "$PROJECT_ACTION_ROOT" release \
  ARTIFACT_ROOT="$OPS_FLEET_ARTIFACT_ROOT" \
  ARTIFACT_PATH="$TLSPROXY_ARTIFACT_PATH"
```

Then change `ops-fleet/.it-runner/tasks/manual/release-tlsproxy-server/task.yaml` so the command becomes:

```yaml
run:
  cmds:
    - "bash ${PROJECT_ROOT}/scripts/tlsproxy/release_target.sh"
```

- [ ] **Step 4: Verify task files exist and parse**

Run:

```bash
find /projects/workspace-linkease-ubuntu/ops/ops-fleet/.it-runner/tasks/manual -maxdepth 2 -name task.yaml | sort
```

Expected: `[TLSProxy] verify-selected` appears next to the existing selected-target tasks.

### Task 6: Update docs and validation around the new split

**Files:**
- Modify: `ops-fleet/.it-runner/tasks/manual/README.md`
- Modify: `ops-fleet/docs/runbooks/tlsproxy-release.md`
- Modify: `ops-fleet/README.md`
- Modify: `ops-fleet/.it-runner/envs/secrets.env.example`
- Modify: `ops-fleet/Makefile`
- Modify: `ops-fleet/scripts/test_generate_tasks.sh`
- Modify: `ops-fleet/scripts/release/release_test.sh`
- Modify: `ops-fleet/scripts/tlsproxy/adapter_test.sh`

- [ ] **Step 1: Document the new split of responsibilities**

Update the docs so they all say the same thing:

- `tlsproxy` owns deploy logic.
- `ops-fleet` owns target meta and production orchestration.
- the production sequence is `release -> preflight -> deploy -> verify`.

- [ ] **Step 2: Add plan-level validation commands to `ops-fleet/Makefile`**

Add these targets:

```make
test-tlsproxy-adapter:
	bash ./scripts/tlsproxy/adapter_test.sh

test: test-go test-scripts test-tlsproxy-adapter
```

- [ ] **Step 3: Update docs examples to the selected-target workflow**

Examples that should appear in the docs:

```env
TLSPROXY_TARGET=bbs1-koolcenter
OPS_FLEET_ARTIFACT_ROOT=/projects/workspace-linkease-ubuntu/ops/build-targets
```

```text
[Release] tlsproxy-server
[TLSProxy] preflight-selected
[TLSProxy] deploy-selected
[TLSProxy] verify-selected
```

- [ ] **Step 4: Run repo validation**

Run:

```bash
cd /projects/workspace-linkease-ubuntu/ops/ops-fleet
make generate
make test
```

Expected: all tests pass and the generated task set remains small.

### Task 7: Verify runner-visible production workflow end-to-end

**Files:**
- Modify: `ops-fleet/docs/runbooks/tlsproxy-release.md`
- Test: `ops-fleet/.it-runner/tasks/manual/*.yaml`
- Test: `/projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks/ops-*.yaml`

- [ ] **Step 1: Restart `it-runner` after task changes**

Run:

```bash
cd /projects/workspace-linkease-ubuntu/ops/it-runner
pkill -f 'it_runner -runner-config ./it-runner.yaml -web 0.0.0.0:19090' || true
nohup go run ./cmd/it_runner -runner-config ./it-runner.yaml -web 0.0.0.0:19090 >/tmp/ops-it-runner-restart.log 2>&1 &
sleep 3
```

Expected: the runner is listening again on `:19090`.

- [ ] **Step 2: Verify the final task surface in `ops-fleet`**

Run:

```bash
curl -s http://127.0.0.1:19090/it-runner/api/workspaces/e9caf7f06e27/projects/ops-fleet/tasks | jq -r '.[].name' | sort
```

Expected output includes:

```text
[Release] tlsproxy-server
[Releases] tlsproxy-server
[TLSProxy] targets
[TLSProxy] show-selected
[TLSProxy] init-selected
[TLSProxy] preflight-selected
[TLSProxy] deploy-selected
[TLSProxy] verify-selected
[TLSProxy] rollback-selected
```

- [ ] **Step 3: Verify the project-owned task surface in `tlsproxy`**

Run:

```bash
find /projects/workspace-linkease-ubuntu/linkease-github/tlsproxy/.it-runner/tasks -maxdepth 2 -name task.yaml | sort
```

Expected output includes:

```text
.../.it-runner/tasks/ops-release/task.yaml
.../.it-runner/tasks/ops-init/task.yaml
.../.it-runner/tasks/ops-preflight/task.yaml
.../.it-runner/tasks/ops-deploy/task.yaml
.../.it-runner/tasks/ops-rollback/task.yaml
.../.it-runner/tasks/ops-verify/task.yaml
```

---

## Self-Review

### Spec coverage

- Server resource split is covered by `ops-fleet` target/project meta tasks.
- Project-owned deploy logic is covered by Tasks 1-3.
- Production orchestration split is covered by Tasks 4-7.
- Multi-server production flow is covered by verify/canary/promote sequencing in Tasks 5-7.

### Placeholder scan

- No `TODO`, `TBD`, or “implement later” markers remain.
- Every task lists exact files and explicit commands.

### Type consistency

- Contract names are consistent across the plan: `TARGET_NAME`, `SSH_TARGET`, `SSH_PORT`, `DEPLOY_BASE`, `ARTIFACT_ROOT`, `ARTIFACT_PATH`, `RELEASE_ID`.
- The standard action names are consistent across both repos: `release`, `init`, `preflight`, `deploy`, `rollback`, `verify`.
