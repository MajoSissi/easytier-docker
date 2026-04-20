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
HOSTNAME=${HOSTNAME:-}
WEB_ENABLE=${WEB_ENABLE:-false}
WEB_REMOTE_API=${WEB_REMOTE_API:-}
WEB_ENABLE_REGISTRATION=${WEB_ENABLE_REGISTRATION:-false}
WEB_USERNAME=${WEB_USERNAME:-}
WEB_PORT=${WEB_PORT:-11211}
WEB_SERVER_PORT=${WEB_SERVER_PORT:-22020}
WEB_SERVER_PROTOCOL=${WEB_SERVER_PROTOCOL:-udp}
WEB_DEFAULT_API_HOST=${WEB_DEFAULT_API_HOST:-http://127.0.0.1:$WEB_API_PORT}
WEB_GEOIP_PATH=${WEB_GEOIP_PATH:-}
WEB_LOG_LEVEL=${WEB_LOG_LEVEL:-error}
CORE_LOG_LEVEL=${CORE_LOG_LEVEL:-error}
WEB_DATA_DIR=/app/data/web
WEB_LOG_DIR=/app/data/logs-web
CORE_LOG_DIR=/app/data/logs-core
CONFIG_DIR=/app/data/config

# Custom entrypoint command
if [ "$#" -gt 0 ]; then
  if [ "${1#-}" = "$1" ]; then
    log "[Core] Custom command detected: $*"
    exec "$@"
  fi
fi

# Web
if [ "$WEB_ENABLE" = "true" ]; then
  # Ensure directories exist
  mkdir -p "$WEB_DATA_DIR" "$WEB_LOG_DIR" "$CORE_LOG_DIR" "$CONFIG_DIR"
  log "[Web] Starting easytier-web-embed..."

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
    --file-log-dir "$WEB_LOG_DIR"
    -c "$WEB_SERVER_PORT"
    -a "$WEB_PORT"
    -p "$WEB_SERVER_PROTOCOL"
    --api-host "$API_URL"
  )

  if [ -n "$WEB_GEOIP_PATH" ]; then
    WEB_ARGS+=("--geoip-db" "$WEB_GEOIP_PATH")
  fi

  if [ "$WEB_ENABLE_REGISTRATION" = "false" ]; then
    WEB_ARGS+=(--disable-registration)
  fi
  log "[Web] Executing command: $(format_cmd easytier-web-embed "${WEB_ARGS[@]}")"

  easytier-web-embed "${WEB_ARGS[@]}" &

  WEB_PID=$!
  log "[Web] easytier-web-embed started with PID $WEB_PID"
fi

log "[Core] Starting easytier-core..."


# Core
CORE_ARGS=(
  --console-log-level "$CORE_LOG_LEVEL"
  --file-log-level "$CORE_LOG_LEVEL"
  --file-log-dir "$CORE_LOG_DIR"
  --file-log-size 30
  --file-log-count 5
)

if [ -n "$HOSTNAME" ]; then
  CORE_ARGS+=("--hostname" "$HOSTNAME")
fi

if [ "$WEB_ENABLE" = "true" ]; then
  CORE_ARGS+=("--config-dir" "$CONFIG_DIR")
  
  if [ -n "$WEB_REMOTE_API" ]; then
      # If WEB_REMOTE_API is set, use it directly
      CORE_ARGS+=("-w" "$WEB_REMOTE_API")
  elif [ -n "$WEB_USERNAME" ]; then
      # Otherwise, use WEB_USERNAME if set
      CORE_ARGS+=("-w" "$WEB_SERVER_PROTOCOL://127.0.0.1:$WEB_SERVER_PORT/$WEB_USERNAME")
  fi
fi

# Add machine ID if WEB_ENABLE is true or WEB_REMOTE_API is set
if [ "$WEB_ENABLE" = "true" ] || [ -n "$WEB_REMOTE_API" ]; then
  MACHINE_ID_FILE="$WEB_DATA_DIR/et_machine_id"
  if [ ! -f "$MACHINE_ID_FILE" ]; then
      log "[Core] Generating new machine ID..."
      cat /proc/sys/kernel/random/uuid > "$MACHINE_ID_FILE"
  fi
  MACHINE_ID=$(cat "$MACHINE_ID_FILE")
  log "[Core] Using machine ID: $MACHINE_ID"
  CORE_ARGS+=("--machine-id" "$MACHINE_ID")
fi

log "[Core] Executing command: $(format_cmd easytier-core "${CORE_ARGS[@]}")"

exec easytier-core "${CORE_ARGS[@]}"
