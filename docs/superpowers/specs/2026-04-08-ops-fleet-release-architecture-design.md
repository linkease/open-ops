# ops-fleet 发布架构设计稿

## 1. 目标

本文定义一套面向实际工程开发的发布架构，使开发、测试部署、正式部署、多服务器发布可以长期复用同一组稳定机制。

核心目标如下：

1. 让业务仓库成为部署逻辑的事实来源。
2. 让 `ops-fleet` 成为正式环境的资源编排中心，而不是第二份业务实现。
3. 让开发环境、测试环境、正式环境共享同一套部署动作，只通过参数和目标环境区分。
4. 让多服务器发布具备稳定的 canary、promote、rollback 能力。
5. 让业务变化能快速反映到部署流程，减少“代码已变、发布脚本未同步”的失效风险。

## 2. 已确认设计决策

本设计基于以下已确认原则：

- 业务仓库是部署逻辑事实来源。
- `ops-fleet` 直接引用业务仓库当前工作区中的部署脚本。
- 动作名称统一，但项目实现细节允许扩展。
- 正式发布使用“已发布 artifact”，但部署脚本仍来自业务仓库当前工作区。
- 服务器登录资源、正式环境实例参数、发布编排信息由 `ops-fleet` 管理。

## 3. 分层职责

### 3.1 服务器资源层

服务器资源只表达“如何连上某台机器”，不表达某个业务如何部署。

典型字段：

- `name`
- `ssh_host`
- `ssh_port`
- `ssh_user`
- `ssh_opts`

该层的职责：

- 统一管理 SSH 访问方式。
- 支持同一台机器被多个项目复用。
- 避免把业务目录、端口、配置文件路径写进服务器定义。

### 3.2 业务项目层

业务项目层位于具体仓库中，例如 `tlsproxy`。

该层负责：

- 源码、构建方式、发布产物格式。
- 项目的初始化、预检查、部署、回滚、验证逻辑。
- 配置模板、默认目录结构、systemd 启动方式、文件布局。
- 开发环境和测试环境中的项目自测部署能力。

该层不负责：

- 正式环境的多服务器编排。
- 公司级统一的服务器资源台账。
- 多项目统一的运维入口展示。

### 3.3 正式环境目标层

该层位于 `ops-fleet`，表达“某个项目在某个环境、某台服务器上的一份实例化部署参数”。

典型字段：

- `project`
- `environment`
- `server`
- `deploy_base`
- `config_file`
- `token_file`
- `binary_path`
- `service_name`
- `domain`
- `listen_port`
- 其他业务特有参数

该层的职责：

- 把同一个业务部署到多台服务器时的差异参数清晰保存。
- 保持业务仓库部署逻辑通用，差异通过 target meta 注入。
- 让 rollout 能按目标实例进行精确控制。

### 3.4 发布产物层

发布产物是正式部署唯一允许使用的输入物料。

发布产物层负责：

- 构建产物输出。
- 产物命名与目录布局。
- release ID 记录。
- 回滚时可定位到旧版本。

正式环境部署不得直接依赖源码目录中的临时构建结果。

### 3.5 编排层

编排层位于 `ops-fleet/.it-runner`。

编排层负责：

- 列出正式环境 target。
- 选择目标 target。
- 调用业务仓库统一动作脚本。
- 组织 canary、promote、rollback 流程。
- 提供日志、观测、审计入口。

编排层不负责重写业务部署逻辑。

## 4. 核心对象模型

### 4.1 Server

表示一台可访问服务器。

关注点只有连接信息，不包含项目部署信息。

### 4.2 Project

表示一个业务仓库。

关键属性：

- 仓库根目录
- artifact 发布入口
- 部署动作入口
- 项目默认配置与文件布局

### 4.3 Target

表示 `Project` 在某个 `Server` 上的一个部署实例。

一个 target 是正式发布的最小操作单位。

例如：

- `tlsproxy / prod / bbs1-koolcenter`
- `tlsproxy / prod / bbs-guigu-koolcenter`

### 4.4 Release

表示一次可部署产物集合。

一个 release 至少包含：

- `release_id`
- artifact 文件集合
- 基本元数据

回滚基于 release 进行，而不是基于“当前工作区状态”进行。

### 4.5 Rollout

表示对多个 target 的一次编排执行。

例如：

- 先 `bbs1`
- 验证成功后再 `bbs-guigu`

## 5. 统一动作契约

每个业务仓库必须暴露统一动作入口，建议目录为：

- `scripts/ops/release.sh`
- `scripts/ops/init.sh`
- `scripts/ops/preflight.sh`
- `scripts/ops/deploy.sh`
- `scripts/ops/rollback.sh`
- `scripts/ops/verify.sh`

说明：

- 动作名称统一，便于 `ops-fleet` 稳定调用。
- 内部实现由业务仓库自行决定。
- 项目允许扩展额外脚本，但标准动作必须长期兼容。

### 5.1 通用输入契约

标准动作至少应支持以下输入，推荐使用环境变量或稳定的 CLI 参数：

- `TARGET_NAME`
- `ENVIRONMENT`
- `SSH_TARGET`
- `SSH_PORT`
- `SSH_OPTS`
- `DEPLOY_BASE`
- `ARTIFACT_ROOT`
- `ARTIFACT_PATH`
- `RELEASE_ID`

### 5.2 项目扩展输入

业务项目可以扩展特有参数，例如：

