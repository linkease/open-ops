# open-ops

`open-ops` contains reusable Codex skills, bootstrap scripts, and supporting
documentation extracted from `linkease/ops`.

The repository is intended to make the LinkEase ops workflow materials easier to
install, inspect, and reuse without cloning the full ops repository.

## Contents

- `skills/` - Codex skills for deployment modeling, project standardization,
  ops-fleet onboarding, it-runner workflows, and Windows agent control.
- `scripts/` - helper scripts for installing and listing Codex skills.
- `docs/` - bootstrap guidance and related planning/spec documents used by the
  scripts and skills.

## Quick Start

List available skills from an installed Codex environment:

```bash
scripts/list-codex-skills
```

Preview installation of this repository's skills:

```bash
scripts/install-codex-skills.sh --dry-run
```

Install the skills by symlink into the active Codex skills root:

```bash
scripts/install-codex-skills.sh
```

Install by copying instead of symlinking:

```bash
scripts/install-codex-skills.sh --copy
```

Bootstrap a Codex environment with `rtk`, `AGENTS.md`, and the local skills:

```bash
scripts/bootstrap-codex-env.sh
```

Use `--force` when existing files or skill destinations should be overwritten:

```bash
scripts/bootstrap-codex-env.sh --force
```

## Requirements

- Bash
- Git
- `curl` and network access when running `bootstrap-codex-env.sh`
- `python3` when using `scripts/list-codex-skills --json`

`install-codex-skills.sh` can also import local superpowers skills when they are
available, but missing superpowers skills are only reported as a warning.

## Skill Entry Points

Start with `skills/INDEX.md` for skill selection and reading order.

Common entry points:

- `skills/deployment-model-design/SKILL.md`
- `skills/project-deploy-standardization/SKILL.md`
- `skills/ops-fleet-project-onboarding/SKILL.md`
- `skills/it-runner-workflow/SKILL.md`
- `skills/it-runner-agentd-control/SKILL.md`
- `skills/it-runner-convention-upgrade/SKILL.md`

## Notes

The bootstrap script installs `docs/codex-prepare/AGENTS.md` into the active
Codex home and then runs `rtk init -g --codex`. Review the script before running
it on a machine with existing global Codex configuration.
