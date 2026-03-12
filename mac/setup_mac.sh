#!/usr/bin/env bash
# One-shot macOS setup for Lexa English Corrector
# Creates .env, installs dependencies, and registers Automator Quick Actions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="$HOME/Library/Services"

echo "=== Lexa macOS Setup ==="

# 1. Python check
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Install from https://python.org"
    exit 1
fi
echo "[1/5] Python3 found: $(python3 --version)"

# 2. Install Python dependencies
echo "[2/5] Installing Python dependencies..."
python3 -m pip install -q -r "$SCRIPT_DIR/requirements.txt"

# 3. Create .env from template if missing
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    chmod 600 "$SCRIPT_DIR/.env"
    echo "[3/5] Created .env — please edit it and set OPENROUTER_API_KEY"
else
    echo "[3/5] .env already exists — skipping"
fi

# 4. Make scripts executable
chmod +x "$SCRIPT_DIR/assistant.py"
chmod +x "$SCRIPT_DIR/mac/correct_english_service.sh"
chmod +x "$SCRIPT_DIR/mac/explain_text_service.sh"
echo "[4/5] Script permissions set"

# 5. Register Automator Quick Actions
mkdir -p "$SERVICES_DIR"

for MODE in correct explain; do
    if [[ "$MODE" == "correct" ]]; then
        SHORTCUT_MOD="command shift"
        SHORTCUT_KEY="e"
        SERVICE_NAME="Correct English (Lexa)"
        SCRIPT_NAME="correct_english_service.sh"
    else
        SHORTCUT_MOD="command shift"
        SHORTCUT_KEY="x"
        SERVICE_NAME="Explain Text (Lexa)"
        SCRIPT_NAME="explain_text_service.sh"
    fi

    BUNDLE_ID="com.lexa.$(echo "$MODE" | tr ' ' '-')"
    SHORTCUT_EQUIV="\$@$(echo "$SHORTCUT_KEY" | tr '[:lower:]' '[:upper:]')"

    WORKFLOW_DIR="$SERVICES_DIR/${SERVICE_NAME}.workflow/Contents"
    mkdir -p "$WORKFLOW_DIR"

    # Write Info.plist (required for macOS to register the service)
    cat > "$WORKFLOW_DIR/Info.plist" <<INFOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>${SERVICE_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleTypeRole</key>
	<string>Viewer</string>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>${SERVICE_NAME}</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSPortName</key>
			<string>${SERVICE_NAME}</string>
			<key>NSSendTypes</key>
			<array>
				<string>NSStringPboardType</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
INFOPLIST

    # Write Automator workflow plist
    cat > "$WORKFLOW_DIR/document.wflow" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>521.1</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMDocumentSpecificationVersion</key>
    <string>0.9</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMAccepts</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Optional</key>
                    <true/>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>AMActionVersion</key>
                <string>2.0.3</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>AMParameterProperties</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <dict/>
                    <key>shell</key>
                    <dict/>
                    <key>source</key>
                    <dict/>
                </dict>
                <key>AMProvides</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>echo "\$1" | pbcopy
bash "${SCRIPT_DIR}/mac/${SCRIPT_NAME}"</string>
                    <key>shell</key>
                    <string>/bin/bash</string>
                    <key>source</key>
                    <string>pass input as arguments</string>
                </dict>
            </dict>
        </dict>
    </array>
    <key>workflowMetaData</key>
    <dict>
        <key>serviceInputTypeIdentifier</key>
        <string>com.apple.Automator.text</string>
        <key>serviceOutputTypeIdentifier</key>
        <string>com.apple.Automator.nothing</string>
        <key>serviceProcessesInput</key>
        <integer>0</integer>
        <key>workflowTypeIdentifier</key>
        <string>com.apple.Automator.servicesMenu</string>
    </dict>
</dict>
</plist>
PLIST

    echo "    Installed: $SERVICE_NAME"
done

# Refresh macOS services cache so they appear immediately
/System/Library/CoreServices/pbs -update

echo "[5/5] Quick Actions installed to ~/Library/Services"
echo ""
echo "=== Setup complete! ==="
echo ""
echo "NEXT STEPS:"
echo "  1. Edit '$SCRIPT_DIR/.env' and set OPENROUTER_API_KEY"
echo "  2. Enable the services:"
echo "     System Settings → Keyboard → Shortcuts → Services → Text"
echo "     Check 'Correct English (Lexa)' and 'Explain Text (Lexa)'"
echo "  3. Select any text, right-click → Services → Correct English (Lexa)"
echo "     or use  Cmd+Shift+E / Cmd+Shift+X"
