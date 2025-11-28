#!/bin/bash
set -e

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Default values
WEB_PORT=${WEB_PORT:-11211}
WEB_API_PORT=${WEB_API_PORT:-11211}
WEB_SERVER_PORT=${WEB_SERVER_PORT:-22020}
WEB_SERVER_PROTOCOL=${WEB_SERVER_PROTOCOL:-udp}
WEB_DEFAULT_API_HOST=${WEB_DEFAULT_API_HOST:-http://127.0.0.1:$WEB_API_PORT}
WEB_LOG_LEVEL=${WEB_LOG_LEVEL:-warn}
WEB_DATA_DIR=${WEB_DATA_DIR:-/web}

# Ensure web directory exists
mkdir -p "$WEB_DATA_DIR/logs"

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
  --console-log-level "$WEB_LOG_LEVEL"
  --file-log-level "$WEB_LOG_LEVEL"
  --file-log-dir "$WEB_DATA_DIR/logs"
  -c "$WEB_SERVER_PORT"
  -p "$WEB_SERVER_PROTOCOL"
  -a "$WEB_API_PORT"
  -l "$WEB_PORT"
  --api-host "$API_URL"
)

log "[Web] Executing command: $BINARY ${WEB_ARGS[*]}"

exec $BINARY "${WEB_ARGS[@]}"
