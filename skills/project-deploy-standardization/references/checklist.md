# Standardization Checklist

## Scripts

- `scripts/ops/common.sh` exists
- `scripts/ops/release.sh` exists
- `scripts/ops/init.sh` exists
- `scripts/ops/preflight.sh` exists
- `scripts/ops/deploy.sh` exists
- `scripts/ops/rollback.sh` exists
- `scripts/ops/verify.sh` exists

## Metadata

- `.it-runner/meta/servers/*.env` exists
- `.it-runner/meta/deployments/*.env` exists
- deployment metadata uses `SERVER_REF`
- `.it-runner/envs/010-local.env` contains only local overrides

## Tasks

- `ops-targets` lists deployments
- `ops-show-selected` resolves deployment + server
- `ops-preflight-selected` works without `ops-fleet`
- `ops-deploy-selected` deploys selected target
- `ops-verify-selected` verifies selected target

## Cleanup

- remove duplicated host-specific legacy tasks
- remove legacy aliases after the new flow is verified

## Validation

- add `test-ops`
- run `bash -n` on critical scripts
- run the selected-target flow end to end on one test machine
