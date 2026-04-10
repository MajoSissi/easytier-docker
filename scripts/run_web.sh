#!/bin/bash
set -e

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

format_cmd() {
  local cmd=$1
  shift || true
  printf '%s' "$cmd"
  local arg
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
}

# Default values
WEB_DISABLE_REGISTRATION=${WEB_DISABLE_REGISTRATION:-false}
WEB_PORT=${WEB_PORT:-11211}
WEB_SERVER_PORT=${WEB_SERVER_PORT:-22020}
WEB_SERVER_PROTOCOL=${WEB_SERVER_PROTOCOL:-udp}
WEB_DEFAULT_API_HOST=${WEB_DEFAULT_API_HOST:-http://127.0.0.1:$WEB_PORT}
WEB_LOG_LEVEL=${WEB_LOG_LEVEL:-warn}
WEB_DATA_DIR=/app/data/web
WEB_LOG_DIR=$WEB_DATA_DIR/logs
WEB_GEOIP_DIR=${WEB_GEOIP_DIR:-}

# Custom entrypoint command
CORE_EXTRA_ARGS=()
if [ "$#" -gt 0 ]; then
  if [ "${1#-}" = "$1" ]; then
    log "[Core] Custom command detected: $*"
    exec "$@"
  else
    CORE_EXTRA_ARGS=("$@")
  fi
fi

# Ensure web directory exists
mkdir -p "$WEB_LOG_DIR"

WEB_EXTRA_ARGS=()
if [ "$#" -gt 0 ]; then
  if [ "${1#-}" = "$1" ]; then
    log "[Web] Custom command detected: $*"
    exec "$@"
  else
    WEB_EXTRA_ARGS=("$@")
  fi
fi

log "[Web] Starting easytier-web-embed..."

# Check if easytier-web-embed exists
if command -v easytier-web-embed &> /dev/null; then
  BINARY=easytier-web-embed
else
  log "[Web] Error: easytier-web-embed binary not found."
  exit 1
fi

# Get API URL
if [[ "$WEB_DEFAULT_API_HOST" == http* ]]; then
  API_URL="$WEB_DEFAULT_API_HOST"
else
  # Assume it's just an IP/Host, append port and scheme
  API_URL="http://$WEB_DEFAULT_API_HOST:$WEB_PORT"
fi

log "[Web] Using API URL: $API_URL"

WEB_ARGS=(
  -d "$WEB_DATA_DIR/et.db"
  --console-log-level "$WEB_LOG_LEVEL"
  --file-log-level "$WEB_LOG_LEVEL"
  --file-log-dir "$WEB_LOG_DIR"
  -c "$WEB_SERVER_PORT"
  -a "$WEB_PORT"
  -p "$WEB_SERVER_PROTOCOL"
  --api-host "$API_URL"
)

if [ -n "$WEB_GEOIP_DIR" ]; then
  WEB_ARGS+=("--geoip-db" "$WEB_GEOIP_DIR")
fi

if [ "$WEB_DISABLE_REGISTRATION" = "true" ]; then
  WEB_ARGS+=(--disable-registration)
fi

if [ ${#WEB_EXTRA_ARGS[@]} -gt 0 ]; then
  WEB_ARGS+=("${WEB_EXTRA_ARGS[@]}")
fi

log "[Web] Executing command: $(format_cmd "$BINARY" "${WEB_ARGS[@]}")"

exec "$BINARY" "${WEB_ARGS[@]}"
