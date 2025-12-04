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
WEB_ENABLE=${WEB_ENABLE:-false}
WEB_REMOTE_API=${WEB_REMOTE_API:-}
WEB_USERNAME=${WEB_USERNAME:-}
WEB_PORT=${WEB_PORT:-11211}
WEB_API_PORT=${WEB_API_PORT:-11211}
WEB_SERVER_PORT=${WEB_SERVER_PORT:-22020}
WEB_SERVER_PROTOCOL=${WEB_SERVER_PROTOCOL:-udp}
WEB_DEFAULT_API_HOST=${WEB_DEFAULT_API_HOST:-http://127.0.0.1:$WEB_API_PORT}
WEB_LOG_LEVEL=${WEB_LOG_LEVEL:-warn}
WEB_DATA_DIR=${WEB_DATA_DIR:-/web}
CONFIG_DIR=${CONFIG_DIR:-}


# Ensure directories exist
mkdir -p "$WEB_DATA_DIR/logs"
if [ -n "$CONFIG_DIR" ]; then
  mkdir -p "$CONFIG_DIR"
fi

CORE_EXTRA_ARGS=()
if [ "$#" -gt 0 ]; then
  if [ "${1#-}" = "$1" ]; then
    log "[Core] Custom command detected: $*"
    exec "$@"
  else
    CORE_EXTRA_ARGS=("$@")
  fi
fi

if [ "$WEB_ENABLE" = "true" ]; then
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
    API_URL="http://$WEB_DEFAULT_API_HOST:$WEB_API_PORT"
  fi
  
  log "[Web] Using API URL: $API_URL"

  WEB_ARGS=(
    -d "$WEB_DATA_DIR/et.db"
    --file-log-level "$WEB_LOG_LEVEL"
    --file-log-dir "$WEB_DATA_DIR/logs"
    -c "$WEB_SERVER_PORT"
    -p "$WEB_SERVER_PROTOCOL"
    -a "$WEB_API_PORT"
    -l "$WEB_PORT"
    --api-host "$API_URL"
  )

  log "[Web] Executing command: $(format_cmd "$BINARY" "${WEB_ARGS[@]}")"

  $BINARY "${WEB_ARGS[@]}" &

  WEB_PID=$!
  log "[Web] easytier-web-embed started with PID $WEB_PID"
fi

log "[Core] Starting easytier-core..."

ARGS=()
if [ ${#CORE_EXTRA_ARGS[@]} -gt 0 ]; then
  ARGS+=("${CORE_EXTRA_ARGS[@]}")
fi

if [ "$WEB_ENABLE" = "true" ]; then
  if [ -n "$WEB_REMOTE_API" ]; then
      # If WEB_REMOTE_API is set, use it directly
      ARGS+=("-w" "$WEB_REMOTE_API")
  elif [ -n "$WEB_USERNAME" ]; then
      # Otherwise, use WEB_USERNAME if set
      ARGS+=("-w" "$WEB_SERVER_PROTOCOL://127.0.0.1:$WEB_SERVER_PORT/$WEB_USERNAME")
  fi

  MACHINE_ID_FILE="$WEB_DATA_DIR/et_machine_id"
  if [ ! -f "$MACHINE_ID_FILE" ]; then
      log "[Core] Generating new machine ID..."
      cat /proc/sys/kernel/random/uuid > "$MACHINE_ID_FILE"
  fi
  MACHINE_ID=$(cat "$MACHINE_ID_FILE")
  log "[Core] Using machine ID: $MACHINE_ID"
  ARGS+=("--machine-id" "$MACHINE_ID")
fi

if [ -n "$CONFIG_DIR" ]; then
  ARGS+=("--config-dir" "$CONFIG_DIR")
fi

log "[Core] Executing command: $(format_cmd easytier-core "${ARGS[@]}")"

exec easytier-core "${ARGS[@]}"
