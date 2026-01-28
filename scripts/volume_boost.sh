#!/bin/bash
# Volume boost script for Debian 13 GNOME
# Uses pactl (PulseAudio/PipeWire) if available, else falls back to amixer (ALSA)

MAX_VOLUME=150   # Maximum allowed volume percentage
STEP=5           # Step size for each increase

# Function: Boost volume using pactl
boost_with_pactl() {
    SINK=$(pactl get-default-sink)
    if [ -z "$SINK" ]; then
        echo "Error: No default audio sink found."
        exit 1
    fi

    CURRENT_VOL=$(pactl get-sink-volume "$SINK" | awk '{print $5}' | head -n 1 | tr -d '%')
    NEW_VOL=$((CURRENT_VOL + STEP))
    if [ "$NEW_VOL" -gt "$MAX_VOLUME" ]; then
        NEW_VOL=$MAX_VOLUME
    fi

    pactl set-sink-volume "$SINK" "${NEW_VOL}%"
    echo "Volume set to ${NEW_VOL}% (via pactl)"
}

# Function: Boost volume using amixer (ALSA)
boost_with_amixer() {
    CARD=$(amixer info | grep "Card default" | awk '{print $3}')
    if [ -z "$CARD" ]; then
        CARD="default"
    fi

    CURRENT_VOL=$(amixer -D "$CARD" get Master | grep -o '[0-9]\+%' | head -n 1 | tr -d '%')
    NEW_VOL=$((CURRENT_VOL + STEP))
    if [ "$NEW_VOL" -gt "$MAX_VOLUME" ]; then
        NEW_VOL=$MAX_VOLUME
    fi

    amixer -D "$CARD" set Master "${NEW_VOL}%"
    echo "Volume set to ${NEW_VOL}% (via amixer)"
}

# Main logic: Try pactl first, then amixer
if command -v pactl >/dev/null 2>&1; then
    boost_with_pactl
elif command -v amixer >/dev/null 2>&1; then
    boost_with_amixer
else
    echo "Error: Neither pactl nor amixer found. Install one of them."
    echo "  sudo apt install pulseaudio-utils   # for pactl"
    echo "  sudo apt install alsa-utils         # for amixer"
    exit 1
fi
