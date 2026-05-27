# Skill Trigger Cheat Sheet

This file helps quickly choose the right deployment-related skill in `skills/`.

## `deployment-model-design`

### Use this skill when you say
- "帮我设计部署模型"
- "如何拆 server 和 deployment？"
- "测试环境和正式环境应该怎么分层？"
- "一个项目部署到多台服务器应该怎么设计？"
- "ops-fleet 和业务仓库应该怎么分工？"
- "如何设计 release / rollout / rollback 结构？"

### Strong trigger words
- 设计部署模型
- 建模
- server / deployment / local overrides
- release / rollout
- 分层
- 职责边界
- 正式环境 / 测试环境

### Typical outcome
- 产出统一概念模型
- 明确 repo 边界
- 明确目录结构和任务面

---

## `project-deploy-standardization`

### Use this skill when you say
- "帮我把这个业务仓库标准化"
- "给项目补 scripts/ops/*.sh"
- "把旧 deploy 任务整理成新的 selected-target 工作流"
- "让业务项目自己能部署到测试服务器"
- "帮我整理 Makefile 和 .it-runner"

### Strong trigger words
- 标准化业务仓库
- scripts/ops
- 项目自有部署
- selected-target
- 测试服务器部署
- Makefile
- 项目内 .it-runner

### Typical outcome
- 生成标准动作脚本
- 引入三层 meta
- 精简旧任务
- 建立项目自测部署闭环

---

## `ops-fleet-project-onboarding`

### Use this skill when you say
- "帮我把这个项目接入 ops-fleet"
- "给这个业务创建正式环境部署任务"
- "帮我加 production target"
- "让 ops-fleet 调用业务仓库部署脚本"
- "帮我做正式环境 canary / promote / rollback 入口"

### Strong trigger words
- 接入 ops-fleet
- 正式环境
- production target
- wrapper task
- canary
- promote
- rollback
- 上线编排

### Typical outcome
- 注册项目元信息
- 创建正式环境 target
- 创建薄 wrapper 脚本与任务
- 建立正式环境 runbook

---

## `it-runner-workflow`

### Use this skill when you say
- "帮我创建 .it-runner 任务"
- "为什么任务没显示在 UI 里？"
- "帮我检查 it-runner API"
- "envs-next 是什么意思？"
- "怎么通过 .STATE 文件重启任务？"
- "task.version missing 怎么处理？"
- "logsDir 为什么跑到 /logs 了？"
- "帮我修 it-runner 本身的 bug"
- "这个任务名是什么意思？"
- "这个任务属于哪个项目更合适怎么显示？"
- "为什么这里是可启动但又已停止？"
- "Polling 是异常吗？"
- "latest 日志路径和具体目录有什么区别？"
- "这个按钮复制的是文件路径还是目录路径？"

### Strong trigger words
- .it-runner
- it-runner
- env layering
- 000-defaults.env
- 010-local.env
- secret-local.env
- task-centric
- env.autoDirs
- env.includeSets
- env.required
- envsets
- selected-target task
- deploy-target envset
- runtime profile
- rollout status
- 哪个项目先迁移
- 哪个仓库是模板
- task.yaml
- project.yaml
- envs-next
- task.version missing
- STATE 文件重启
- 任务不显示
- API 调试
- 任务发现
- logsDir
- runner bug
- 任务名解释
- project: task
- latest 日志路径
- 具体 run 目录
- 可启动
- 实时流
- Polling
- SSE
- UI 语义
- 文件路径
- 目录路径

---

## `it-runner-agentd-control`

### Use this skill when you say
- "帮我通过 agentctl 控制远程 Windows 程序"
- "帮我接 controlapi / agentd.exe"
- "给我写 agent-task.yaml"
- "帮我做 winagent 远程任务"
- "为什么 task apply / restart 成功了但远端程序没起来？"
- "帮我把本地程序打包并发布给远端 Windows agent"

### Strong trigger words
- agentd
- agentd.exe
- controlapi
- agentctl
- winagent
- agent-task.yaml
- remote windows
- task apply
- task restart
- task status
- task logs
- packageName
- workDir
- logDir
- agent ping
- deskwin_winagent

### Typical outcome
- 建立远端 Windows 控制任务骨架
- 规范 package/apply/restart/status/logs 流程
- 产出 `agent-task.yaml` 与本地 `.it-runner` 模板
- 固化排障顺序与关键 env 约定

---

## `it-runner-convention-upgrade`

### Use this skill when you say
- "帮我把旧 `.it-runner` 升级到新规范"
- "根据 `--check-project-envs` 结果修这个项目"
- "帮我迁移 `.env.local` / `shared.env` 到新命名"
- "把 legacy `.it-runner` env 布局改成编号 env"

### Strong trigger words
- 升级 `.it-runner` 规范
- legacy env layout
- check-project-envs
- migrate env naming
- 000-defaults.env
- 010-local.env
- shared.env -> 000-defaults.env
- .env.local -> 010-local.env

### Typical outcome
- 读取规范检查结果
- 迁移旧 env 命名
- 收敛 `project.yaml.envFiles`
- 复查迁移结果

### Typical outcome
- 建立正确的 `.it-runner` 目录结构
- 创建/修复任务定义
- 选择合适的 task-centric 模式
- 用 API 定位任务问题
- 必要时修复 `it-runner` 内核

---

## Quick Selection Patterns

### 我还没想清楚结构
- Start with `deployment-model-design`

### 我要让业务仓库自己可部署
- Start with `project-deploy-standardization`

### 我要把业务接入正式环境
- Start with `ops-fleet-project-onboarding`

### 我的 `.it-runner` 任务坏了或没显示
- Start with `it-runner-workflow`

### 我要控制远端 Windows agent 程序
- Start with `it-runner-agentd-control`

---

## Common Sequences

### 新业务从零开始
1. `deployment-model-design`
2. `project-deploy-standardization`
3. `ops-fleet-project-onboarding`
4. `it-runner-workflow` as needed

### 业务仓库历史任务很多且很乱
1. `project-deploy-standardization`
2. `it-runner-workflow`

### 正式环境接入失败
1. `ops-fleet-project-onboarding`
2. `it-runner-workflow`

### 任务存在但 UI/API 行为不对
1. `it-runner-workflow`
2. If repo boundaries are the root issue, then `deployment-model-design`

### 远端 Windows agent 控制链路有问题
1. `it-runner-agentd-control`
2. `it-runner-workflow` if local `.it-runner` structure is also suspect

---

## Template Companion

- For a concrete folder/file starting point, read `skills/TEMPLATES.md`
- For cloning the `tlsproxy` pattern into another real service, read `skills/SECOND-SERVICE-CHECKLIST.md`
- For daily `.it-runner` run/stop/log/envs-next commands, read `skills/IT-RUNNER-CHEATSHEET.md`
