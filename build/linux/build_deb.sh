#!/usr/bin/env bash
# Build lexa_1.0.0_all.deb for Ubuntu/Debian
#
# Usage: bash build/linux/build_deb.sh
# Output: dist/lexa_1.0.0_all.deb
# Requires: dpkg-deb (sudo apt install dpkg)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
PKG_NAME="lexa"
VERSION="1.0.0"
PKG_DIR="/tmp/lexa_deb_build"

mkdir -p "$DIST_DIR"
rm -rf "$PKG_DIR"

echo "=== Building ${PKG_NAME}_${VERSION}_all.deb ==="

# ── Package directory structure ───────────────────────────────────────────────
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/opt/lexa/scripts"
mkdir -p "$PKG_DIR/opt/lexa/scripts/linux"
mkdir -p "$PKG_DIR/usr/local/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/pixmaps"

# ── 1. control file ───────────────────────────────────────────────────────────
cat > "$PKG_DIR/DEBIAN/control" <<CONTROL
Package: lexa
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Depends: python3 (>= 3.9), python3-pip, xclip, libnotify-bin, python3-tk
Maintainer: Lexa Project <lexa@example.com>
Description: AI English Correction & Explanation Assistant
 Lexa uses AI (via OpenRouter) to correct English grammar and explain
 text in plain English. Works system-wide via keyboard shortcuts
 (Ctrl+Shift+E to correct, Ctrl+Shift+X to explain).
CONTROL

# ── 2. Copy Python scripts ────────────────────────────────────────────────────
for f in assistant.py config.py openrouter_client.py prompts.py popup_ui.py notifications.py requirements.txt; do
    cp "$PROJECT_DIR/$f" "$PKG_DIR/opt/lexa/scripts/"
done

cp "$PROJECT_DIR/linux/correct_english.sh" "$PKG_DIR/opt/lexa/scripts/linux/"
cp "$PROJECT_DIR/linux/explain_text.sh"    "$PKG_DIR/opt/lexa/scripts/linux/"

# Patch script paths to use /opt/lexa/scripts (compatible with BSD + GNU sed)
_sed_i() { sed -i.bak "$@" && rm -f "${@: -1}.bak"; }
_sed_i 's|SCRIPT_DIR=.*|SCRIPT_DIR="/opt/lexa/scripts"|' \
    "$PKG_DIR/opt/lexa/scripts/linux/correct_english.sh"
_sed_i 's|SCRIPT_DIR=.*|SCRIPT_DIR="/opt/lexa/scripts"|' \
    "$PKG_DIR/opt/lexa/scripts/linux/explain_text.sh"

chmod +x "$PKG_DIR/opt/lexa/scripts/linux/"*.sh

# ── 3. Copy icon ─────────────────────────────────────────────────────────────
if [[ -f "$PROJECT_DIR/../lexa.png" ]]; then
    cp "$PROJECT_DIR/../lexa.png" "$PKG_DIR/opt/lexa/lexa.png"
    cp "$PROJECT_DIR/../lexa.png" "$PKG_DIR/usr/share/pixmaps/lexa.png"
fi

# ── 4. lexa-setup command ─────────────────────────────────────────────────────
cat > "$PKG_DIR/usr/local/bin/lexa-setup" <<'SETUP'
#!/usr/bin/env bash
# Lexa interactive setup — configure API key and keyboard shortcuts
set -euo pipefail

CONFIG_DIR="$HOME/.config/lexa"
ENV_FILE="$CONFIG_DIR/.env"
SCRIPTS_DIR="/opt/lexa/scripts"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║        Lexa AI English Assistant         ║"
echo "║              Setup Wizard                ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# API Key
if [[ -f "$ENV_FILE" ]] && grep -qE "^OPENROUTER_API_KEY=.+" "$ENV_FILE" 2>/dev/null; then
    echo "✓ API key already configured."
    read -r -p "  Re-enter API key? [y/N] " RECONFIG
    [[ "$RECONFIG" =~ ^[Yy]$ ]] || RECONFIG="n"
else
    RECONFIG="y"
fi

