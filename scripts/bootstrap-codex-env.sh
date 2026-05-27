#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
bin_dir="$HOME/.local/bin"
ag_src="$repo_root/docs/codex-prepare/AGENTS.md"
ag_dest="$codex_home/AGENTS.md"
list_src="$repo_root/scripts/list-codex-skills"
list_dest="$bin_dir/list-codex-skills"
install_skills_script="$repo_root/scripts/install-codex-skills.sh"
force="false"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force]

Bootstrap a Codex environment using files from this repository.

Actions:
  1. Ensure rtk is installed
  2. Install list-codex-skills into $bin_dir
  3. Initialize Codex RTK files under $codex_home
  4. Install repository skills into the active Codex skills root
  5. Verify the resulting setup

Options:
  --force    Overwrite existing AGENTS.md and skill destinations where applicable
  -h, --help Show this help
EOF
}

log() {
  printf '%s\n' "$*"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "error: required command not found: $cmd"
    exit 1
  fi
}

install_rtk() {
  if command -v rtk >/dev/null 2>&1; then
    log "ok: rtk already installed at $(command -v rtk)"
    return 0
  fi

  require_cmd curl
  log "installing: rtk"
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
  hash -r
  require_cmd rtk
}

install_list_codex_skills() {
  mkdir -p "$bin_dir"
  install -m 0755 "$list_src" "$list_dest"
  log "installed: $list_dest"
}

install_agents_md() {
  mkdir -p "$codex_home"

  if [[ -f "$ag_dest" && "$force" != "true" ]]; then
    if cmp -s "$ag_src" "$ag_dest"; then
      log "ok: AGENTS.md already up to date"
      return 0
    fi

    cp "$ag_dest" "$ag_dest.bak"
    log "backup: $ag_dest.bak"
  fi

  install -m 0644 "$ag_src" "$ag_dest"
  log "installed: $ag_dest"
}

install_rtk_codex_files() {
  log "initializing: rtk codex integration"
  rtk init -g --codex
}

install_skills() {
  if [[ "$force" == "true" ]]; then
    "$install_skills_script" --force
  else
    "$install_skills_script"
  fi
}

verify_setup() {
  log "verify: rtk -> $(command -v rtk)"
  log "verify: list-codex-skills -> $(command -v list-codex-skills)"

  test -f "$ag_dest"
  test -f "$codex_home/RTK.md"

  log "verify: AGENTS.md and RTK.md present under $codex_home"
  list-codex-skills --roots
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force="true"
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

require_cmd bash
require_cmd git

install_rtk
install_list_codex_skills
install_rtk_codex_files
install_agents_md
install_skills
verify_setup

log "done: restart Codex to pick up AGENTS.md and skills changes"
