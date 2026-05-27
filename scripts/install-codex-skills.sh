#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
local_skills_dir="$repo_root/skills"
codex_home="${CODEX_HOME:-$HOME/.codex}"
dest_dir=""
dest_explicit="false"
mode="symlink"
force="false"
dry_run="false"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Install skills into the active Codex skills root from:
  1. superpowers skills
  2. $local_skills_dir

Destination selection order when `--dest` is not provided:
  1. first root reported by `list-codex-skills --roots`
  2. `$CODEX_HOME/skills`
  3. `$HOME/.codex/skills`

Options:
  --copy           Copy skills instead of symlinking
  --force          Overwrite existing destinations
  --dest PATH      Override destination directory
  --dry-run        Print planned actions without changing files
  -h, --help       Show this help
EOF
}

log() {
  printf '%s\n' "$*"
}

run_cmd() {
  if [[ "$dry_run" == "true" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

discover_dest_dir() {
  local root
  local parent

  if command -v list-codex-skills >/dev/null 2>&1; then
    while IFS= read -r root; do
      [[ -n "$root" ]] || continue
      if [[ -d "$root" ]]; then
        printf '%s\n' "$root"
        return 0
      fi
      parent="$(dirname "$root")"
      if [[ -d "$parent" && -w "$parent" ]]; then
        printf '%s\n' "$root"
        return 0
      fi
    done < <(list-codex-skills --roots 2>/dev/null | awk '
      /^roots:/ { in_roots=1; next }
      in_roots && /^[[:space:]]+\// {
        sub(/^[[:space:]]+/, "", $0)
        print
        next
      }
      in_roots { exit }
    ')
  fi

  if [[ -n "${CODEX_HOME:-}" ]]; then
    printf '%s\n' "$CODEX_HOME/skills"
    return 0
  fi

  printf '%s\n' "$HOME/.codex/skills"
}

find_superpowers_dir() {
  local candidates=(
    "$HOME/.agents/skills/superpowers"
    "/config/.codex/superpowers/skills"
  )
  local candidate
  local resolved

  for candidate in "${candidates[@]}"; do
    resolved="$(readlink -f "$candidate" 2>/dev/null || true)"
    if [[ -n "$resolved" && -d "$resolved" ]]; then
      printf '%s\n' "$resolved"
      return 0
    fi
  done

  return 1
}

install_skill() {
  local source_dir="$1"
  local skill_name="$2"
  local destination="$dest_dir/$skill_name"

  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ "$force" != "true" ]]; then
      log "skip: $skill_name already exists at $destination"
      return 0
    fi

    run_cmd rm -rf "$destination"
  fi

  if [[ "$mode" == "copy" ]]; then
    run_cmd cp -R "$source_dir" "$destination"
  else
    run_cmd ln -s "$source_dir" "$destination"
  fi

  log "installed: $skill_name"
}

install_from_root() {
  local root_dir="$1"
  local label="$2"
  local found_any="false"
  local skill_dir

  if [[ ! -d "$root_dir" ]]; then
    log "skip: $label source not found at $root_dir"
    return 0
  fi

  log "source: $label -> $root_dir"

  while IFS= read -r -d '' skill_dir; do
    found_any="true"
    install_skill "$skill_dir" "$(basename "$skill_dir")"
  done < <(find "$root_dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -exec test -f '{}/SKILL.md' ';' -print0 | sort -z)

  if [[ "$found_any" != "true" ]]; then
    log "skip: no skills with SKILL.md found under $root_dir"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      mode="copy"
      ;;
    --force)
      force="true"
      ;;
    --dest)
      shift
      if [[ $# -eq 0 ]]; then
        log "error: --dest requires a path"
        exit 1
      fi
      dest_dir="$1"
      dest_explicit="true"
      ;;
    --dry-run)
      dry_run="true"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "error: unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

superpowers_dir=""
if superpowers_dir="$(find_superpowers_dir)"; then
  :
else
  log "warning: superpowers source not found"
fi

if [[ "$dest_explicit" != "true" ]]; then
  dest_dir="$(discover_dest_dir)"
fi

log "destination: $dest_dir"

run_cmd mkdir -p "$dest_dir"

if [[ -n "$superpowers_dir" ]]; then
  install_from_root "$superpowers_dir" "superpowers"
fi

install_from_root "$local_skills_dir" "workspace"

log "done: restart Codex to pick up new skills"
