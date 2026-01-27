#!/usr/bin/env bash
set -euo pipefail

##################################################
# Helper Functions
##################################################
to_bool() {
    case "$1" in
        true|True|TRUE|1)   echo "true" ;;
        false|False|FALSE|0|"") echo "false" ;;
        *) echo "false" ;;  # default fallback
    esac
}

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
STARTUP=$(to_bool "$8")
FAJR_CUSTOM=$(to_bool "$9")
FAJR_URL="${10}"
DUA=$(to_bool "${11}")

echo "------------------------------------------------------------"
echo " Starting Muezzin + Autologin Configuration Script - Part 2"
echo " User: $SUPERUSER_NAME"
echo " Config File: $CONFIG_FILE"
echo "------------------------------------------------------------"

###############################################################
# 5. Download Fajr Adhan MP3
###############################################################
echo "[5/7] Downloading Fajr Adhan MP3…"

sudo -u "$SUPERUSER_NAME" mkdir -p "/home/$SUPERUSER_NAME/Music"

wget -O "/home/$SUPERUSER_NAME/Music/Fajr_azan.mp3" "${FAJR_URL:-https://media.assabile.com/assabile/adhan_3435370/31f4182515ea.mp3}"

echo "✓ Audio downloaded."

echo "Sleep 20 seconds to ensure file system is ready for Flatpak export…"
sleep 20

###############################################################
# 6. Grant Flatpak access to Music folder (Option 1)
###############################################################
echo "[6/7] Granting Muezzin access to Music folder…"

sudo flatpak override io.github.dbchoco.muezzin --filesystem="/home/$SUPERUSER_NAME/Music"
DOC_PATH="/home/$SUPERUSER_NAME/Music/Fajr_azan.mp3"
echo "Audio path set to: $DOC_PATH"

echo "✓ Flatpak override applied."


###############################################################
# 6.1 Wait for Confihg file to be ready, by first launch of Muezzin
###############################################################
echo "[6.1/7] Waiting for 6 minutes (maximum) for Muezzin config file to be ready..."

echo "Waiting for Muezzin config file to be created:"
echo "  $CONFIG_FILE"

MAX_WAIT=360     # 6 minutes
INTERVAL=5       # check every 5 seconds
WAITED=0

while [ ! -f "$CONFIG_FILE" ]; do
    if [ "$WAITED" -ge "$MAX_WAIT" ]; then
        echo "ERROR: Config file did not appear within 6 minutes."
        exit 1
    fi

    echo "  Not found yet... waited ${WAITED}s"
    sleep "$INTERVAL"
    WAITED=$((WAITED + INTERVAL))
done

echo "✓ Config file detected after ${WAITED}s"
echo "Stopping service muezzin to allow configuration update..."
systemctl --user stop muezzin.service
echo "✓ Service stopped."
echo "Replacing muezzin minimal config with initial full config..."
mv /home/"$SUPERUSER_NAME"/config.json "$CONFIG_FILE"
echo "✓ Config template copied."
echo "Continuing with next steps..."

###############################################################
# 7. Update Muezzin Config JSON
###############################################################
echo "[7/7] Updating Muezzin config JSON using jq and terraform parameters…"

FAJR_PATH=${DOC_PATH}

# Boolean normalization (Terraform → jq)
to_bool() {
    case "$1" in
        true|True|TRUE|1) echo "true" ;;
        false|False|FALSE|0|"") echo "false" ;;
        *) echo "false" ;;
    esac
}

STARTUP_BOOL=$STARTUP
FAJR_CUSTOM_BOOL=$FAJR_CUSTOM
DUA_BOOL=$DUA

# Build jq filter dynamically (using jq variables)
FILTER="."

append() {
    local jq_path="$1"   # e.g. .latitude
    local varname="$2"   # e.g. LAT
    local value="${!varname}"

    if [ -n "$value" ]; then
        FILTER="$FILTER | $jq_path = \$$varname"
    fi
}

# String fields
append ".calculationMethod.calcMethod" "CALC"
append ".calculationMethod.madhab" "MADHAB"
append ".latitude" "LAT"
append ".longitude" "LON"
append ".timezone" "TZ"
append ".adhan.adhanFajr.path" "FAJR_PATH"

# Boolean fields
append ".settings.startupSound" "STARTUP_BOOL"
append ".adhan.adhanFajr.custom" "FAJR_CUSTOM_BOOL"
append ".adhan.dua.enabled" "DUA_BOOL"

echo "Applying jq filter:"
echo "$FILTER"

# Build jq argument list dynamically
JQ_ARGS=()

add_arg() {
    local name="$1"
    local value="$2"
    if [ -n "$value" ]; then
        JQ_ARGS+=( --arg "$name" "$value" )
    fi
}

add_argjson() {
    local name="$1"
    local value="$2"
    if [ -n "$value" ]; then
        JQ_ARGS+=( --argjson "$name" "$value" )
    fi
}

# String args
add_arg "CALC" "$CALC"
add_arg "MADHAB" "$MADHAB"
add_arg "LAT" "$LAT"
add_arg "LON" "$LON"
add_arg "TZ" "$TZ"
add_arg "FAJR_PATH" "$FAJR_PATH"

# Boolean args
add_argjson "STARTUP_BOOL" "$STARTUP_BOOL"
add_argjson "FAJR_CUSTOM_BOOL" "$FAJR_CUSTOM_BOOL"
add_argjson "DUA_BOOL" "$DUA_BOOL"

# Apply jq update
jq "${JQ_ARGS[@]}" "$FILTER" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" \
  && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

echo "✓ Config updated successfully."

# Restart Muezzin Flatpak (not systemd)
echo "Restarting Muezzin Flatpak…"
#flatpak kill io.github.dbchoco.muezzin 2>/dev/null
systemctl --user restart muezzin.service
echo "✓ Restarted."

echo "------------------------------------------------------------"
echo " Muezzin setup completed successfully."
echo "------------------------------------------------------------"
echo "Please remember to Add Host PCI Device Pass through to the VM for Audio if needed."
echo "------------------------------------------------------------"
###################################################
# Manual Steps in Proxmox Host for PCI Pass Through
####################################################
# Get PCI Audio Device ID for Pass Through and Address
# First log into SSH Session on Proxmox Host.
# Then...
# lspci -nn | grep -i audio
# Example Output: 00:1f.3 Audio device [0403]: Intel Corporation Device [8086:a0c8] (rev 30)
# Use the following command to extract the values:
# read a b <<< $(lspci -nn | grep -i audio | awk '{gsub(/\[|\]/,""); print $1, $12 }')
# PCI_ADDR="$a"
# PCI_ID="$b"
# Make sure PCI_ID is included in /etc/modprobe.d/* file for vfio-pci
# echo "options vfio-pci ids=$PCI_ID" >> /etc/modprobe.d/vfio.conf
# Then add to VM Hardware - Add the PCI device to your VM In /etc/pve/qemu-server/<VMID>.conf
# echo "hostpci0: $PCI_ADDR" >> /etc/pve/qemu-server/<VMID>.conf
# Then reboot the VM to apply changes.
# qm reboot <VMID>
# qm status <VMID>
###################################################
