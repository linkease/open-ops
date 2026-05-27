# Task Reading And Naming

Use this reference when an AI agent or operator needs to quickly understand what a task is, how to refer to it, and how to summarize it without ambiguity.

## Read Order

When reading one task, prefer this order:

1. `project`
2. `name`
3. `description`
4. `tags`
5. `key`

Reason:

- `project` tells you which repo or project family owns the task
- `name` tells you the operator-facing action
- `description` explains the intent and scope
- `tags` hint at mode, environment, or protocol
- `key` is for exact API control, not for first-pass human explanation

## Preferred Display Name

When there is any chance of cross-project ambiguity, prefer:

- `<project>: <task-name>`

Examples:

- `ddnsto-zig: test-transport-client-online`
- `ops-fleet: deploy-training-prod`

When the project is already obvious from the current page or command context, `name` alone is acceptable.

## What Each Field Usually Means

### `name`

This should answer: what action or role does the task expose to an operator?

Good signals:

- `build-ddnsto_tunnel`
- `test-transport-client-online`
- `deploy-prod`

### `description`

This should answer: why would someone run this task, against what target, and with what mode?

Good descriptions often mention:

- whether the task is for build, dev, deploy, test, inspect, or keepalive
- whether it talks to a real online service
- whether it is safe for local use or requires real credentials
- which transport/profile/selector the task expects

### `tags`

Treat tags as quick hints, not full truth. They help classify the task surface.

Common tag meanings:

- `build` / `test` / `deploy` / `online` / `manual`
- protocol or mode tags such as `tcp`, `wss`
- family or feature tags such as `transport`

### `key`

Treat `key` as the stable machine identifier for API calls and exact lookup.

Do not lead with `key` when explaining the task to a human unless:

- two tasks have the same visible name
- the user is driving the HTTP API directly
- the UI is already keyed by task key

## AI Summary Pattern

When summarizing one task, use this compact shape:

- `<project>: <name>` if project is known
- one sentence from `description`
- short note on important tags or selectors

Example:

`ddnsto-zig: test-transport-client-online` keeps the Zig ddnsto tunnel online for manual transport testing, with real-server transport selected by env such as `tcp-tcp` or `wss-wss`.

## Naming Guidance For New Tasks

Prefer names that expose operator intent first.

Good patterns:

- `build-...`
- `test-...`
- `run-...`
- `deploy-...`
- `inspect-...`
- `sync-...`

Prefer descriptions to carry the extra detail that would make the name too long.

Bad pattern:

- putting every transport/target/profile detail into the task name

Better pattern:

- keep the visible name short
- put transport/target/profile details in `description`, task-local env defaults, and tags

## Ambiguity Checks

An AI agent should slow down and include `project` when:

- multiple repos expose similar task names such as `build`, `deploy`, `restart`
- the user pasted only a task name from the UI
- a task family exists across many projects
- logs or screenshots omit the surrounding project context

If ambiguity remains, quote both:

- display name: `<project>: <name>`
- task key: `<key>`
