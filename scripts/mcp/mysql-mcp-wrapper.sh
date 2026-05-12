#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ---------------------------------------------------------
# CONFIGURATION — override with env if needed (NVM, fnm, custom Node)
# ---------------------------------------------------------
NODE_BIN="${NODE_BIN:-$(command -v node 2>/dev/null || true)}"
if [[ -z "${NODE_BIN}" || ! -x "${NODE_BIN}" ]]; then
  echo "mysql-mcp-wrapper: node not found in PATH; set NODE_BIN" >&2
  exit 1
fi

# MCP server entry: local checkout (override with MCP_SERVER_JS or MCP_SERVER_ROOT)
MCP_SERVER_ROOT="${MCP_SERVER_ROOT:-/home/sr/mcp-server-mysql}"
if [[ -z "${MCP_SERVER_JS:-}" ]]; then
  if [[ -f "${MCP_SERVER_ROOT}/dist/index.js" ]]; then
    MCP_SERVER_JS="${MCP_SERVER_ROOT}/dist/index.js"
  else
    _npm_global="$(PATH="$(dirname "$NODE_BIN"):$PATH" npm root -g 2>/dev/null || true)"
    MCP_SERVER_JS="${_npm_global}/@benborla29/mcp-server-mysql/dist/index.js"
  fi
fi

# Optional: extra module resolution (defaults to global node_modules)
LOCAL_NODE_PATH_DIR="${LOCAL_NODE_PATH_DIR:-$(PATH="$(dirname "$NODE_BIN"):$PATH" npm root -g 2>/dev/null)}"
# ---------------------------------------------------------

if ! command -v lando >/dev/null 2>&1; then
  echo "mysql-mcp-wrapper: lando command not found" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "mysql-mcp-wrapper: jq is required" >&2
  exit 1
fi

lando_info_from_dir() {
  local dir="$1"
  if [[ -z "$dir" || ! -d "$dir" || ! -f "$dir/.lando.yml" ]]; then
    return 1
  fi
  (cd "$dir" && lando info --format json 2>/dev/null) || return 1
}

canonical_dir() {
  local dir="$1"
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    return 1
  fi
  (cd "$dir" && pwd)
}

find_lando_root_from_dir() {
  local dir="$1"
  dir="$(canonical_dir "$dir" || true)"

  while [[ -n "$dir" && "$dir" != "/" ]]; do
    if [[ -f "$dir/.lando.yml" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  if [[ "$dir" == "/" && -f "/.lando.yml" ]]; then
    printf '/\n'
    return 0
  fi

  return 1
}

find_project_dir() {
  local git_root=""
  local -a candidates=()
  local dir=""

  if [[ -n "${MYSQL_PROJECT_DIR:-}" ]]; then
    candidates+=("$MYSQL_PROJECT_DIR")
  fi

  candidates+=(
    "${PROJECT_CWD:-}"
    "${INIT_CWD:-}"
    "${PWD:-}"
    "$REPO_ROOT"
  )

  git_root="$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$git_root" ]]; then
    candidates+=("$git_root")
  fi

  for dir in "${candidates[@]}"; do
    dir="$(find_lando_root_from_dir "$dir" || true)"
    if [[ -n "$dir" ]] && lando_info_from_dir "$dir" >/dev/null 2>&1; then
      printf '%s\n' "$dir"
      return 0
    fi
  done

  echo "mysql-mcp-wrapper: unable to resolve a Lando project directory. Set MYSQL_PROJECT_DIR to override." >&2
  return 1
}

PROJECT_DIR="$(find_project_dir || true)"
if [[ -z "$PROJECT_DIR" ]]; then
  echo "mysql-mcp-wrapper: unable to resolve a project from current working directory or overrides" >&2
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

find_lando_db_service() {
  local explicit_service="${MYSQL_LANDO_SERVICE:-}"

  if [[ -n "$explicit_service" ]]; then
    jq -er --arg service "$explicit_service" '
      map(
        select(
          .service == $service and
          .external_connection.host? and
          .external_connection.port? and
          .creds.user? and
          .creds.password? and
          .creds.database?
        )
      )
      | first
      | .service
    ' <<<"$LANDO_JSON" 2>/dev/null || return 1
    return 0
  fi

  jq -er '
    def is_db:
      (.external_connection.host? and .external_connection.port? and
       .creds.user? and .creds.password? and .creds.database?);
    (
      map(select(.service == "database" and is_db)) +
      map(select((.service == "db" or .service == "mysql" or .service == "mariadb") and is_db)) +
      map(select(((.type // "") | test("mysql|mariadb"; "i")) and is_db))
    )
    | first
    | .service
  ' <<<"$LANDO_JSON" 2>/dev/null
}

LANDO_DB_SERVICE="$(find_lando_db_service || true)"
if [[ -z "$LANDO_DB_SERVICE" ]]; then
  echo "mysql-mcp-wrapper: unable to identify a Lando MySQL service. Set MYSQL_LANDO_SERVICE to override." >&2
  exit 1
fi

find_service_json() {
  local filter="$1"
  jq -r --arg service "$LANDO_DB_SERVICE" '
    map(select(.service == $service))
    | first
    | '"$filter"' // empty
  ' <<<"$LANDO_JSON" | first_nonempty
}

MYSQL_HOST="${MYSQL_HOST:-$(find_service_json '.external_connection.host?')}"
MYSQL_PORT="${MYSQL_PORT:-$(find_service_json '.external_connection.port?')}"
MYSQL_USER="${MYSQL_USER:-$(find_service_json '.creds.user?')}"
MYSQL_PASS="${MYSQL_PASS:-$(find_service_json '.creds.password?')}"
MYSQL_DB="${MYSQL_DB:-$(find_service_json '.creds.database?')}"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"

if [[ -z "${MYSQL_PORT:-}" || -z "${MYSQL_USER:-}" || -z "${MYSQL_PASS:-}" || -z "${MYSQL_DB:-}" ]]; then
  echo "mysql-mcp-wrapper: incomplete MySQL credentials from lando info for service $LANDO_DB_SERVICE" >&2
  exit 1
fi

export MYSQL_HOST MYSQL_PORT MYSQL_USER MYSQL_PASS MYSQL_DB
export ALLOW_DELETE_OPERATION="${ALLOW_DELETE_OPERATION:-false}"
export ALLOW_INSERT_OPERATION="${ALLOW_INSERT_OPERATION:-false}"
export ALLOW_UPDATE_OPERATION="${ALLOW_UPDATE_OPERATION:-false}"
export MYSQL_PROJECT_DIR="$PROJECT_DIR"
export MYSQL_LANDO_SERVICE="$LANDO_DB_SERVICE"

# Set up environment for execution
export NODE_PATH="${NODE_PATH:-$LOCAL_NODE_PATH_DIR}"
export PATH="$(dirname "$NODE_BIN"):$PATH"

if [[ ! -f "$MCP_SERVER_JS" ]]; then
  echo "mysql-mcp-wrapper: MCP server entry point not found at $MCP_SERVER_JS" >&2
  exit 1
fi

exec "$NODE_BIN" "$MCP_SERVER_JS"
