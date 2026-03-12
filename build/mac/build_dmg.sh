#!/usr/bin/env bash
# Build Lexa.app and Lexa-1.0.0.dmg
#
# Usage: bash build/mac/build_dmg.sh
# Output: dist/Lexa-1.0.0.dmg

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
APP_NAME="Lexa"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
APP_DIR="$DIST_DIR/${APP_NAME}.app"
ICNS="$BUILD_DIR/lexa.icns"

mkdir -p "$DIST_DIR"
rm -rf "$APP_DIR"

echo "=== Building ${APP_NAME}.app ==="

# ── 1. Create .app bundle skeleton ──────────────────────────────────────────
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources/scripts/mac"

# ── 2. Copy Python scripts ───────────────────────────────────────────────────
for f in assistant.py config.py openrouter_client.py prompts.py popup_ui.py notifications.py; do
    cp "$PROJECT_DIR/$f" "$APP_DIR/Contents/Resources/scripts/"
done
cp "$PROJECT_DIR/requirements.txt" "$APP_DIR/Contents/Resources/scripts/"

# ── 3. Copy macOS service scripts ────────────────────────────────────────────
cp "$PROJECT_DIR/mac/correct_english_service.sh" "$APP_DIR/Contents/Resources/scripts/mac/"
cp "$PROJECT_DIR/mac/explain_text_service.sh"    "$APP_DIR/Contents/Resources/scripts/mac/"
cp "$PROJECT_DIR/mac/stop_lexa_services.sh"      "$APP_DIR/Contents/Resources/scripts/mac/"
chmod +x "$APP_DIR/Contents/Resources/scripts/mac/"*.sh
# Service scripts resolve SCRIPT_DIR dynamically at runtime — no patching needed

# ── 4. Copy icon ─────────────────────────────────────────────────────────────
cp "$ICNS" "$APP_DIR/Contents/Resources/lexa.icns"

# ── 5. Write Info.plist ──────────────────────────────────────────────────────
cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Lexa</string>
    <key>CFBundleDisplayName</key>
    <string>Lexa</string>
    <key>CFBundleIdentifier</key>
    <string>com.lexa.english-corrector</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>lexa</string>
    <key>CFBundleIconFile</key>
    <string>lexa</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Lexa uses AppleScript to show correction and explanation dialogs.</string>
</dict>
</plist>
PLIST

# ── 6. Write main launcher ───────────────────────────────────────────────────
LAUNCHER="$APP_DIR/Contents/MacOS/lexa"
SCRIPTS_RES="$APP_DIR/Contents/Resources/scripts"

cat > "$LAUNCHER" <<'LAUNCHER_EOF'
#!/usr/bin/env bash
# Lexa main launcher — runs on double-click in Finder
APP_CONTENTS="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$APP_CONTENTS/Resources/scripts"
CONFIG_DIR="$HOME/Library/Application Support/Lexa"
ENV_FILE="$CONFIG_DIR/.env"

# Prefer Homebrew Python
if   [[ -x "/opt/homebrew/bin/python3" ]]; then PYTHON="/opt/homebrew/bin/python3"
elif [[ -x "/usr/local/bin/python3"    ]]; then PYTHON="/usr/local/bin/python3"
else                                             PYTHON="python3"
fi

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# ── First-run or reconfigure ──────────────────────────────────────────────────
NEEDS_KEY=0
if [[ ! -f "$ENV_FILE" ]]; then
    NEEDS_KEY=1
elif ! grep -qE "^OPENROUTER_API_KEY=.+" "$ENV_FILE" 2>/dev/null; then
    NEEDS_KEY=1
fi

