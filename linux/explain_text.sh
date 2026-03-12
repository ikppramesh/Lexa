#!/usr/bin/env bash
# Linux shortcut script: Explain Text (Ctrl+Shift+X)
# Reads selected text from clipboard, displays explanation in popup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"

# Load .env if present
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

"$PYTHON" "$SCRIPT_DIR/assistant.py" --explain
