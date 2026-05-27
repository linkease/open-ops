# It-Runner Rollout Status

Use this file to quickly answer two questions:

1. Which repos already meet the strict project-level env convention?
2. Which repos have already entered task-centric phase 2?

## Current Rule

- All listed repos are already on the strict project-level env convention.
- Task-centric phase 2 means the repo has at least some tasks using `env.autoDirs`, `env.includeSets`, or `env.required`.
- The remaining rollout work is now about task models, not project env naming.

## Current Status Matrix

| Repo | Project Env Check | Task-Centric Phase 2 | Approx task env coverage | Closest pattern |
| --- | --- | --- | --- | --- |
| `apptunnel` | yes | yes | `6/94` | Pattern 6 |
| `kspeeder` | yes | yes | `4/21` | Pattern 2 |
| `training` | yes | yes | `11/37` | Pattern 3 |
| `istore-ai-helper` | yes | yes | `9/16` | Pattern 3 |
| `jiajia-gateway` | yes | yes | `2/10` | Pattern 5 |
| `istoreos-app-hub` | yes | yes | `3/16` | Pattern 5 |
| `vibe-kanban` | yes | yes | `3/14` | Pattern 3 |
| `ddns-server` | yes | yes | `5/16` | Pattern 2 |
| `ddnsto-zig` | yes | yes | `4/24` | Pattern 2 |
| `tlsproxy` | yes | yes | `30/31` | Pattern 1 |
| `ops-fleet` | yes | yes | `30/31` | Pattern 1 + 4 |

## Practical Reading

- Need a nearly complete full selected-target service example: use `tlsproxy`
- Need a nearly complete ops wrapper/control hub: use `ops-fleet`
- Need a lightweight local build/dev example: use `ddns-server` or `ddnsto-zig`
- Need a mono-repo build/dev/deploy example: use `kspeeder`
- Need an app repo with dev + release/deploy split: use `training`, `istore-ai-helper`, or `vibe-kanban`
- Need a gateway deploy example with service env upload: use `jiajia-gateway`
- Need a real online integration/gate example: use `apptunnel`

## Remaining Gap

All repos in `it-runner/it-runner.yaml` have now entered task-centric phase 2.

The remaining work is now about depth rather than first adoption:

- which repos should receive a second-round migration
- which large task families should be converted next
- which repo is the best template for a future service
