#!/bin/bash
# Reduce system volume in Debian 13 GNOME
# Works with PipeWire/PulseAudio (pactl) and falls back to ALSA (amixer) if needed

STEP=5          # Step size for each decrease in %
MIN_VOLUME=0    # Minimum allowed volume

# Function: Reduce volume using pactl
reduce_with_pactl() {
    SINK=$(pactl get-default-sink)
    if [ -z "$SINK" ]; then
        echo "Error: No default audio sink found."
        exit 1
    fi

    CURRENT_VOL=$(pactl get-sink-volume "$SINK" | awk '{print $5}' | head -n 1 | tr -d '%')
    NEW_VOL=$((CURRENT_VOL - STEP))
    if [ "$NEW_VOL" -lt "$MIN_VOLUME" ]; then
        NEW_VOL=$MIN_VOLUME
    fi

    pactl set-sink-volume "$SINK" "${NEW_VOL}%"
    echo "Volume set to ${NEW_VOL}% (via pactl)"
}

# Function: Reduce volume using amixer (ALSA)
reduce_with_amixer() {
    # Detect a real ALSA card (not "pipewire")
    CARD=$(aplay -l 2>/dev/null | grep "^card" | head -n 1 | awk '{print $2}' | tr -d ':')
    if [ -z "$CARD" ]; then
        echo "Error: No real ALSA card found. Install pactl instead."
        exit 1
    fi

    CURRENT_VOL=$(amixer -c "$CARD" get Master | grep -o '[0-9]\+%' | head -n 1 | tr -d '%')
    NEW_VOL=$((CURRENT_VOL - STEP))
    if [ "$NEW_VOL" -lt "$MIN_VOLUME" ]; then
        NEW_VOL=$MIN_VOLUME
    fi

    amixer -c "$CARD" set Master "${NEW_VOL}%"
    echo "Volume set to ${NEW_VOL}% (via amixer)"
}

# Main logic: Try pactl first, then amixer
if command -v pactl >/dev/null 2>&1; then
    reduce_with_pactl
elif command -v amixer >/dev/null 2>&1; then
    reduce_with_amixer
else
    echo "Error: Neither pactl nor amixer found."
    echo "  sudo apt install pulseaudio-utils   # for pactl (recommended)"
    echo "  sudo apt install alsa-utils         # for amixer"
    exit 1
fi
