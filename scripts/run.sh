#!/bin/bash
set -e

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
WEB_LOG_LEVEL=${WEB_LOG_LEVEL:-}
CORE_LOG_LEVEL=${CORE_LOG_LEVEL:-}
WEB_DATA_DIR=/app/data/web
WEB_LOG_DIR=/app/data/logs-web
CORE_LOG_DIR=/app/data/logs-core
CONFIG_DIR=/app/data/config

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

format_cmd() {
  local cmd=$1
  shift || true
  printf '\n|%s' "$cmd"
  local arg
  local next
  while [ $# -gt 0 ]; do
    arg=$1
    shift
    # 检查下一个参数是否是选项（以-开头）
    if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
      next=$1
      shift
      printf '\n|  %q %q' "$arg" "$next"
    else
      printf '\n|  %q' "$arg"
    fi
  done
}

start_web() {
  log "[Web] Starting easytier-web-embed..."
  # Ensure directories exist
  mkdir -p "$WEB_DATA_DIR" "$WEB_LOG_DIR"

  # Get API URL
  if [[ "$WEB_DEFAULT_API_HOST" == http* ]]; then
    API_URL="$WEB_DEFAULT_API_HOST"
  else
    # Assume it's just an IP/Host, append port and scheme
    API_URL="http://$WEB_DEFAULT_API_HOST:$WEB_API_PORT"
  fi
  
  log "[Web] Using API URL: $API_URL"

  WEB_BIN="easytier-web-embed"
  WEB_ARGS=(
    --db "$WEB_DATA_DIR/et.db"
    --file-log-dir "$WEB_LOG_DIR"
    --config-server-protocol "$WEB_SERVER_PROTOCOL"
    --config-server-port "$WEB_SERVER_PORT"
    --api-server-port "$WEB_PORT"
    --api-host "$API_URL"
  )

  if [ -n "$WEB_LOG_LEVEL" ]; then
    WEB_ARGS+=(--file-log-level "$WEB_LOG_LEVEL")
  fi


  if [ -n "$WEB_GEOIP_PATH" ]; then
    WEB_ARGS+=("--geoip-db" "$WEB_GEOIP_PATH")
  fi

  if [ "$WEB_ENABLE_REGISTRATION" = "false" ]; then
    WEB_ARGS+=(--disable-registration)
  fi

  log "[Web] Executing command: $(format_cmd $WEB_BIN "${WEB_ARGS[@]}")"

  $WEB_BIN "${WEB_ARGS[@]}" &

  WEB_PID=$!
  log "[Web] $WEB_BIN started with PID $WEB_PID"
}

start_core() {
  log "[Core] Starting easytier-core..."
  # Ensure directories exist
  mkdir -p "$CORE_LOG_DIR" "$CONFIG_DIR"

  CORE_BIN="easytier-core"
  CORE_ARGS=(
    --file-log-dir "$CORE_LOG_DIR"
    --file-log-size 30
    --file-log-count 5
  )

  if [ -n "$CORE_LOG_LEVEL" ]; then
    CORE_ARGS+=(    
      --console-log-level "$CORE_LOG_LEVEL"
      --file-log-level "$CORE_LOG_LEVEL"
    )
  fi

  if [ -n "$HOSTNAME" ]; then
    CORE_ARGS+=("--hostname" "$HOSTNAME")
  fi

  if [ "$WEB_ENABLE" = "true" ]; then
    CORE_ARGS+=("--config-dir" "$CONFIG_DIR")
    if [ -n "$WEB_REMOTE_API" ]; then
        # If WEB_REMOTE_API is set, use it directly
        CORE_ARGS+=("--config-server" "$WEB_REMOTE_API")
    elif [ -n "$WEB_USERNAME" ]; then
        # Otherwise, use WEB_USERNAME if set
        CORE_ARGS+=("--config-server" "$WEB_SERVER_PROTOCOL://127.0.0.1:$WEB_SERVER_PORT/$WEB_USERNAME")
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
    CORE_ARGS+=("--machine-id" "$MACHINE_ID")
  fi

  log "[Core] Executing command: $(format_cmd $CORE_BIN "${CORE_ARGS[@]}")"

  exec $CORE_BIN "${CORE_ARGS[@]}"
}

# Custom entrypoint command
if [ "$#" -gt 0 ]; then
  if [ "${1#-}" = "$1" ]; then
    log "[Core] Custom command detected: $*"
    exec "$@"
  fi
fi

# Web
if [ "$WEB_ENABLE" = "true" ]; then
  start_web
fi

# Core
start_core
