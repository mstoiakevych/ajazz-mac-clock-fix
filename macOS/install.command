#!/bin/bash

echo "🕒 Installing Ajazz Mac Clock Fix (Native Swift Version)..."
echo "=========================================================="

# Navigate to the script directory
cd "$(dirname "$0")"

INSTALL_DIR="$HOME/.ajazz-clock-sync"
BIN_PATH="$INSTALL_DIR/ajazz_daemon"
PLIST_PATH="$HOME/Library/LaunchAgents/com.ajazz.clocksync.plist"

# 1. Create a hidden directory and copy the binary
mkdir -p "$INSTALL_DIR"
cp "ajazz_daemon" "$BIN_PATH"

# 2. Make it executable and remove Apple's Gatekeeper quarantine
chmod +x "$BIN_PATH"
xattr -cr "$BIN_PATH" 2>/dev/null

# 3. Create the launchd service configuration (plist)
cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ajazz.clocksync</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# 4. Load and start the background service
echo "⚙️ Setting up macOS background service..."
launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH"

echo "=========================================================="
echo "✅ Installation Complete!"
echo "⚠️ IMPORTANT: macOS blocks USB access by default."
echo "Please go to: System Settings -> Privacy & Security -> Input Monitoring"
echo "Click the '+' button, press Cmd+Shift+G, enter '~/.ajazz-clock-sync/'"
echo "and select 'ajazz_daemon' to grant it permission."
echo "=========================================================="
read -p "Press Enter to close this window..."