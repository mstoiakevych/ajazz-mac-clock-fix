#!/bin/bash

echo "🕒 Installing Ajazz Linux Clock Fix (Python Daemon)..."
echo "========================================================"

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  echo "Usage: sudo ./install.sh"
  exit 1
fi

# Navigate to the script directory
cd "$(dirname "$0")"

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 is not found."
    exit 1
fi

INSTALL_DIR="/opt/ajazz-clock-sync"
SERVICE_PATH="/etc/systemd/system/ajazz-clocksync.service"

echo "📦 Creating virtual environment and installing dependencies..."
mkdir -p "$INSTALL_DIR"

# Create an isolated virtual environment (Best Practice for Linux)
python3 -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install hidapi

# Copy the Python script
cp ajazz_daemon.py "$INSTALL_DIR/ajazz_daemon.py"

echo "⚙️ Setting up systemd background service..."

# Create the systemd unit file. Running as root for direct access to /dev/hidraw
cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Ajazz Clock Sync Daemon
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/ajazz_daemon.py
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
systemctl daemon-reload
systemctl enable ajazz-clocksync.service
systemctl restart ajazz-clocksync.service

echo "========================================================"
echo "✅ Installation Complete!"
echo "The daemon is now running in the background as a systemd service."
echo "You can check its status using: sudo systemctl status ajazz-clocksync.service"
echo "========================================================"