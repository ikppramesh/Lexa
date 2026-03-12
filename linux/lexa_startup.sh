#!/usr/bin/env bash
# Lexa startup script — run on every login via GNOME autostart
# Ensures keyboard shortcuts and Python venv are always ready.

SCRIPT_DIR="/home/ramesh/Documents/Lexa"
LOG="$HOME/.lexa_startup.log"

echo "=== Lexa startup $(date) ===" >> "$LOG"

# 1. Ensure Python venv exists
if [[ ! -f "$SCRIPT_DIR/.venv/bin/python3" ]]; then
    echo "venv missing — recreating..." >> "$LOG"
    python3 -m venv "$SCRIPT_DIR/.venv"
    "$SCRIPT_DIR/.venv/bin/pip" install -q -r "$SCRIPT_DIR/requirements.txt"
fi

# 2. Re-register GNOME keyboard shortcuts (safe to run every login)
BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
    "['${BASE}/lexa-correct/', '${BASE}/lexa-explain/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-correct/" \
    name "Lexa: Correct English"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-correct/" \
    command "bash ${SCRIPT_DIR}/linux/correct_english.sh"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-correct/" \
    binding "<Control><Shift>e"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-explain/" \
    name "Lexa: Explain Text"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-explain/" \
    command "bash ${SCRIPT_DIR}/linux/explain_text.sh"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-explain/" \
    binding "<Control><Shift>x"

echo "Lexa shortcuts registered." >> "$LOG"
