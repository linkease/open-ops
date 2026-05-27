# Ops It-Runner Nodeagent Task Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy `winagent`-based `ops/.it-runner` task set with a current `nodeagent` + `agenthub` + `agentctl` task model split into infrastructure tasks and remote-control tasks.

**Architecture:** Keep `ops/.it-runner` as a thin orchestration layer. Infrastructure tasks wrap `make build-bundle`, `make publish-demo`, and a long-running local `agenthub` server script; remote-control tasks wrap `agentctl` against one visible demo `agent-task.yaml` directory. The implementation rewrites checked-in env/docs/tasks/scripts and removes old `winagent_*` entrypoints entirely.

**Tech Stack:** Bash, YAML task configs, Go-based `it-runner`/`agentctl`/`agenthub`/`nodeagentd`, `rg`, `git`

---

## File Structure

### Create

- `.it-runner/tasks/nodeagent_build_bundle/task.yaml`
- `.it-runner/tasks/nodeagent_publish_demo/task.yaml`
- `.it-runner/tasks/agenthub_linux_server/task.yaml`
- `.it-runner/tasks/agentctl_agent_list/task.yaml`
- `.it-runner/tasks/agentctl_task_apply_demo/task.yaml`
- `.it-runner/tasks/agentctl_task_apply_demo/agent-task.yaml`
- `.it-runner/tasks/agentctl_task_restart_demo/task.yaml`
- `.it-runner/tasks/agentctl_task_status_demo/task.yaml`
- `.it-runner/tasks/agentctl_task_logs_demo/task.yaml`
- `.it-runner/scripts/run_nodeagent_build_bundle.sh`
- `.it-runner/scripts/run_nodeagent_publish_demo.sh`
- `.it-runner/scripts/run_agenthub_linux_server.sh`
- `.it-runner/scripts/check_agenthub_linux_server.sh`
- `.it-runner/scripts/agentctl-agent-list.sh`
- `.it-runner/scripts/agentctl-task-apply.sh`
- `.it-runner/scripts/agentctl-task-restart.sh`
- `.it-runner/scripts/agentctl-task-status.sh`
- `.it-runner/scripts/agentctl-task-logs.sh`

### Modify

- `.it-runner/README.md`
- `.it-runner/envs/000-defaults.env`
- `.it-runner/env-templates/010-local.env.example`

### Remove

- `.it-runner/tasks/winagent_build_bundle/task.yaml`
- `.it-runner/tasks/winagent_publish_demo/task.yaml`
- `.it-runner/tasks/winagent_publish_manual_bundle/task.yaml`
- `.it-runner/tasks/winagent_linux_server/task.yaml`
- `.it-runner/scripts/run_winagent_build_bundle.sh`
- `.it-runner/scripts/run_winagent_publish_demo.sh`
- `.it-runner/scripts/run_winagent_publish_manual_bundle.sh`
- `.it-runner/scripts/run_winagent_linux_server.sh`
- `.it-runner/scripts/check_winagent_linux_server.sh`

### Verification Targets

- `cd it-runner && go run ./cmd/it_runner --project .. --check-project-envs`
- `make -C it-runner build-bundle`
- `make -C it-runner publish-demo`
- `cd it-runner && go test ./cmd/agentctl ./cmd/agenthub ./cmd/nodeagentd ./internal/agenthubhttpapi ./internal/nodeagentconfig`
- `rg -n "WINAGENT_|winagent_|controlapi|agentd.exe|/config/demo-data/winagent" .it-runner`

### Task 1: Rewrite Shared Env and README

**Files:**
- Modify: `.it-runner/envs/000-defaults.env`
- Modify: `.it-runner/env-templates/010-local.env.example`
- Modify: `.it-runner/README.md`

- [ ] **Step 1: Capture the legacy baseline**

Run: `rg -n "WINAGENT_|winagent_|controlapi|agentd.exe|/config/demo-data/winagent" .it-runner`
Expected: Matches in `.it-runner/envs/000-defaults.env`, `.it-runner/env-templates/010-local.env.example`, `.it-runner/README.md`, and legacy task/script files.

- [ ] **Step 2: Replace shared defaults with nodeagent naming**

Update `.it-runner/envs/000-defaults.env` to:

```env
OPS_DATA_ROOT=/config/demo-data/ops
ITRUNNER_REPO_DIR=${PROJECT_ROOT}/it-runner
NODEAGENT_DATA_ROOT=/config/demo-data/nodeagent
AGENTCTL_BIN=${ITRUNNER_REPO_DIR}/bin/agentctl
AGENTCTL_SERVER=http://127.0.0.1:28080
AGENTHUB_ADDR=:28080
AGENT_ID=nodeagent-dev-box-01
AGENT_SSH_HOST=127.0.0.1
AGENT_SSH_PORT=22
AGENT_SSH_USER=${USER}
AGENT_REMOTE_BIND_PORT=59080
AGENT_API_PORT=57831
AGENT_KEY_PATH=/config/demo-data/keys/nodeagent-dev-box-01.key
```

- [ ] **Step 3: Replace local env template with new machine-local knobs**

Update `.it-runner/env-templates/010-local.env.example` to:

```env
# Copy to .it-runner/envs/010-local.env and adjust for your environment.
AGENTCTL_SERVER=http://127.0.0.1:28080
AGENT_ID=nodeagent-dev-box-01
AGENT_TASK_DIR=${PROJECT_ROOT}/.it-runner/tasks/agentctl_task_apply_demo
AGENT_SSH_HOST=192.168.9.19
AGENT_SSH_PORT=3022
AGENT_SSH_USER=abc
AGENT_KEY_PATH=/config/demo-data/keys/nodeagent-dev-box-01.key
```

- [ ] **Step 4: Rewrite `.it-runner/README.md` around the new task families**

Replace the task overview with:

```md
# ops/.it-runner

Shared infrastructure and remote-control `it-runner` tasks for the `/projects/workspace-linkease-ubuntu/ops` repo.

Task families:
- `nodeagent_build_bundle`: build `agentctl`, `nodeagentd`, and Linux `agenthub` bundle artifacts under `it-runner/bin/nodeagent-bundle/`.
- `nodeagent_publish_demo`: publish the current nodeagent demo bundle into `/config/demo-data/nodeagent`.
- `agenthub_linux_server`: ensure bundle outputs exist, prepare demo runtime files, and run the shared Linux `agenthub`.
- `agentctl_agent_list`: verify `agenthub` reachability and list registered agents.
- `agentctl_task_apply_demo`: apply the checked-in demo remote task definition through `agentctl`.
- `agentctl_task_restart_demo`: restart the checked-in demo remote task through `agentctl`.
- `agentctl_task_status_demo`: fetch demo remote task status through `agentctl`.
- `agentctl_task_logs_demo`: fetch demo remote task logs through `agentctl`.

Recommended usage:
1. Run `agenthub_linux_server` in the ops repo UI.
2. Verify connectivity with `agentctl_agent_list`.
3. Use the `agentctl_task_*_demo` tasks to operate on the checked-in demo remote task.
```

- [ ] **Step 5: Run project env check**

Run: `cd it-runner && go run ./cmd/it_runner --project .. --check-project-envs`
Expected: No warnings about legacy `.env` usage; no requirement to keep `WINAGENT_*` variables.

- [ ] **Step 6: Commit**

```bash
git add .it-runner/envs/000-defaults.env .it-runner/env-templates/010-local.env.example .it-runner/README.md
git commit -m "Rewrite ops it-runner envs for nodeagent tasks"
```

### Task 2: Replace Legacy Infrastructure Scripts and Tasks

**Files:**
- Create: `.it-runner/scripts/run_nodeagent_build_bundle.sh`
- Create: `.it-runner/scripts/run_nodeagent_publish_demo.sh`
- Create: `.it-runner/scripts/run_agenthub_linux_server.sh`
- Create: `.it-runner/scripts/check_agenthub_linux_server.sh`
- Create: `.it-runner/tasks/nodeagent_build_bundle/task.yaml`
- Create: `.it-runner/tasks/nodeagent_publish_demo/task.yaml`
- Create: `.it-runner/tasks/agenthub_linux_server/task.yaml`
- Remove: `.it-runner/scripts/run_winagent_build_bundle.sh`
- Remove: `.it-runner/scripts/run_winagent_publish_demo.sh`
- Remove: `.it-runner/scripts/run_winagent_linux_server.sh`
- Remove: `.it-runner/scripts/check_winagent_linux_server.sh`
- Remove: `.it-runner/scripts/run_winagent_publish_manual_bundle.sh`
- Remove: `.it-runner/tasks/winagent_build_bundle/task.yaml`
- Remove: `.it-runner/tasks/winagent_publish_demo/task.yaml`
- Remove: `.it-runner/tasks/winagent_publish_manual_bundle/task.yaml`
- Remove: `.it-runner/tasks/winagent_linux_server/task.yaml`

