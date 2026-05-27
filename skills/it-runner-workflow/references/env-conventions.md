# Env Conventions

读取或修改 `.it-runner` 项目时，env 规范按下面几条执行：

- 正式项目内 env 只放在 `.it-runner/envs/`
- 文件名必须使用 `000-defaults.env`、`010-local.env`、`080-secret-local.env` 这类编号命名
- 不使用 `.it-runner/.env`、`.it-runner/.env.local`
- 不使用 `envs/shared.env`、`envs/secrets.env`
- selector 变体用 `020-server@SELECT_SERVER=c-server.env`
- 需要隐藏显示值的变量使用 `SECRET_` 前缀
- repo 外 secrets 使用 `project.yaml.envFiles` 显式引入

设计目标：

- 保持加载顺序稳定
- 避免误加载样例/备份 env
- 让 `envs-next` 和真实运行结果一致

更完整说明见 `it-runner/docs/env-conventions.md`。
