#!/bin/bash
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Default values
WEB_ENABLE=${WEB_ENABLE:-false}
WEB_USERNAME=${WEB_USERNAME:-}
WEB_PORT=${WEB_PORT:-11210}
WEB_API_PORT=${WEB_API_PORT:-11211}
WEB_SERVER_PORT=${WEB_SERVER_PORT:-22020}
WEB_SERVER_PROTOCOL=${WEB_SERVER_PROTOCOL:-udp}
WEB_DEFAULT_API_HOST=${WEB_DEFAULT_API_HOST:-http://127.0.0.1:$WEB_API_PORT}
WEB_DATA_DIR=${WEB_DATA_DIR:-/web}
WEB_LOG_LEVEL=${WEB_LOG_LEVEL:-warn}

# Ensure web directory exists
mkdir -p "$WEB_DATA_DIR/logs"

if [ "$WEB_ENABLE" = "true" ]; then
    log "Starting easytier-web-embed..."
    
    # Check if easytier-web-embed exists
    if command -v easytier-web-embed &> /dev/null; then
        BINARY=easytier-web-embed
    elif command -v easytier-web &> /dev/null; then
        BINARY=easytier-web
    else
        log "Error: easytier-web binary not found."
        exit 1
    fi

    # Get API URL
    if [[ "$WEB_DEFAULT_API_HOST" == http* ]]; then
            API_URL="$WEB_DEFAULT_API_HOST"
    else
            # Assume it's just an IP/Host, append port and scheme
            API_URL="http://$WEB_DEFAULT_API_HOST:$WEB_API_PORT"
    fi
    
    log "Using API URL: $API_URL"

    $BINARY \
        -d "$WEB_DATA_DIR/et.db" \
        --file-log-level "$WEB_LOG_LEVEL" \
        --file-log-dir "$WEB_DATA_DIR/logs" \
        -c "$WEB_SERVER_PORT" \
        -p "$WEB_SERVER_PROTOCOL" \
        -a "$WEB_API_PORT" \
        -l "$WEB_PORT" \
        --api-host "$API_URL" &
    
    WEB_PID=$!
    log "easytier-web-embed started with PID $WEB_PID"
fi

log "Starting easytier-core..."

ARGS=()
for arg in "$@"; do
    if [ -n "$arg" ]; then
        ARGS+=("$arg")
    fi
done

if [ "$WEB_ENABLE" = "true" ]; then
    if [ -n "$WEB_USERNAME" ]; then
        ARGS+=("-w" "$WEB_SERVER_PROTOCOL://127.0.0.1:$WEB_SERVER_PORT/$WEB_USERNAME")
    fi

    MACHINE_ID_FILE="$WEB_DATA_DIR/et_machine_id"
    if [ ! -f "$MACHINE_ID_FILE" ]; then
        log "Generating new machine ID..."
        cat /proc/sys/kernel/random/uuid > "$MACHINE_ID_FILE"
    fi
    MACHINE_ID=$(cat "$MACHINE_ID_FILE")
    log "Using machine ID: $MACHINE_ID"
    ARGS+=("--machine-id" "$MACHINE_ID")
fi

exec easytier-core "${ARGS[@]}"