- [ ] **Step 1: Write the new infrastructure runner scripts**

Create `.it-runner/scripts/run_nodeagent_build_bundle.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

itrunner_repo_dir="${ITRUNNER_REPO_DIR:-$(pwd)/it-runner}"
make -C "$itrunner_repo_dir" build-bundle
```

Create `.it-runner/scripts/run_nodeagent_publish_demo.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

itrunner_repo_dir="${ITRUNNER_REPO_DIR:-$(pwd)/it-runner}"
make -C "$itrunner_repo_dir" publish-demo
```

Create `.it-runner/scripts/check_agenthub_linux_server.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

agentctl_server="${AGENTCTL_SERVER:-http://127.0.0.1:28080}"
probe_url="${agentctl_server}/v1/agents"

for _ in $(seq 1 100); do
  if curl -fsS "$probe_url" >/dev/null 2>&1; then
    printf 'agenthub ready: %s\n' "$probe_url"
    exit 0
  fi
  sleep 0.2
done

echo "agenthub not ready: $probe_url" >&2
exit 1
```

- [ ] **Step 2: Implement the long-running `agenthub` server script**

Create `.it-runner/scripts/run_agenthub_linux_server.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

data_root="${NODEAGENT_DATA_ROOT:-/config/demo-data/nodeagent}"
agenthub_addr="${AGENTHUB_ADDR:-:28080}"
agentctl_server="${AGENTCTL_SERVER:-http://127.0.0.1:28080}"
agent_id="${AGENT_ID:-nodeagent-dev-box-01}"
ssh_host="${AGENT_SSH_HOST:-127.0.0.1}"
ssh_port="${AGENT_SSH_PORT:-22}"
ssh_user="${AGENT_SSH_USER:-${USER:-root}}"
remote_bind_port="${AGENT_REMOTE_BIND_PORT:-59080}"
agent_api_port="${AGENT_API_PORT:-57831}"
key_path="${AGENT_KEY_PATH:-/config/demo-data/keys/nodeagent-dev-box-01.key}"
itrunner_repo_dir="${ITRUNNER_REPO_DIR:-$(pwd)/it-runner}"

make -C "$itrunner_repo_dir" build-bundle >/dev/stderr
mkdir -p "$data_root"
mkdir -p "$data_root/packages"
rm -rf "$data_root/windows" "$data_root/darwin" "$data_root/linux" "$data_root/examples"
cp -R "$itrunner_repo_dir/bin/nodeagent-bundle/windows" "$data_root/windows"
cp -R "$itrunner_repo_dir/bin/nodeagent-bundle/darwin" "$data_root/darwin"
cp -R "$itrunner_repo_dir/bin/nodeagent-bundle/linux" "$data_root/linux"
cp -R "$itrunner_repo_dir/bin/nodeagent-bundle/examples" "$data_root/examples"
cp "$itrunner_repo_dir/bin/nodeagent-bundle/README.md" "$data_root/README.md"

tmp_dir="$(mktemp -d)"
mkdir -p "$tmp_dir/bin"
cat >"$tmp_dir/bin/echo.bat" <<'EOF'
@echo hello-from-nodeagent-package
EOF
(
  cd "$tmp_dir"
  python3 -m zipfile -c "$data_root/packages/echo-demo.zip" bin/echo.bat
)
rm -rf "$tmp_dir"

cat >"$data_root/agent.yaml" <<EOF
agentId: "$agent_id"
dataRoot: data
tasksFile: examples/tasks.yaml
controlApiBaseUrl: "$agentctl_server"
localApi:
  bindAddress: 127.0.0.1
  port: $agent_api_port
ssh:
  serverAddr: "$ssh_host:$ssh_port"
  username: "$ssh_user"
  privateKeyPath: "$key_path"
  tunnels:
    - name: agenthub
      mode: local
      localBind: "127.0.0.1:${agenthub_addr##*:}"
      remoteTarget: "127.0.0.1:${agenthub_addr##*:}"
    - name: agentapi
      mode: remote
      remoteBind: "127.0.0.1:$remote_bind_port"
      localTarget: "127.0.0.1:$agent_api_port"
EOF

cd "$data_root"
exec env CONTROLAPI_ADDR="$agenthub_addr" ./linux/agenthub
```

