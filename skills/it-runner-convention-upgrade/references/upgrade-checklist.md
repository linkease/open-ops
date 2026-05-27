# Upgrade Checklist

Use this when upgrading one existing project.

## 1. Read current state

- open `.it-runner/project.yaml`
- run `go run ./it-runner/cmd/it_runner --project <root> --check-project-envs`
- prefer `--check-project-envs=json` if the result will be consumed by another AI/tool step

## 2. Fix in this order

- remove project-local legacy `.env` entrypoints first
- rename non-numbered files under `.it-runner/envs/`
- repair `project.yaml.envFiles`
- create `000-defaults.env` if the project uses managed env layers but lacks a base layer

## 3. Recommended mapping

- `.it-runner/.env` -> `envs/000-defaults.env`
- `.it-runner/.env.local` -> `envs/010-local.env`
- `envs/shared.env` -> `envs/000-defaults.env`
- `envs/secrets.env` -> `envs/080-secret-local.env`

## 4. Selector migration

When one old file encoded multiple target contexts, split it into selector files such as:

- `020-server@SELECT_SERVER=a-server.env`
- `020-server@SELECT_SERVER=c-server.env`

Keep the selector variable itself in a lower layer such as `010-local.env` if the operator chooses the target locally.

## 5. Secret migration

- keep real secret values out of Git
- prefer `080-secret-local.env`
- rename sensitive keys to `SECRET_*` if redaction in env inspection is desired

## 6. Recheck

- rerun `--check-project-envs`
- for at least one representative task, inspect `envs-next`
- verify that the intended override order still works

## 7. Hand-off summary

Summarize only:

- which files were renamed or removed
- which `envFiles` entries changed
- whether any warnings remain and why
