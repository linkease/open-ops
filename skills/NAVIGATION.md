# Skills Navigation Map

## Fast Path

```text
不确定怎么设计
  -> deployment-model-design

业务仓库先能自己部署测试机
  -> project-deploy-standardization

要接入 ops-fleet 正式环境
  -> ops-fleet-project-onboarding

.it-runner / API / 日志 / envs-next / .STATE 有问题
  -> it-runner-workflow

agentd.exe / controlapi / agentctl / 远端 Windows 程序控制
  -> it-runner-agentd-control

旧 `.it-runner` env 命名要迁移到新编号规范
  -> it-runner-convention-upgrade
```

## Companion Files

```text
只想看触发词
  -> TRIGGERS.md

只想看命令和排障手法
  -> IT-RUNNER-CHEATSHEET.md

只想照目录模板搭起来
  -> TEMPLATES.md

想按阶段推进一个新业务
  -> NEW-SERVICE-RUNBOOK.md

想复制 tlsproxy 模式到第二个业务
  -> SECOND-SERVICE-CHECKLIST.md
```

## Recommended Reading Order

```text
INDEX.md
  -> TRIGGERS.md
  -> TEMPLATES.md
  -> NEW-SERVICE-RUNBOOK.md
  -> 具体 SKILL.md
```

## Suggested Paths

### New Business

```text
deployment-model-design
  -> project-deploy-standardization
  -> ops-fleet-project-onboarding
  -> it-runner-workflow (as needed)
```

### Broken Tasks

```text
it-runner-workflow
  -> IT-RUNNER-CHEATSHEET.md
  -> project-deploy-standardization (if repo contract is still messy)
```

### Remote Windows Control

```text
it-runner-agentd-control
  -> it-runner-workflow (if local task/env structure also needs work)
  -> IT-RUNNER-CHEATSHEET.md
```

### Legacy Env Migration

```text
it-runner-convention-upgrade
  -> it-runner-workflow
  -> IT-RUNNER-CHEATSHEET.md
```

### Production Rollout

```text
ops-fleet-project-onboarding
  -> NEW-SERVICE-RUNBOOK.md
  -> IT-RUNNER-CHEATSHEET.md
```
