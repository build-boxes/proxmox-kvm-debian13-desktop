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
echo "Continuing with next steps..."

###############################################################
# 7. Update Muezzin Config JSON
###############################################################
echo "[7/7] Updating Muezzin config JSON using jq…"

FAJR_PATH='"$DOC_PATH"'
echo "Using Fajr Adhan path: $FAJR_PATH"

FILTER="."

append() {
    local key="$1"
    local value="$2"
    if [ -n "$value" ]; then
        FILTER="$FILTER | $key"
    fi
}

append ".calculationMethod.calcMethod = \"$CALC\"" "$CALC"
append ".calculationMethod.madhab = \"$MADHAB\"" "$MADHAB"
append ".latitude = \"$LAT\"" "$LAT"
append ".longitude = \"$LON\"" "$LON"
append ".timezone = \"$TZ\"" "$TZ"

# Boolean values
[ -n "$STARTUP" ]      && FILTER="$FILTER | .settings.startupSound = $STARTUP"
[ -n "$FAJR_CUSTOM" ]  && FILTER="$FILTER | .adhan.adhanFajr.custom = $FAJR_CUSTOM"
[ -n "$FAJR_PATH" ]    && FILTER="$FILTER | .adhan.adhanFajr.path = $FAJR_PATH"
[ -n "$DUA" ]          && FILTER="$FILTER | .adhan.dua.enabled = $DUA"

echo "Applying jq filter: $FILTER"

jq "$FILTER" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

echo "✓ Config updated successfully."

echo "------------------------------------------------------------"
echo " Muezzin setup completed successfully."
echo "------------------------------------------------------------"
echo "Please remember to Add Host PCI Device Pass through to the VM for Audio if needed."
echo "------------------------------------------------------------"
