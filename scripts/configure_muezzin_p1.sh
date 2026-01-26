#!/usr/bin/env bash
set -euo pipefail

###############################################
# Terraform → Bash Parameter Mapping
###############################################
SUPERUSER_NAME="$1"
CONFIG_FILE="$2"
CALC="$3"
MADHAB="$4"
LAT="$5"
LON="$6"
TZ="$7"
STARTUP="$8"
FAJR_CUSTOM="$9"
FAJR_URL="${10}"
DUA="${11}"

echo "------------------------------------------------------------"
echo " Starting Muezzin + Autologin Configuration Script - Part 1"
echo " User: $SUPERUSER_NAME"
echo " Config File: $CONFIG_FILE"
echo "------------------------------------------------------------"


###############################################################
# 1. Enable AutoLogin for the specified user
###############################################################
echo "[1/7] Enabling autologin for user: $SUPERUSER_NAME"

sudo awk -v user="$SUPERUSER_NAME" '
/^\[daemon\]/ {
    print;
    print "AutomaticLoginEnable=true";
    print "AutomaticLogin=" user;
    next
}
{ print }
' /etc/gdm3/daemon.conf \
| sudo tee /etc/gdm3/daemon.conf.tmp >/dev/null

sudo mv /etc/gdm3/daemon.conf.tmp /etc/gdm3/daemon.conf
echo "✓ Autologin enabled."


###############################################################
# 2. Install Muezzin via Flatpak
###############################################################
echo "[2/7] Installing Muezzin from Flathub…"

flatpak install flathub -y -u io.github.dbchoco.muezzin
echo "✓ Muezzin installed."


###############################################################
# 3. Create systemd user service
###############################################################
echo "[3/7] Creating systemd user service for Muezzin…"

sudo mkdir -p /etc/systemd/user

sudo tee /etc/systemd/user/muezzin.service >/dev/null <<EOF
[Unit]
Description=Start Muezzin App for '$SUPERUSER_NAME' on Login after delay
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
# Delay start to ensure Flatpak portal is ready
ExecStartPre=/bin/sleep 45
ExecStart=/usr/bin/flatpak run io.github.dbchoco.muezzin
Restart=no

[Install]
WantedBy=default.target
EOF

sudo chmod 644 /etc/systemd/user/muezzin.service

echo "✓ systemd service created."


###############################################################
# 4. Enable the service globally
###############################################################
echo "[4/7] Enabling Muezzin systemd service globally…"

sudo systemctl daemon-reload
sudo systemctl --global enable muezzin.service

echo "✓ Service enabled."
echo "To restart manually: systemctl --user restart muezzin.service"
###############################################################
echo "✓ Muezzin setup part 1 complete. Remaining steps after reboot."