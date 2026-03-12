#!/usr/bin/env bash
# Lexa — Stop All Services
# Kills every Lexa-related process. Usable as a Quick Action (right-click menu)
# or run directly from Terminal.

pkill -f "assistant\.py"              2>/dev/null || true
pkill -f "com.apple.automator.runner" 2>/dev/null || true
pkill -f "WorkflowServiceRunner"      2>/dev/null || true

osascript -e 'display notification "All Lexa services stopped." with title "Lexa"' &>/dev/null &
