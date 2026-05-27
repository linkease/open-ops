---
name: it-runner-convention-upgrade
description: Use when upgrading an existing project from legacy `.it-runner` env naming and layout to the new numbered env conventions, especially when consuming `--check-project-envs` text or JSON output and applying focused migration changes.
---

# It-Runner Convention Upgrade

Use this skill when a project already has `.it-runner/`, but its env layout or naming needs to be upgraded to the new conventions.

## Goal

Turn a legacy `.it-runner` setup into a strict, predictable layout without changing more than necessary.

## What This Skill Covers

- reading `--check-project-envs` text output
- reading `--check-project-envs=json` output
- migrating legacy env names
- updating `project.yaml.envFiles`
- removing project-local legacy `.env` entrypoints
- rechecking until the project is clean or only has acceptable warnings

## Default Migration Target

Prefer this layout:

```text
.it-runner/
  project.yaml
  envs/
    000-defaults.env
    010-local.env
    020-*.env
    080-secret-local.env
```

## Core Rules

- Do not keep `.it-runner/.env` or `.it-runner/.env.local`.
- Do not keep `envs/shared.env` or `envs/secrets.env`.
- Keep project-internal env layers in `.it-runner/envs/` only.
- Use numbered filenames for every real env layer.
- Use `project.yaml.envFiles` only for explicit special cases, especially repo-external env files.
- Rename sensitive keys to `SECRET_` when the project wants `/envs` and `/envs-next` to redact them.

## Workflow

1. Run `--check-project-envs` first.
2. Group findings into:
   - legacy entrypoints
   - bad filenames
   - bad `envFiles` references
   - missing recommended base layer
3. Apply the smallest safe rename/move set.
4. Update `project.yaml.envFiles` only where still needed.
5. Re-run `--check-project-envs`.
6. If the project has runnable tasks, inspect `envs-next` for one representative task.

## Rename Defaults

- `.it-runner/.env` -> `.it-runner/envs/000-defaults.env`
- `.it-runner/.env.local` -> `.it-runner/envs/010-local.env`
- `.it-runner/envs/shared.env` -> `.it-runner/envs/000-defaults.env`
- `.it-runner/envs/secrets.env` -> `.it-runner/envs/080-secret-local.env`

These are defaults, not laws. If the old file is clearly selector-based or secret-heavy, choose the more accurate numbered destination.

## Scope Discipline

- Do not redesign unrelated tasks while doing env migration.
- Do not rewrite scripts unless the migration proves the script depends on old names.
- Do not remove repo-external `envFiles` just because numbered envs now exist.

## References

- Read `references/upgrade-checklist.md` when applying a migration.
- Read `../it-runner-workflow/references/env-conventions.md` for the target rules.