- [ ] **Step 3: Replace the visible infrastructure task directories**

Create `.it-runner/tasks/nodeagent_build_bundle/task.yaml`:

```yaml
name: nodeagent_build_bundle
description: "Shared infrastructure task: build the nodeagent bundle artifacts."
tags: ["nodeagent", "infra", "build"]
version: "1"

watch:
  stateFile: "${PROJECT_ROOT}/.it-runner/tasks/nodeagent_build_bundle/STATE"

run:
  cmds:
    - |-
      bash -lc 'exec "${PROJECT_ROOT}/.it-runner/scripts/run_nodeagent_build_bundle.sh"'
```

Create `.it-runner/tasks/nodeagent_publish_demo/task.yaml`:

```yaml
name: nodeagent_publish_demo
description: "Shared infrastructure task: publish the nodeagent demo bundle into /config/demo-data/nodeagent."
tags: ["nodeagent", "infra", "publish"]
version: "1"

watch:
  stateFile: "${PROJECT_ROOT}/.it-runner/tasks/nodeagent_publish_demo/STATE"

run:
  cmds:
    - |-
      bash -lc 'exec "${PROJECT_ROOT}/.it-runner/scripts/run_nodeagent_publish_demo.sh"'
```

Create `.it-runner/tasks/agenthub_linux_server/task.yaml`:

```yaml
name: agenthub_linux_server
description: "Shared infrastructure task: build bundle outputs, prepare nodeagent demo files, and run Linux agenthub."
tags: ["agenthub", "nodeagent", "infra", "server"]
version: "1"

watch:
  stateFile: "${PROJECT_ROOT}/.it-runner/tasks/agenthub_linux_server/STATE"

processes:
  - name: agenthub-linux
    cmd: |-
      bash -lc 'exec "${PROJECT_ROOT}/.it-runner/scripts/run_agenthub_linux_server.sh"'

run:
  cmds:
    - |-
      bash -lc 'exec "${PROJECT_ROOT}/.it-runner/scripts/check_agenthub_linux_server.sh"'
```

- [ ] **Step 4: Verify task discovery and infra commands**

Run: `cd it-runner && go run ./cmd/it_runner --project .. --check-project-envs`
Expected: Task discovery succeeds with `nodeagent_build_bundle`, `nodeagent_publish_demo`, and `agenthub_linux_server`.

Run: `make -C it-runner build-bundle`
Expected: `bin/nodeagent-bundle/windows/nodeagentd.exe` and `bin/nodeagent-bundle/linux/agenthub` exist.

Run: `make -C it-runner publish-demo`
Expected: Output mentions `/config/demo-data/nodeagent`.

- [ ] **Step 5: Commit**

```bash
git add .it-runner/scripts/run_nodeagent_build_bundle.sh .it-runner/scripts/run_nodeagent_publish_demo.sh .it-runner/scripts/run_agenthub_linux_server.sh .it-runner/scripts/check_agenthub_linux_server.sh .it-runner/tasks/nodeagent_build_bundle/task.yaml .it-runner/tasks/nodeagent_publish_demo/task.yaml .it-runner/tasks/agenthub_linux_server/task.yaml .it-runner/scripts .it-runner/tasks
git commit -m "Replace ops winagent infra tasks with nodeagent tasks"
```

### Task 3: Add the `agentctl` Remote-Control Task Family

