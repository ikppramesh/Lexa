#!/usr/bin/env bash
# One-shot Ubuntu/GNOME setup for Lexa English Corrector
# Installs dependencies, creates .env, and registers keyboard shortcuts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Lexa Linux Setup ==="

# 1. Python check
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Run: sudo apt install python3 python3-pip"
    exit 1
fi
echo "[1/5] Python3 found: $(python3 --version)"

# 2. Install system dependencies
echo "[2/5] Installing system dependencies..."
if command -v apt-get &>/dev/null; then
    sudo apt-get install -y -q xclip libnotify-bin python3-tk python3-pip 2>/dev/null || true
fi

# 3. Install Python dependencies
python3 -m pip install -q -r "$SCRIPT_DIR/requirements.txt"

# 4. Create .env
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    chmod 600 "$SCRIPT_DIR/.env"
    echo "[3/5] Created .env — please edit it and set OPENROUTER_API_KEY"
else
    echo "[3/5] .env already exists — skipping"
fi

# 5. Make scripts executable
chmod +x "$SCRIPT_DIR/assistant.py"
chmod +x "$SCRIPT_DIR/linux/correct_english.sh"
chmod +x "$SCRIPT_DIR/linux/explain_text.sh"
echo "[4/5] Script permissions set"

# 6. Register GNOME keyboard shortcuts
if command -v gsettings &>/dev/null; then
    CORRECT_CMD="bash ${SCRIPT_DIR}/linux/correct_english.sh"
    EXPLAIN_CMD="bash ${SCRIPT_DIR}/linux/explain_text.sh"

    # GNOME custom shortcuts live under /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/
    BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
        "['${BASE_PATH}/lexa-correct/', '${BASE_PATH}/lexa-explain/']"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE_PATH}/lexa-correct/" \
        name "Lexa: Correct English"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE_PATH}/lexa-correct/" \
        command "$CORRECT_CMD"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE_PATH}/lexa-correct/" \
        binding "<Control><Shift>e"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE_PATH}/lexa-explain/" \
        name "Lexa: Explain Text"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE_PATH}/lexa-explain/" \
        command "$EXPLAIN_CMD"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE_PATH}/lexa-explain/" \
        binding "<Control><Shift>x"

    echo "[5/5] GNOME keyboard shortcuts registered:"
    echo "      Ctrl+Shift+E → Correct English"
    echo "      Ctrl+Shift+X → Explain Text"
else
    echo "[5/5] GNOME not detected — register shortcuts manually:"
    echo "      Correct: bash ${SCRIPT_DIR}/linux/correct_english.sh   (Ctrl+Shift+E)"
    echo "      Explain: bash ${SCRIPT_DIR}/linux/explain_text.sh      (Ctrl+Shift+X)"
fi

echo ""
echo "=== Setup complete! ==="
echo ""
echo "NEXT STEPS:"
echo "  1. Edit '$SCRIPT_DIR/.env' and set OPENROUTER_API_KEY"
echo "  2. Select any text, press Ctrl+Shift+E (correct) or Ctrl+Shift+X (explain)"
echo "  3. Test manually: echo 'I goed there' | python3 $SCRIPT_DIR/assistant.py --correct"
