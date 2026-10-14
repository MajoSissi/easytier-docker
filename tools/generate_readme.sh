#!/bin/bash
set -e

# Usage: ./generate_readme.sh <compose_file> [output_file] [--update <target_file> --marker <marker_name>]

COMPOSE_FILE="$1"
shift

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: Compose file '$COMPOSE_FILE' not found."
    exit 1
fi

# Read compose content
CONTENT=$(cat "$COMPOSE_FILE")

# Function to generate markdown block
generate_block() {
    echo '```yaml'
    echo "$CONTENT"
    echo '```'
}

if [ "$1" == "--update" ]; then
    TARGET_FILE="$2"
    shift 2
    if [ "$1" == "--marker" ]; then
        MARKER="$2"
        shift 2
    else
        echo "Error: --marker is required with --update"
        exit 1
    fi

    if [ ! -f "$TARGET_FILE" ]; then
        echo "Error: Target file '$TARGET_FILE' not found."
        exit 1
    fi

    START_MARKER="<!-- BEGIN_${MARKER} -->"
    END_MARKER="<!-- END_${MARKER} -->"

    # Create a temporary file for the new content
    TEMP_FILE=$(mktemp)
    
    # Use awk to replace the content between markers
    awk -v start="$START_MARKER" -v end="$END_MARKER" -v content="$(generate_block)" '
    $0 ~ start {print; print content; in_block=1; next}
    $0 ~ end {in_block=0}
    !in_block {print}
    ' "$TARGET_FILE" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$TARGET_FILE"
    echo "Updated $TARGET_FILE with content from $COMPOSE_FILE using marker $MARKER"

else
    OUTPUT_FILE="$1"
    if [ -z "$OUTPUT_FILE" ]; then
        echo "Error: Output file or --update argument required."
        exit 1
    fi
    
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    generate_block > "$OUTPUT_FILE"
    echo "Generated $OUTPUT_FILE from $COMPOSE_FILE"
fi
