#!/bin/bash

echo "🗑️ Uninstalling Ajazz Linux Clock Fix..."
echo "========================================="

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  echo "Usage: sudo ./uninstall.sh"
  exit 1
fi

SERVICE_PATH="/etc/systemd/system/ajazz-clocksync.service"
INSTALL_DIR="/opt/ajazz-clock-sync"

# Stop and disable the systemd service
if [ -f "$SERVICE_PATH" ]; then
    systemctl stop ajazz-clocksync.service
    systemctl disable ajazz-clocksync.service
    rm "$SERVICE_PATH"
    systemctl daemon-reload
    echo "✅ systemd service stopped and removed."
fi

# Delete the installation directory containing the script and venv
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "✅ Python script and virtual environment removed."
fi

echo "========================================="
echo "Done! The fix has been completely removed from your Linux system."