# Skills Reading Order

Use this file when you want the shortest human-readable sequence for navigating the `skills/` folder.

## Fastest Reading Order

1. `skills/INDEX.md`
   - Start here if you are new to this folder.

2. `skills/NAVIGATION.md`
   - Read this if you want the shortest route by problem type.

3. `skills/TRIGGERS.md`
   - Read this if you want to know which skill should trigger from a prompt.

4. `skills/TEMPLATES.md`
   - Read this if you want folder/file starting points.

5. `skills/IT-RUNNER-CHEATSHEET.md`
   - Read this if your work involves task execution, logs, APIs, `envs-next`, or `.STATE` files.

6. `skills/it-runner-workflow/references/env-conventions.md`
   - Read this if your work involves `.it-runner` env naming, layering, selectors, or secret handling.

7. `skills/it-runner-workflow/references/task-centric-patterns.md`
   - Read this if you need to choose the right task-centered `.it-runner` pattern for a repo.

8. `skills/it-runner-workflow/references/project-rollout-status.md`
   - Read this if you need to know which repos are already migrated, which repo is the best template, or which repo still needs task-centric phase 2.

9. `skills/it-runner-convention-upgrade/SKILL.md`
   - Read this if your work is specifically about migrating an existing project from legacy `.it-runner` env naming to the new numbered convention.

10. `skills/NEW-SERVICE-RUNBOOK.md`
   - Read this if you want the full design → test deploy → production onboarding flow.

11. `skills/SECOND-SERVICE-CHECKLIST.md`
   - Read this when cloning the proven `tlsproxy` pattern into another real service.

## Then Read The Actual Skill

Choose one of these based on the problem you are solving:

- `skills/deployment-model-design/SKILL.md`
- `skills/project-deploy-standardization/SKILL.md`
- `skills/ops-fleet-project-onboarding/SKILL.md`
- `skills/it-runner-workflow/SKILL.md`

## Shortest Decision Rule

- Need architecture/modeling help → `deployment-model-design`
- Need the business repo to own and run deployments → `project-deploy-standardization`
- Need `ops-fleet` production onboarding → `ops-fleet-project-onboarding`
- Need `.it-runner` creation/debugging/API/log help → `it-runner-workflow`
