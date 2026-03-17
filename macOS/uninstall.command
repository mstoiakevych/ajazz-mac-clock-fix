#!/bin/bash

echo "🗑️ Uninstalling Ajazz Mac Clock Fix..."
echo "========================================="

PLIST_PATH="$HOME/Library/LaunchAgents/com.ajazz.clocksync.plist"
INSTALL_DIR="$HOME/.ajazz-clock-sync"

# Stop and remove the launchd service
if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null
    rm "$PLIST_PATH"
    echo "✅ Background service stopped and removed."
fi

# Delete the installation directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "✅ Executable files removed."
fi

echo "========================================="
echo "Done! The fix has been completely removed from your Mac."
read -p "Press Enter to close this window..."