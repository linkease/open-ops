# Skills Index

## 30-Second Start

- If you are not sure how to model deployment yet, start with `skills/deployment-model-design/SKILL.md`
- If you want a business repo to deploy to its own test server, start with `skills/project-deploy-standardization/SKILL.md`
- If you want to wire a project into `ops-fleet`, start with `skills/ops-fleet-project-onboarding/SKILL.md`
- If the problem is about `.it-runner` tasks, task visibility, logs, API, `envs-next`, or `.STATE` control, start with `skills/it-runner-workflow/SKILL.md`
- If the problem is about understanding a task name, task title, copied log path, or task-detail UI semantics, still start with `skills/it-runner-workflow/SKILL.md` and then load its task/log/UI references
- If the problem is about `agentd.exe`, `controlapi`, `agentctl`, remote Windows task application, or `agent-task.yaml`, start with `skills/it-runner-agentd-control/SKILL.md`
- If the problem is specifically about `.it-runner` env layering and naming, also read `skills/it-runner-workflow/references/env-conventions.md`
- If the problem is choosing the right `.it-runner` task model, also read `skills/it-runner-workflow/references/task-centric-patterns.md`
- If the problem is deciding which repo is the best current template or which repo to migrate next, also read `skills/it-runner-workflow/references/project-rollout-status.md`
- If the problem is upgrading a legacy `.it-runner` project to the new env conventions, start with `skills/it-runner-convention-upgrade/SKILL.md`
- If you just need commands, read `skills/IT-RUNNER-CHEATSHEET.md`
- If you want a folder/file starting point, read `skills/TEMPLATES.md`
- If this is the next real service after `tlsproxy`, read `skills/SECOND-SERVICE-CHECKLIST.md`

This folder contains reusable skills for engineering deployment workflows across business repositories, `ops-fleet`, and `it-runner`.

## Recommended Order

1. Use `deployment-model-design` when the deployment structure or repo boundaries are still unclear.
2. Use `project-deploy-standardization` when a business repo needs to own and stabilize its own deploy workflow.
3. Use `ops-fleet-project-onboarding` when a standardized project should be wired into production orchestration.
4. Use `it-runner-workflow` whenever `.it-runner` structure, task authoring, API debugging, or runner internals are part of the work.
5. Use `it-runner-agentd-control` whenever the task crosses into remote Windows agent control, package publication, or `agentctl`-driven operations.
6. Use `task-centric-patterns.md` to decide whether the repo should look like `tlsproxy`, `ddns-server`, `training`, or `ops-fleet`.
7. Use `project-rollout-status.md` to see which repos are already template-ready and which ones still need task-centric phase 2.
8. Use `it-runner-convention-upgrade` when an existing project must migrate from old env naming/layout to the strict numbered convention.

## Skill Selection

### `deployment-model-design`
- Path: `skills/deployment-model-design/SKILL.md`
- Use for: modeling `server`, `deployment`, `local overrides`, `release`, and `rollout`
- Typical prompts:
  - "How should we model one service across many servers?"
  - "How do we split business repo deployment logic from ops-fleet orchestration?"

### `project-deploy-standardization`
- Path: `skills/project-deploy-standardization/SKILL.md`
- Use for: turning a business repo into a self-owned deployment project
- Typical prompts:
  - "Please standardize this repo with `scripts/ops/*.sh`"
  - "Help me replace old deploy tasks with a selected-target `.it-runner` flow"

### `ops-fleet-project-onboarding`
- Path: `skills/ops-fleet-project-onboarding/SKILL.md`
- Use for: onboarding a business repo into `ops-fleet`
- Typical prompts:
  - "Help me add this project to ops-fleet"
  - "Create production target metadata and wrapper tasks for this service"

### `it-runner-workflow`
- Path: `skills/it-runner-workflow/SKILL.md`
- Use for: `.it-runner` authoring, task discovery, API debugging, and runner fixes
- Typical prompts:
  - "Why is this task missing from the UI?"
  - "Create a `.it-runner` layout and tasks for this project"
  - "Inspect `envs-next` and runner APIs to debug task startup"
  - "这个任务名到底是什么意思？"
  - "为什么这里显示可启动但又是已停止？"
  - "latest 路径和具体日志目录有什么区别？"

### `it-runner-agentd-control`
- Path: `skills/it-runner-agentd-control/SKILL.md`
- Use for: `agentd.exe`, `controlapi`, `agentctl`, `agent-task.yaml`, remote Windows task apply/restart/status/logs, and reusable winagent task templates
- Typical prompts:
  - "帮我通过 agentctl 控制远程 Windows 程序"
  - "把这个程序接到 controlapi + agentd.exe"
  - "帮我写一个 agent-task.yaml 和对应 `.it-runner` 任务"
  - "为什么远端 winagent 任务 apply/restart 了但程序没起来？"

### `it-runner-convention-upgrade`
- Path: `skills/it-runner-convention-upgrade/SKILL.md`
- Use for: upgrading legacy `.it-runner` env layouts using the new checker and numbered env rules
- Typical prompts:
  - "Help me migrate this `.it-runner` to the new env conventions"
  - "Use `--check-project-envs` output and clean up this project"
  - "Rename old `.env.local/shared.env` style files in this project"

## Sequencing Patterns

### New Service From Scratch
- `deployment-model-design`
- `project-deploy-standardization`
- `ops-fleet-project-onboarding`
- `it-runner-workflow` as needed during authoring/debugging

### Existing Project With Broken Tasks
- `it-runner-workflow`
- `project-deploy-standardization` if the repo still lacks a stable deploy contract

### Remote Windows Agent Control
- `it-runner-agentd-control`
- `it-runner-workflow` if the local `.it-runner` task structure or env layout is also broken

### Existing Project With Legacy Env Layout
- `it-runner-convention-upgrade`
- `it-runner-workflow` if task behavior must be revalidated after migration

### Formal Production Rollout Design
- `deployment-model-design`
- `ops-fleet-project-onboarding`

## Notes

- Business repo and `ops-fleet` may keep independent metadata copies; that is acceptable.
- Shared contract is more important than shared data files.
- Prefer thin wrappers in `ops-fleet` over copied deploy logic.

## Trigger Cheat Sheet

- Quick trigger reference: `skills/TRIGGERS.md`
- Minimal template checklist: `skills/TEMPLATES.md`
- New service runbook: `skills/NEW-SERVICE-RUNBOOK.md`
- Second service onboarding checklist: `skills/SECOND-SERVICE-CHECKLIST.md`
- It-runner cheatsheet: `skills/IT-RUNNER-CHEATSHEET.md`
- It-runner task model patterns: `skills/it-runner-workflow/references/task-centric-patterns.md`
- It-runner task reading and naming: `skills/it-runner-workflow/references/task-reading-and-naming.md`
- It-runner log reading and paths: `skills/it-runner-workflow/references/log-reading-and-paths.md`
- It-runner UI semantics: `skills/it-runner-workflow/references/ui-semantics.md`
- It-runner rollout status: `skills/it-runner-workflow/references/project-rollout-status.md`
- It-runner convention upgrade: `skills/it-runner-convention-upgrade/SKILL.md`
- Navigation map: `skills/NAVIGATION.md`
- Reading order: `skills/READING-ORDER.md`
