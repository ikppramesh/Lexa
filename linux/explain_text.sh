#!/usr/bin/env bash
# Linux shortcut script: Explain Text (Ctrl+Shift+X)
# Reads selected text from clipboard, displays explanation in popup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-$SCRIPT_DIR/.venv/bin/python3}"

# Ensure DISPLAY is set for xclip (needed when launched via GNOME shortcut)
export DISPLAY="${DISPLAY:-:1}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

# Capture selected text NOW (primary selection is lost once Chrome loses focus)
SELECTED_TEXT="$(xclip -selection primary -o 2>/dev/null || true)"
if [[ -z "$SELECTED_TEXT" ]]; then
    SELECTED_TEXT="$(xclip -selection clipboard -o 2>/dev/null || true)"
fi

# Load .env if present
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Pipe captured text to Python via stdin
echo "$SELECTED_TEXT" | "$PYTHON" "$SCRIPT_DIR/assistant.py" --explain
