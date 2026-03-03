#!/usr/bin/env bash

# Shared helpers for workflow scripts.
# Source this file at the top of every workflow.

# --- Colors ---
_R='\033[0;31m'  # Red
_G='\033[0;32m'  # Green
_Y='\033[0;33m'  # Yellow
_B='\033[0;34m'  # Blue
_C='\033[0;36m'  # Cyan
_N='\033[0m'     # No color

wf_info()    { echo -e "${_C}▸${_N} $*"; }
wf_ok()      { echo -e "${_G}✔${_N} $*"; }
wf_warn()    { echo -e "${_Y}⚠${_N} $*"; }
wf_err()     { echo -e "${_R}✘${_N} $*" >&2; }
wf_step()    { echo -e "${_B}→${_N} $*"; }
wf_header()  { echo -e "\n${_B}━━━ $* ━━━${_N}"; }
wf_dry()     { echo -e "${_Y}[dry-run]${_N} $*"; }

# --- Fatal exit ---
wf_die() {
  wf_err "$1"
  exit "${2:-1}"
}

# --- Guards ---
require_git_repo() {
  git rev-parse --is-inside-work-tree &>/dev/null \
    || wf_die "Not inside a git repository."
}

require_clean_tree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    wf_warn "Working tree has uncommitted changes:"
    git status --short
    return 1
  fi
  return 0
}

require_lando() {
  command -v lando &>/dev/null \
    || wf_die "lando is not installed."
}

require_lando_running() {
  require_lando
  # Check if container is running (supports different lando outputs)
  if ! lando list 2>/dev/null | grep -q -E "Running|running: true"; then
    wf_die "Lando is not running. Start it first: lando start"
  fi
}

# Detect mainline branch name (main or master)
detect_mainline() {
  if git rev-parse --verify origin/main &>/dev/null; then
    echo "main"
  elif git rev-parse --verify main &>/dev/null; then
    echo "main"
  elif git rev-parse --verify origin/master &>/dev/null; then
    echo "master"
  else
    echo "master"
  fi
}

current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD"
}

# --- Dry-run support ---
# Set WF_DRY_RUN=1 to preview commands without executing them.
wf_run() {
  if [[ "${WF_DRY_RUN:-0}" == "1" ]]; then
    wf_dry "$*"
  else
    wf_step "$*"
    eval "$@"
  fi
}
