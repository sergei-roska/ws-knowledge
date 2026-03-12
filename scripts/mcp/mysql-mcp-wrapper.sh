#!/usr/bin/env bash
set -euo pipefail

if ! command -v lando >/dev/null 2>&1; then
  echo "mysql-mcp-wrapper: lando command not found" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "mysql-mcp-wrapper: jq is required" >&2
  exit 1
fi

find_current_project() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.lando.yml" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

lando_info_from_dir() {
  local dir="$1"
  if [[ -z "$dir" || ! -d "$dir" || ! -f "$dir/.lando.yml" ]]; then
    return 1
  fi
  (cd "$dir" && lando info --format json 2>/dev/null) || return 1
}

find_project_dir() {
  local maybe=""
  local candidate=""
  local info=""
  local default_project="/home/sr/Projects/Sun_State_Specialists"

  maybe="$(find_current_project || true)"
  if [[ -n "$maybe" ]]; then
    printf '%s\n' "$maybe"
    return 0
  fi

  if [[ -n "${MYSQL_PROJECT_DIR:-}" ]]; then
    info="$(lando_info_from_dir "$MYSQL_PROJECT_DIR" || true)"
    if [[ -n "$info" && "$info" != "null" ]]; then
      printf '%s\n' "$MYSQL_PROJECT_DIR"
      return 0
    fi
  fi

  if [[ -d "$default_project" && -f "$default_project/.lando.yml" ]]; then
    info="$(lando_info_from_dir "$default_project" || true)"
    if [[ -n "$info" && "$info" != "null" ]]; then
      printf '%s\n' "$default_project"
      return 0
    fi
  fi

  if [[ -n "${MYSQL_PROJECTS:-}" ]]; then
    IFS=':' read -r -a candidates <<<"$MYSQL_PROJECTS"
    for candidate in "${candidates[@]}"; do
      info="$(lando_info_from_dir "$candidate" || true)"
      if [[ -n "$info" && "$info" != "null" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  fi

  for candidate in /home/sr/Projects/*; do
    [[ -d "$candidate" && -f "$candidate/.lando.yml" ]] || continue
    info="$(lando_info_from_dir "$candidate" || true)"
    if [[ -n "$info" && "$info" != "null" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

PROJECT_DIR="$(find_project_dir || true)"
if [[ -z "$PROJECT_DIR" ]]; then
  echo "mysql-mcp-wrapper: no active Lando project found from current directory; set MYSQL_PROJECT_DIR or MYSQL_PROJECTS" >&2
  exit 1
fi

LANDO_JSON="$(lando_info_from_dir "$PROJECT_DIR" || true)"
if [[ -z "$LANDO_JSON" || "$LANDO_JSON" == "null" ]]; then
  echo "mysql-mcp-wrapper: unable to read lando info for project: $PROJECT_DIR" >&2
  exit 1
fi

first_nonempty() {
  awk 'NF{print; exit}'
}

find_json() {
  local filter="$1"
  jq -r "$filter // empty" <<<"$LANDO_JSON" | first_nonempty
}

MYSQL_HOST="${MYSQL_HOST:-$(find_json '..|objects|.external_connection? | .host?')}"
MYSQL_PORT="${MYSQL_PORT:-$(find_json '..|objects|.external_connection? | .port?')}"
MYSQL_USER="${MYSQL_USER:-$(find_json '..|objects|.creds? | .user?')}"
MYSQL_PASS="${MYSQL_PASS:-$(find_json '..|objects|.creds? | .password?')}"
MYSQL_DB="${MYSQL_DB:-$(find_json '..|objects|.creds? | .database?')}"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"

if [[ -z "${MYSQL_PORT:-}" || -z "${MYSQL_USER:-}" || -z "${MYSQL_PASS:-}" || -z "${MYSQL_DB:-}" ]]; then
  echo "mysql-mcp-wrapper: incomplete MySQL credentials from lando info" >&2
  exit 1
fi

export MYSQL_HOST MYSQL_PORT MYSQL_USER MYSQL_PASS MYSQL_DB
export ALLOW_DELETE_OPERATION="${ALLOW_DELETE_OPERATION:-false}"
export ALLOW_INSERT_OPERATION="${ALLOW_INSERT_OPERATION:-false}"
export ALLOW_UPDATE_OPERATION="${ALLOW_UPDATE_OPERATION:-false}"
export MYSQL_PROJECT_DIR="$PROJECT_DIR"

NODE_BIN="${NODE_BIN:-$HOME/.nvm/versions/node/v22.20.0/bin/node}"
NODE_PATH_DEFAULT="$HOME/.nvm/versions/node/v22.20.0/lib/node_modules"
export NODE_PATH="${NODE_PATH:-$NODE_PATH_DEFAULT}"
export PATH="$HOME/.nvm/versions/node/v22.20.0/bin:/usr/bin:/bin:${PATH:-}"

exec "$NODE_BIN" "$HOME/mcp-server-mysql/dist/index.js"
