# UI Semantics

Use this reference when reading the it-runner frontend, explaining task detail UI, or deciding what a status or button label means for operators.

## Status Layers

The UI exposes different kinds of status. Do not mix them.

### Runtime status

Examples:

- `已停止`
- `启动中`
- `运行中`
- `停止中`
- `已完成`
- `失败`

This answers:

- what is the task runtime doing right now?

### Readiness status

Examples:

- `可启动`
- `缺 Secret`
- `缺参数`
- `警告`

This answers:

- if the task were started now, is its config/env context ready?

Important rule:

- `可启动` does not mean already running
- `已停止 + 可启动` is a normal combination

### Stream status

Examples:

- `实时流: SSE`
- `实时流: Polling`
- `实时流: 连接中`

This answers:

- how the UI is currently receiving state and log updates

Important rule:

- `Polling` is a transport fallback, not a task failure

## Path And Copy Semantics

When the frontend offers file-name clicks, folder buttons, or copy buttons, define each one explicitly.

Preferred meanings:

- clicking the log file name opens a file-path dialog
- clicking the folder button opens a directory-path dialog
- clicking the copy/file button opens or copies the stable latest file path
- copied paths should prefer `latest/...` over one timestamped run path

If the UI also shows the concrete run directory, label it as current context, not the default copied value.

## HTTP Browser Constraint

On plain `http` pages, silent clipboard APIs may be restricted.

Preferred interaction:

- open a dialog with a read-only input
- auto-select the input contents
- let the user press `Ctrl+C`
- keep a best-effort copy button as a convenience path

Do not assume secure-context clipboard support on every deployment.

## AI Explanation Pattern

When explaining a screenshot or task detail page, describe statuses in this order:

1. runtime status
2. readiness status
3. stream status
4. current selected log file
5. copied path semantics if relevant

This avoids common confusion such as:

- mistaking `可启动` for runtime state
- mistaking `Polling` for task failure
- mistaking a path button for direct file content copy
