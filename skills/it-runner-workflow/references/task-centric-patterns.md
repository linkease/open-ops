# Task-Centric Patterns

Use this reference when designing a new `.it-runner` project or deciding how far to migrate an existing one.

Do not force every repo into one shape. Pick the smallest pattern that matches the repo's real task surface.

## Pattern 1: Full Target + Meta

Use when:

- tasks select one deployment target or server target
- project metadata is already split into project / deployment / server layers
- scripts need resolved SSH, artifact, and remote path metadata

Recommended structure:

- `.it-runner/envs/000-defaults.env`
- `.it-runner/envs/010-local.env`
- `tasks/<task>/envs/000-defaults.env`
- `.it-runner/meta/projects/*.env`
- `.it-runner/meta/<service>/local.env`
- `.it-runner/meta/<service>/deployments/*.env`
- `.it-runner/meta/servers/*.env`

Task shape:

- `env.autoDirs: ["envs"]`
- `env.includeSets` includes project meta, service local meta, selected deployment, selected server
- `env.required` contains the selector variable such as `TLSPROXY_TARGET`

Reference projects:

- `tlsproxy`
- `ops-fleet`

Maturity note:

- `tlsproxy` and `ops-fleet` are now the closest thing to full-stack reference templates: selected-target ops tasks, runtime profiles, and most visible local/generated task families are already task-centered.

## Pattern 2: Lightweight Build / Dev

Use when:

- the visible task surface is mostly build / test / local dev
- tasks only need a few runtime knobs
- there is no meaningful multi-target deployment matrix yet

Recommended structure:

- `.it-runner/envs/000-defaults.env` for true project-wide defaults only
- `.it-runner/envs/010-local.env` for machine-local overrides only
- `tasks/<task>/envs/000-defaults.env` for task default profile selection
- `.it-runner/envsets/task-runtimes/<task>/<profile>/000-base.env`

Task shape:

- `env.autoDirs: ["envs"]`
- `env.includeSets` points only to task runtime profiles
- `env.required` contains only task profile selectors such as `IT_TASK_PROFILE`

Reference project:

- `ddns-server`

Additional reference projects:

- `kspeeder`
- `ddnsto-zig`

## Pattern 3: App Dev + Deploy

Use when:

- the repo has both local dev tasks and a small number of deploy targets
- frontend/backend runtime knobs differ from deploy target knobs
- one project needs multiple task families with different parameter models

Recommended structure:

- project envs for shared defaults and machine-local overrides
- `tasks/<dev-task>/envs/000-defaults.env` for dev profiles
- `.it-runner/envsets/task-runtimes/<dev-task>/<profile>/`
- `tasks/<deploy-task>/envs/000-defaults.env` for deploy target/profile selectors
- `.it-runner/envsets/deploy-targets/<target>/`
- `.it-runner/envsets/task-runtimes/deploy/<profile>/`

Reference project:

- `training`

Additional reference projects:

- `istore-ai-helper`
- `vibe-kanban`

## Pattern 4: Control Hub / Wrapper Repo

Use when:

- the repo mostly orchestrates other repos
- most tasks are thin wrappers around project-owned actions
- the task's real job is to resolve parameters and metadata cleanly

Notes:

- this often overlaps with Pattern 1
- the main discipline is to keep wrapper tasks thin and move defaults into task env plans rather than global `010-local.env`

Reference project:

- `ops-fleet`

## Pattern 5: Gateway Deploy + Service Env

Use when:

- the repo mainly builds one service binary and deploys it to a small number of servers
- deploy tasks need SSH target metadata plus an optional uploaded systemd/service env payload
- build/release tasks are still simple, but deploy/log inspection should be task-centered

Recommended structure:

- project envs for shared defaults only
- `tasks/<deploy-task>/envs/000-defaults.env`
- `.it-runner/envsets/deploy-targets/<target>/000-base.env`
- `.it-runner/service-env-local/*.env` for deploy-only uploaded env payloads

Reference project:

- `jiajia-gateway`

## Pattern 6: Online Gate / Integration Sandbox

Use when:

- tasks talk to a real online service or account-bound environment
- part of the configuration is safe, reusable, and non-secret
- another part is real token/session data that must stay local

Recommended structure:

- project envs for true shared defaults
- local secret env for tokens/passwords only
- `tasks/<task>/envs/000-defaults.env` for online profile selection
- `.it-runner/envsets/online-profiles/<profile>/000-base.env` for non-secret online defaults
- migrate high-value online tasks first, not the entire historical gate surface at once

Reference project:

- `apptunnel`

## Reference Map

Use this when you already know the repo and want the closest working example.

- `tlsproxy`: Pattern 1 (full target + meta)
- `ops-fleet`: Pattern 1 + Pattern 4 (selected-target control hub)
- `ddns-server`: Pattern 2 (lightweight build/dev with task runtimes)
- `kspeeder`: Pattern 2 (mono-repo build/dev/deploy mix, still lightweight)
- `ddnsto-zig`: Pattern 2 (single-service/single-binary runtime profiles)
- `training`: Pattern 3 (app dev + deploy)
- `istore-ai-helper`: Pattern 3 (app dev + remote ops)
- `vibe-kanban`: Pattern 3 (frontend/backend dev + release profiles)
- `jiajia-gateway`: Pattern 5 (gateway deploy + service env)
- `istoreos-app-hub`: Pattern 5 leaning toward repo-sync/deploy tooling
- `apptunnel`: Pattern 6 (online gate / integration sandbox)

## Selection Rule

- If a repo has selected-target tasks and meta files, start with Pattern 1
- If a repo is mostly local build/dev, start with Pattern 2
- If a repo mixes app dev and deploy, start with Pattern 3
- If a repo mainly wraps other repos, favor Pattern 4 behavior even if the file layout looks like Pattern 1
- If a repo mainly builds one binary and deploys one systemd service, start with Pattern 5
- If a repo depends on real online identities/tokens and long-lived integration gates, start with Pattern 6

## Migration Rule

Do not migrate every task at once.

Prefer this order:

1. high-value operator tasks
2. selected-target tasks
3. long-running dev tasks
4. repetitive build/release wrappers
5. low-value or legacy tasks last
