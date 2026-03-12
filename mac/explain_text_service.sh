#!/usr/bin/env bash
# Automator Quick Action: Explain Text
# Triggered by: right-click menu or Cmd+Shift+X

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Clean up any stale runners from previous failed/stuck runs (not the current one)
pkill -9 -f "automator.runner"     2>/dev/null || true
pkill -9 -f "WorkflowServiceRunner" 2>/dev/null || true
sleep 0.2  # brief pause so the current runner isn't caught by the pkill above

# Prefer Homebrew Python (has proper SSL + no Xcode Tcl/Tk issues)
if [[ -x "/opt/homebrew/bin/python3" ]]; then
    PYTHON="/opt/homebrew/bin/python3"
elif [[ -x "/usr/local/bin/python3" ]]; then
    PYTHON="/usr/local/bin/python3"
else
    PYTHON="python3"
fi

# Load .env — check app support dir first (where Lexa.app saves the key),
# then fall back to the local script directory (dev installs)
CONFIG_DIR="$HOME/Library/Application Support/Lexa"
if [[ -f "$CONFIG_DIR/.env" ]]; then
    set -a; source "$CONFIG_DIR/.env"; set +a
elif [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

"$PYTHON" "$SCRIPT_DIR/assistant.py" --explain