- `TLSPROXY_CONFIG_FILE`
- `TLSPROXY_TOKEN_FILE`
- `TLSPROXY_BINARY_PATH`
- `TLSPROXY_DOMAIN`

### 5.3 动作语义

- `release.sh`: 生成并发布正式可部署 artifact。
- `init.sh`: 完成首次初始化，若目标已初始化则报错并退出，不做覆盖。
- `preflight.sh`: 检查本地 artifact 与远端运行条件是否满足。
- `deploy.sh`: 将指定 artifact 部署到目标服务器。
- `rollback.sh`: 将目标恢复到指定 `release_id`。
- `verify.sh`: 对部署结果进行功能或健康验证。

## 6. 目录设计建议

### 6.1 业务仓库目录建议

以 `tlsproxy` 为例：

- `scripts/ops/release.sh`
- `scripts/ops/init.sh`
- `scripts/ops/preflight.sh`
- `scripts/ops/deploy.sh`
- `scripts/ops/rollback.sh`
- `scripts/ops/verify.sh`
- `.it-runner/tasks/dev/*`
- `.it-runner/tasks/test/*`

开发测试阶段，应优先由业务仓库自己的 `.it-runner` 先跑通部署动作。

### 6.2 ops-fleet 目录建议

- `inventory/servers/*.yaml`: 服务器资源
- `inventory/projects/*.yaml`: 项目定义
- `.it-runner/meta/<project>/local.env`: 本地产物与通用默认值
- `.it-runner/meta/<project>/targets/*.env`: 正式环境 target meta
- `.it-runner/tasks/manual/*`: 调用业务仓库标准动作的编排任务
- `docs/runbooks/*`: 正式发布说明

## 7. 开发、测试、正式发布流程

### 7.1 开发阶段

由业务仓库负责：

1. 开发代码。
2. 调整项目部署脚本。
3. 在业务仓库自己的开发或测试 `.it-runner` 中验证 `init/preflight/deploy/verify`。

要求：

- 开发环境与正式环境调用同一套动作脚本。
- 禁止开发环境用一套脚本、正式环境再维护另一套逻辑副本。

### 7.2 测试部署阶段

由业务仓库继续主导：

1. 构建 artifact。
2. 发布到统一 artifact 根目录或项目约定目录。
3. 对测试目标运行 `preflight/deploy/verify`。

测试部署的价值在于：

- 提前暴露业务脚本兼容性问题。
- 使正式环境复用已经被项目自己验证过的部署逻辑。

### 7.3 正式发布阶段

由 `ops-fleet` 主导编排：

1. 选择项目。
2. 选择 target。
3. 运行项目的 `release` 或使用已发布 artifact。
4. 运行 `preflight`。
5. 先对 canary target 运行 `deploy` 与 `verify`。
6. 通过后对其余 target 逐台 promote。
7. 若失败则执行 `rollback`。

## 8. 多服务器发布模型

正式环境建议采用分阶段 rollout：

1. `canary`
2. `verify`
3. `promote`
4. `verify`
5. 必要时 `rollback`

建议约束：

- 不鼓励首次发布时多台并发。
- 默认顺序发布，特殊情况下才允许并发。
- 回滚以 target 为单位执行。

## 9. 稳定性与兼容性规则

为了长期稳定，标准动作脚本必须遵守以下规则：

1. 非交互式执行。
2. 参数接口尽量向后兼容。
3. 报错信息必须明确指出缺少的参数、文件或远端条件。
4. `preflight` 失败时不得继续 `deploy`。
5. `init` 对已初始化目标必须拒绝覆盖。
6. `rollback` 必须以 release 为基础，不依赖源码目录当前状态。
7. 正式环境脚本修改后，应先在业务仓库测试环境验证。

## 10. 对当前 tlsproxy 的落地映射

当前 `tlsproxy` 已经具备一部分目标模型：

- `ops-fleet/.it-runner/meta/tlsproxy-server/local.env`
- `ops-fleet/.it-runner/meta/tlsproxy-server/targets/bbs1-koolcenter.env`
- `ops-fleet/.it-runner/meta/tlsproxy-server/targets/bbs-guigu-koolcenter.env`

当前 `ops-fleet` 中的 `[TLSProxy] ...` 手动任务，已经接近“正式编排层”的形态。

下一步应继续把 `tlsproxy` 的真实部署逻辑逐步收回到业务仓库标准动作中，而 `ops-fleet` 只保留：

- 目标选择
- 参数注入
- 发布编排
- 正式环境观测入口

## 11. 推荐迁移路线

### 第一阶段

保持当前 `ops-fleet` 可用，整理出统一 target meta 结构。

### 第二阶段

在业务仓库中补齐标准动作脚本：

- `release`
- `init`
- `preflight`
- `deploy`
- `rollback`
- `verify`

### 第三阶段

让 `ops-fleet` 不再自己实现项目专属部署逻辑，而是改为调用业务仓库标准动作。

### 第四阶段

把更多项目迁移到同一契约模型下，形成统一规范。

## 12. 后续实现建议

建议接下来输出一份实现计划，至少包含：

1. 为 `tlsproxy` 设计业务仓库标准动作目录。
2. 为 `ops-fleet` 设计通用 target meta 结构。
3. 为 `ops-fleet` 增加通用“调用业务仓库动作”的任务模板。
4. 为正式环境定义 canary、promote、rollback 的任务组合。
5. 为变更兼容定义最小测试矩阵。

本设计的核心原则不变：

`业务仓库负责部署逻辑，ops-fleet 负责正式编排。`
