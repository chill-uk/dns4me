#!/bin/bash
# dns4me UnifiOS setup script
# This script automates the setup steps described in the README.md

set -e

# --- Validation Section ---
# Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] This script must be run as root. Please run with sudo." >&2
  exit 1
fi

# Check for required commands
for cmd in curl systemctl; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "[ERROR] Required command '$cmd' not found. Please install it and try again." >&2
    exit 1
  fi
done

# Check for internet connectivity
if ! curl -s --head https://dns4me.net | grep '200 OK' >/dev/null; then
  echo "[ERROR] No internet connectivity or dns4me.net is unreachable." >&2
  exit 1
fi

# --- Main Setup ---

# 1. Download dns4me.sh to /data/custom/dns4me
echo "Creating /data/custom/dns4me and downloading dns4me.sh..."
mkdir -p /data/custom/dns4me
cd /data/custom/dns4me
if curl -fsSL https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS/data/custom/dns4me/dns4me.sh -o dns4me.sh; then
  echo "[OK] dns4me.sh downloaded."
else
  echo "[ERROR] Failed to download dns4me.sh." >&2
  exit 1
fi

# 2. Make the script executable
echo "Making dns4me.sh executable..."
chmod +x dns4me.sh

# 3. Download the systemd service file
echo "Downloading dns4me.service to /lib/systemd/system..."
if curl -fsSL https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS/lib/systemd/system/dns4me.service -o /lib/systemd/system/dns4me.service; then
  echo "[OK] dns4me.service downloaded."
else
  echo "[ERROR] Failed to download dns4me.service." >&2
  exit 1
fi

# 4. Reload systemd, enable and start the service
echo "Reloading systemd and enabling dns4me.service..."
systemctl daemon-reload
systemctl enable dns4me.service
systemctl start dns4me.service
if systemctl status dns4me.service >/dev/null 2>&1; then
  echo "[OK] dns4me.service is active."
else
  echo "[WARNING] dns4me.service may not be running. Check with: systemctl status dns4me.service" >&2
fi

# 5. (Optional) Download cron job for periodic updates
echo "Downloading cron job to /etc/cron.d and restarting cron..."
if curl -fsSL https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS/dns4me_cron -o /etc/cron.d/dns4me_cron; then
  echo "[OK] Cron job installed."
else
  echo "[WARNING] Failed to download cron job. Skipping." >&2
fi
if [[ -x /etc/init.d/cron ]]; then
  /etc/init.d/cron restart || true
fi

# 6. Reminder to edit API key and Telegram info
echo "\n---"
echo "Setup complete!"
echo "Please edit /data/custom/dns4me/dns4me.sh to add your dns4meApikey, groupId, and botToken."
echo "You can view logs with: sudo journalctl -u dns4me.service"
echo "---"