if [[ "$NEEDS_KEY" -eq 1 ]]; then
    API_KEY=$(osascript <<'AS'
        set k to text returned of (display dialog "Welcome to Lexa!" & return & return & \
            "Enter your OpenRouter API key to get started." & return & \
            "Get a free key at openrouter.ai/keys" ¬
            default answer "" ¬
            with title "Lexa Setup" ¬
            buttons {"Cancel", "Set Up Lexa"} ¬
            default button "Set Up Lexa" ¬
            with icon note)
        return k
AS
    ) || exit 0   # user clicked Cancel

    # Trim leading/trailing whitespace (handles accidental spaces when pasting)
    API_KEY="${API_KEY#"${API_KEY%%[![:space:]]*}"}"
    API_KEY="${API_KEY%"${API_KEY##*[![:space:]]}"}"

    if [[ -z "$API_KEY" ]]; then
        osascript -e 'display alert "No API key entered. Please open Lexa again to set up." as warning'
        exit 0
    fi

    # Pick AI model
    MODEL=$(osascript <<'AS'
set labels to {"----- FREE MODELS -----", "openrouter/free  (auto-pick best free model)", "meta-llama/llama-3.3-70b-instruct:free  (Llama 3.3 70B)", "google/gemini-2.0-flash-exp:free  (Gemini 2.0 Flash)", "deepseek/deepseek-r1:free  (DeepSeek R1 - reasoning)", "deepseek/deepseek-v3:free  (DeepSeek V3)", "mistralai/mistral-7b-instruct:free  (Mistral 7B)", "meta-llama/llama-3.1-8b-instruct:free  (Llama 3.1 8B)", "qwen/qwen-2.5-72b-instruct:free  (Qwen 2.5 72B)", "microsoft/phi-3-mini-128k-instruct:free  (Phi-3 Mini)", "google/gemma-3-12b-it:free  (Gemma 3 12B)", "nvidia/nemotron-3-nano-30b-a3b:free  (Nemotron Nano 30B)", "----- PAID MODELS -----", "openai/gpt-4o-mini  (GPT-4o Mini - fast & cheap)", "openai/gpt-4o  (GPT-4o - most capable)", "anthropic/claude-haiku-4-5  (Claude Haiku)"}
set ids to {"openrouter/free", "openrouter/free", "meta-llama/llama-3.3-70b-instruct:free", "google/gemini-2.0-flash-exp:free", "deepseek/deepseek-r1:free", "deepseek/deepseek-v3:free", "mistralai/mistral-7b-instruct:free", "meta-llama/llama-3.1-8b-instruct:free", "qwen/qwen-2.5-72b-instruct:free", "microsoft/phi-3-mini-128k-instruct:free", "google/gemma-3-12b-it:free", "nvidia/nemotron-3-nano-30b-a3b:free", "openai/gpt-4o-mini", "openai/gpt-4o-mini", "openai/gpt-4o", "anthropic/claude-haiku-4-5"}
set chosen to choose from list labels ¬
    with title "Lexa — Choose AI Model" ¬
    with prompt "Choose a model (free models cost $0):" ¬
    default items {"openrouter/free  (auto-pick best free model)"} ¬
    without multiple selections allowed and empty selection allowed
if chosen is false then return "openrouter/free"
set idx to 1
repeat with i from 1 to count of labels
    if item i of labels is item 1 of chosen then set idx to i
end repeat
return item idx of ids
AS
    ) || MODEL="openrouter/free"
    [[ -z "$MODEL" ]] && MODEL="openrouter/free"

    # Write key and model quoted so special chars are preserved safely
    printf 'OPENROUTER_API_KEY="%s"\nCORRECTOR_MODEL=%s\nCORRECTOR_TIMEOUT=30\nCORRECTOR_MAX_CHARS=2000\n' \
        "$API_KEY" "$MODEL" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

# ── Install Python dependencies ───────────────────────────────────────────────
"$PYTHON" -m pip install --break-system-packages -q requests python-dotenv pyperclip 2>/dev/null || \
"$PYTHON" -m pip install -q requests python-dotenv pyperclip 2>/dev/null || true

# ── Install Automator Quick Actions ──────────────────────────────────────────
SERVICES_DIR="$HOME/Library/Services"
mkdir -p "$SERVICES_DIR"

install_service() {
    local service_name="$1"
    local script_name="$2"
    local bundle_id="$3"

    local wf_dir="$SERVICES_DIR/${service_name}.workflow/Contents"
    mkdir -p "$wf_dir"

    # Info.plist
    cat > "$wf_dir/Info.plist" <<INFOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${service_name}</string>
    <key>CFBundleIdentifier</key><string>${bundle_id}</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleTypeRole</key><string>Viewer</string>
    <key>NSServices</key>
    <array><dict>
        <key>NSMenuItem</key><dict><key>default</key><string>${service_name}</string></dict>
        <key>NSMessage</key><string>runWorkflowAsService</string>
        <key>NSPortName</key><string>${service_name}</string>
        <key>NSSendTypes</key><array><string>NSStringPboardType</string></array>
    </dict></array>
</dict>
</plist>
INFOPLIST

    local script_path="${SCRIPTS_DIR}/mac/${script_name}"
    cat > "$wf_dir/document.wflow" <<WFLOW
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key><string>521.1</string>
    <key>AMApplicationVersion</key><string>2.10</string>
    <key>AMDocumentSpecificationVersion</key><string>0.9</string>
    <key>actions</key>
    <array><dict><key>action</key><dict>
        <key>AMAccepts</key><dict>
            <key>Container</key><string>List</string>
            <key>Optional</key><true/>
            <key>Types</key><array><string>com.apple.cocoa.string</string></array>
        </dict>
        <key>AMActionVersion</key><string>2.0.3</string>
        <key>AMApplication</key><array><string>Automator</string></array>
        <key>AMParameterProperties</key><dict>
            <key>COMMAND_STRING</key><dict/>
            <key>shell</key><dict/>
            <key>source</key><dict/>
        </dict>
        <key>AMProvides</key><dict>
            <key>Container</key><string>List</string>
            <key>Types</key><array><string>com.apple.cocoa.string</string></array>
        </dict>
        <key>ActionBundlePath</key><string>/System/Library/Automator/Run Shell Script.action</string>
        <key>ActionName</key><string>Run Shell Script</string>
        <key>ActionParameters</key><dict>
            <key>COMMAND_STRING</key>
            <string>echo "\$1" | pbcopy
bash "${script_path}"</string>
            <key>shell</key><string>/bin/bash</string>
            <key>source</key><string>pass input as arguments</string>
        </dict>
    </dict></dict></array>
    <key>workflowMetaData</key><dict>
        <key>serviceInputTypeIdentifier</key><string>com.apple.Automator.text</string>
        <key>serviceOutputTypeIdentifier</key><string>com.apple.Automator.nothing</string>
        <key>serviceProcessesInput</key><integer>0</integer>
        <key>workflowTypeIdentifier</key><string>com.apple.Automator.servicesMenu</string>
    </dict>
</dict>
</plist>
WFLOW
}

install_service "Correct English (Lexa)" "correct_english_service.sh" "com.lexa.correct-english"
install_service "Explain Text (Lexa)"    "explain_text_service.sh"    "com.lexa.explain-text"
install_service "Stop Lexa Services"     "stop_lexa_services.sh"      "com.lexa.stop-services"

/System/Library/CoreServices/pbs -update

# ── Done ──────────────────────────────────────────────────────────────────────
osascript <<'DONE'
display dialog "Lexa is ready!" & return & return & "ENABLE SERVICES:" & return & "System Settings -> Keyboard -> Shortcuts -> Services -> Text" & return & "Check: Correct English (Lexa)" & return & "Check: Explain Text (Lexa)" & return & "Check: Stop Lexa Services" & return & return & "Then select any text and right-click -> Services to use Lexa." ¬
    with title "Lexa Setup Complete" ¬
    buttons {"Open System Settings", "Done"} ¬
    default button "Open System Settings" ¬
    with icon note

if button returned of result is "Open System Settings" then
    open location "x-apple.systempreferences:com.apple.preference.keyboard"
end if
DONE
LAUNCHER_EOF

chmod +x "$LAUNCHER"

echo "[1/3] Lexa.app created at $APP_DIR"

# ── 7. Build DMG ──────────────────────────────────────────────────────────────
echo "[2/3] Building DMG..."

DMG_STAGING="/tmp/lexa_dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# Copy app into staging
cp -r "$APP_DIR" "$DMG_STAGING/"

# Create symlink to /Applications for drag-install UX
ln -s /Applications "$DMG_STAGING/Applications"

# Create the DMG
hdiutil create \
    -volname "Lexa" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DIST_DIR/${DMG_NAME}.dmg"

rm -rf "$DMG_STAGING"

echo "[3/3] DMG built: $DIST_DIR/${DMG_NAME}.dmg"
echo ""
echo "=== Done! ==="
echo "Distribute: dist/${DMG_NAME}.dmg"
echo "Install:    Mount DMG → drag Lexa.app → /Applications → open Lexa"