**Files:**
- Create: `.it-runner/scripts/agentctl-agent-list.sh`
- Create: `.it-runner/scripts/agentctl-task-apply.sh`
- Create: `.it-runner/scripts/agentctl-task-restart.sh`
- Create: `.it-runner/scripts/agentctl-task-status.sh`
- Create: `.it-runner/scripts/agentctl-task-logs.sh`
- Create: `.it-runner/tasks/agentctl_agent_list/task.yaml`
- Create: `.it-runner/tasks/agentctl_task_apply_demo/task.yaml`
- Create: `.it-runner/tasks/agentctl_task_apply_demo/agent-task.yaml`
- Create: `.it-runner/tasks/agentctl_task_restart_demo/task.yaml`
- Create: `.it-runner/tasks/agentctl_task_status_demo/task.yaml`
- Create: `.it-runner/tasks/agentctl_task_logs_demo/task.yaml`

- [ ] **Step 1: Copy the thin `agentctl` wrappers into ops scripts**

Create `.it-runner/scripts/agentctl-agent-list.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${AGENTCTL_BIN:?AGENTCTL_BIN is required}"
: "${AGENTCTL_SERVER:?AGENTCTL_SERVER is required}"

"${AGENTCTL_BIN}" --server "${AGENTCTL_SERVER}" --output json agent list
```

Create `.it-runner/scripts/agentctl-task-apply.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${AGENTCTL_BIN:?AGENTCTL_BIN is required}"
: "${AGENTCTL_SERVER:?AGENTCTL_SERVER is required}"
: "${AGENT_ID:?AGENT_ID is required}"
: "${AGENT_TASK_DIR:?AGENT_TASK_DIR is required}"

"${AGENTCTL_BIN}" --server "${AGENTCTL_SERVER}" --output json task apply \
  --agent-id "${AGENT_ID}" \
  --task-dir "${AGENT_TASK_DIR}"
```

Create `.it-runner/scripts/agentctl-task-restart.sh`, `.it-runner/scripts/agentctl-task-status.sh`, and `.it-runner/scripts/agentctl-task-logs.sh` by swapping only the subcommand to `restart`, `status`, and `logs`.

- [ ] **Step 2: Add the visible remote-control task directories**

Create `.it-runner/tasks/agentctl_agent_list/task.yaml`:

```yaml
version: "1"
name: agentctl_agent_list
description: List reachable remote agents through agentctl
tags: [agentctl, remote, list]
watch:
  stateFile: ${PROJECT_ROOT}/.it-runner/tasks/agentctl_agent_list/STATE
logs:
  rootDir: .it-runner/logs
workspace:
  workdir: ${PROJECT_ROOT}
run:
  cmds:
    - ./.it-runner/scripts/agentctl-agent-list.sh
```

Create `.it-runner/tasks/agentctl_task_apply_demo/task.yaml`:

```yaml
version: "1"
name: agentctl_task_apply_demo
description: Apply the checked-in demo remote task through agentctl
tags: [agentctl, remote, apply]
watch:
  stateFile: ${PROJECT_ROOT}/.it-runner/tasks/agentctl_task_apply_demo/STATE
logs:
  rootDir: .it-runner/logs
workspace:
  workdir: ${PROJECT_ROOT}
run:
  cmds:
    - ./.it-runner/scripts/agentctl-task-apply.sh
```

Create `.it-runner/tasks/agentctl_task_restart_demo/task.yaml`, `.it-runner/tasks/agentctl_task_status_demo/task.yaml`, and `.it-runner/tasks/agentctl_task_logs_demo/task.yaml` with the same structure, using the matching script and task name.

- [ ] **Step 3: Check in the shared demo remote task definition**

Create `.it-runner/tasks/agentctl_task_apply_demo/agent-task.yaml`:

```yaml
taskId: ops-demo-echo
displayName: Ops Demo Echo
packageName: echo-demo.zip
version: dev
workDir: ${AGENT_DATA}/apps/${TASK_ID}
command: cmd.exe
args:
  - /c
  - echo
  - hello-from-ops-demo
  - in
  - ${TASK_LOG_DIR}
env: {}
logDir: ${AGENT_DATA}/logs/${TASK_ID}
stopMode: kill
```

Set `AGENT_TASK_DIR` in `.it-runner/envs/010-local.env` to `${PROJECT_ROOT}/.it-runner/tasks/agentctl_task_apply_demo` when verifying locally.

- [ ] **Step 4: Run the lightweight command verification**

