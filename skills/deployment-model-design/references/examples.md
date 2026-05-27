# Examples

## Recommended Business Repo Layout

```text
.it-runner/
  envs/
    000-defaults.env
    010-local.env
  project.yaml
  meta/
    servers/
      test-a.env
    deployments/
      test-a.env
  tasks/
    ops-targets/task.yaml
    ops-show-selected/task.yaml
    ops-preflight-selected/task.yaml
    ops-deploy-selected/task.yaml
```

## Recommended `ops-fleet` Layout

```text
.it-runner/
  meta/
    projects/
      tlsproxy.env
    tlsproxy-server/
      targets/
        prod-a.env
        prod-b.env
  tasks/
    manual/
      tlsproxy-preflight-selected/task.yaml
      tlsproxy-deploy-selected/task.yaml
```

## Decision Heuristics

- If one physical host may run multiple businesses, split **server** from **deployment**.
- If test and production differ operationally, keep their metadata in separate repos.
- If rollout order matters, model rollout explicitly instead of multiplying nearly identical tasks.
