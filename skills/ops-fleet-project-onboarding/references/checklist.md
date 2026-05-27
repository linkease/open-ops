# Onboarding Checklist

## Preconditions

- business repo already has `scripts/ops/*.sh`
- project-local test deployment has been exercised at least once

## Metadata

- add project registration metadata
- add target files for production instances
- keep server connection data separate from project deployment data

## Wrappers

- wrapper loads selected target
- wrapper exports contract env vars
- wrapper calls project-owned script instead of duplicating logic

## Tasks

- release task exists
- selected-target tasks exist
- verify task exists
- rollback task exists

## Operations

- run release
- run canary preflight
- run canary deploy
- run canary verify
- then broader promotion
