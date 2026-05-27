# Global Codex Guidance

## Skills Discovery

- When checking Codex skills under `~/.codex/skills`, `$CODEX_HOME/skills`, or `~/.agents/skills`, assume skill directories may be symlinks.
- Never use `find ... -type f -name 'SKILL.md'` without following symlinks.
- Prefer the fixed command `list-codex-skills` instead of composing ad-hoc discovery commands.
- If a result seems unexpectedly small, verify with `ls -la ~/.codex/skills` and inspect the resolved target with `readlink -f` before claiming a skill is missing.
- Before saying a skill does not exist, verify both the visible symlink entry and the resolved target path.

## Preferred Command

- Use `list-codex-skills` to enumerate locally available Codex skills.
- Use `list-codex-skills --roots` to see the discovery roots and resolved `SKILL.md` paths.

@RTK.md