Run: `cd it-runner && go test ./cmd/agentctl ./cmd/agenthub ./cmd/nodeagentd ./internal/agenthubhttpapi ./internal/nodeagentconfig`
Expected: PASS.

Run: `cd it-runner && go run ./cmd/it_runner --project .. --check-project-envs`
Expected: The five `agentctl_*` task directories are discovered without config errors.

- [ ] **Step 5: Commit**

```bash
git add .it-runner/scripts/agentctl-agent-list.sh .it-runner/scripts/agentctl-task-apply.sh .it-runner/scripts/agentctl-task-restart.sh .it-runner/scripts/agentctl-task-status.sh .it-runner/scripts/agentctl-task-logs.sh .it-runner/tasks/agentctl_agent_list/task.yaml .it-runner/tasks/agentctl_task_apply_demo/task.yaml .it-runner/tasks/agentctl_task_apply_demo/agent-task.yaml .it-runner/tasks/agentctl_task_restart_demo/task.yaml .it-runner/tasks/agentctl_task_status_demo/task.yaml .it-runner/tasks/agentctl_task_logs_demo/task.yaml
git commit -m "Add ops agentctl remote-control tasks"
```

### Task 4: Remove Legacy Entry Points and Perform Final Verification

**Files:**
- Remove: all remaining `.it-runner/tasks/winagent_*`
- Remove: all remaining `.it-runner/scripts/run_winagent_*`
- Modify: any `.it-runner` file still mentioning `winagent` as the current model

- [ ] **Step 1: Delete the old task directories and scripts**

Remove these paths:

```text
.it-runner/tasks/winagent_build_bundle
.it-runner/tasks/winagent_publish_demo
.it-runner/tasks/winagent_publish_manual_bundle
.it-runner/tasks/winagent_linux_server
.it-runner/scripts/run_winagent_build_bundle.sh
.it-runner/scripts/run_winagent_publish_demo.sh
.it-runner/scripts/run_winagent_publish_manual_bundle.sh
.it-runner/scripts/run_winagent_linux_server.sh
.it-runner/scripts/check_winagent_linux_server.sh
```

- [ ] **Step 2: Verify the legacy terms are gone from live `.it-runner` entrypoints**

Run: `rg -n "WINAGENT_|winagent_|controlapi|agentd.exe|/config/demo-data/winagent" .it-runner`
Expected: No matches in live `.it-runner` envs, README, tasks, or scripts. Historical references are allowed only outside `.it-runner` if needed.

- [ ] **Step 3: Run end-to-end infra verification**

Run: `make -C it-runner build-bundle`
Expected: PASS and prints `bundle created`.

Run: `make -C it-runner publish-demo`
Expected: PASS and prints `published to /config/demo-data/nodeagent`.

Run: `cd it-runner && go run ./cmd/it_runner --project .. --check-project-envs`
Expected: PASS with only the new task names visible.

- [ ] **Step 4: Run long-lived control-plane smoke verification**

Run: `bash -lc 'exec ./.it-runner/scripts/run_agenthub_linux_server.sh'`
Expected: Process starts, publishes `packages/echo-demo.zip`, and does not reference `agentd.exe`.

In a second shell, run: `bash ./.it-runner/scripts/check_agenthub_linux_server.sh`
Expected: Prints `agenthub ready: http://127.0.0.1:28080/v1/agents` or the configured equivalent.

- [ ] **Step 5: Commit**

```bash
git add .it-runner
git commit -m "Clean up legacy winagent ops tasks"
```

## Self-Review

- Spec coverage:
  - task-family split is implemented by Task 2 and Task 3
  - env and naming migration is implemented by Task 1
  - old task/script removal is implemented by Task 4
  - acceptance checks are covered by Task 2 Step 4, Task 3 Step 4, and Task 4 Step 3-4
- Placeholder scan:
  - no `TODO` / `TBD`
  - each code-writing step includes concrete file contents
- Type and name consistency:
  - uses one naming set throughout: `nodeagent_build_bundle`, `nodeagent_publish_demo`, `agenthub_linux_server`, `agentctl_*`
  - uses one env surface throughout: `NODEAGENT_DATA_ROOT`, `AGENTCTL_BIN`, `AGENTCTL_SERVER`, `AGENT_ID`, `AGENT_TASK_DIR`