if [[ "$RECONFIG" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Get a free API key at: https://openrouter.ai/keys"
    read -r -p "Enter your OpenRouter API key: " API_KEY
    if [[ -z "$API_KEY" ]]; then
        echo "ERROR: No API key entered. Run lexa-setup again."
        exit 1
    fi
    cat > "$ENV_FILE" <<DOTENV
OPENROUTER_API_KEY=${API_KEY}
CORRECTOR_MODEL=openai/gpt-4o-mini
CORRECTOR_TIMEOUT=5
CORRECTOR_MAX_CHARS=2000
DOTENV
    chmod 600 "$ENV_FILE"
    echo "✓ API key saved to $ENV_FILE"
fi

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
python3 -m pip install --user -q requests python-dotenv pyperclip
echo "✓ Dependencies installed"

# Register GNOME keyboard shortcuts
echo ""
if command -v gsettings &>/dev/null; then
    BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    CORRECT_CMD="bash /opt/lexa/scripts/linux/correct_english.sh"
    EXPLAIN_CMD="bash /opt/lexa/scripts/linux/explain_text.sh"

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
        "['${BASE}/lexa-correct/', '${BASE}/lexa-explain/']"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-correct/" \
        name "Lexa: Correct English"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-correct/" \
        command "$CORRECT_CMD"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-correct/" \
        binding "<Control><Shift>e"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-explain/" \
        name "Lexa: Explain Text"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-explain/" \
        command "$EXPLAIN_CMD"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${BASE}/lexa-explain/" \
        binding "<Control><Shift>x"

    echo "✓ Keyboard shortcuts registered:"
    echo "    Ctrl+Shift+E → Correct English"
    echo "    Ctrl+Shift+X → Explain Text"
else
    echo "ℹ GNOME not detected. Register shortcuts manually:"
    echo "    Correct: bash /opt/lexa/scripts/linux/correct_english.sh"
    echo "    Explain: bash /opt/lexa/scripts/linux/explain_text.sh"
fi

# Quick test
echo ""
echo "Testing API connection..."
if echo "I am test." | python3 "$SCRIPTS_DIR/assistant.py" --correct --quiet >/dev/null 2>&1; then
    echo "✓ API connection successful"
else
    echo "⚠ API test failed. Check your API key and internet connection."
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           Setup Complete! 🎉             ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Usage:"
echo "  • Select text → Ctrl+Shift+E  (Correct English)"
echo "  • Select text → Ctrl+Shift+X  (Explain Text)"
echo "  • CLI: echo 'text' | python3 /opt/lexa/scripts/assistant.py --correct"
SETUP
chmod +x "$PKG_DIR/usr/local/bin/lexa-setup"

# ── 5. postinst script ────────────────────────────────────────────────────────
cat > "$PKG_DIR/DEBIAN/postinst" <<'POSTINST'
#!/bin/bash
set -e
chmod -R 755 /opt/lexa/scripts
chmod +x /opt/lexa/scripts/linux/*.sh
echo ""
echo "Lexa installed successfully!"
echo "Run 'lexa-setup' to configure your API key and keyboard shortcuts."
echo ""
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

# ── 6. Desktop entry ──────────────────────────────────────────────────────────
cp "$BUILD_DIR/lexa.desktop" "$PKG_DIR/usr/share/applications/"

# ── 7. Set file permissions ───────────────────────────────────────────────────
find "$PKG_DIR" -type f -name "*.py"  -exec chmod 644 {} \;
find "$PKG_DIR" -type f -name "*.sh"  -exec chmod 755 {} \;
find "$PKG_DIR" -type f -name "*.txt" -exec chmod 644 {} \;

# ── 8. Build the .deb ─────────────────────────────────────────────────────────
echo "[Building .deb package...]"
dpkg-deb --build --root-owner-group "$PKG_DIR" "$DIST_DIR/${PKG_NAME}_${VERSION}_all.deb"

rm -rf "$PKG_DIR"

echo ""
echo "=== Done! ==="
echo "Package: dist/${PKG_NAME}_${VERSION}_all.deb"
echo ""
echo "Install on Ubuntu:"
echo "  sudo dpkg -i dist/${PKG_NAME}_${VERSION}_all.deb"
echo "  lexa-setup"
