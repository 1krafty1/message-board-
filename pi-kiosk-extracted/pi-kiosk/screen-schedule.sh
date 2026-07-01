#!/bin/bash
# ============================================================
# Day/night screen control for the message board Pi.
# Turns the HDMI output (and TV, if CEC-capable) OFF overnight
# and ON in the morning, via cron.
#
# Install:
#   chmod +x screen-schedule.sh
#   Edit the ON/OFF times in the crontab step below.
#   Test now:  ./screen-schedule.sh off   then   ./screen-schedule.sh on
#
# Supports both legacy (vcgencmd/tvservice) and newer (wlr-randr/
# kms) Pi setups, plus HDMI-CEC to switch the actual TV.
# ============================================================

ACTION="$1"   # "on" or "off"

turn_off() {
  # Try CEC first (turns the TV itself to standby)
  command -v cec-client >/dev/null 2>&1 && echo "standby 0" | cec-client -s -d 1 >/dev/null 2>&1
  # Wayland / KMS (Bookworm)
  if command -v wlr-randr >/dev/null 2>&1; then
    export WAYLAND_DISPLAY=wayland-1
    for o in $(wlr-randr --json 2>/dev/null | grep -oP '"name":\s*"\K[^"]+'); do
      wlr-randr --output "$o" --off 2>/dev/null
    done
  fi
  # Legacy X / framebuffer
  command -v tvservice >/dev/null 2>&1 && tvservice -o >/dev/null 2>&1
  command -v vcgencmd >/dev/null 2>&1 && vcgencmd display_power 0 >/dev/null 2>&1
}

turn_on() {
  command -v cec-client >/dev/null 2>&1 && echo "on 0" | cec-client -s -d 1 >/dev/null 2>&1
  if command -v wlr-randr >/dev/null 2>&1; then
    export WAYLAND_DISPLAY=wayland-1
    for o in $(wlr-randr --json 2>/dev/null | grep -oP '"name":\s*"\K[^"]+'); do
      wlr-randr --output "$o" --on 2>/dev/null
    done
  fi
  command -v tvservice >/dev/null 2>&1 && { tvservice -p >/dev/null 2>&1; }
  command -v vcgencmd >/dev/null 2>&1 && vcgencmd display_power 1 >/dev/null 2>&1
  # nudge the framebuffer back after tvservice
  command -v fbset >/dev/null 2>&1 && fbset -depth 8 >/dev/null 2>&1 && fbset -depth 16 >/dev/null 2>&1
}

case "$ACTION" in
  off) turn_off ;;
  on)  turn_on ;;
  *) echo "Usage: $0 on|off"; exit 1 ;;
esac
