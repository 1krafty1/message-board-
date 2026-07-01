#!/bin/bash
# ============================================================
# Message Board kiosk setup for Raspberry Pi OS (Desktop)
# Run on a FRESH Raspberry Pi OS install:
#   chmod +x setup-kiosk.sh && ./setup-kiosk.sh
# ============================================================
set -e

echo "=================================================="
echo " Message Board - Raspberry Pi kiosk setup"
echo "=================================================="
echo

# --- Gather config ---
read -rp "Enter the board URL (e.g. https://your-board.vercel.app/display.html): " BOARD_URL
if [ -z "$BOARD_URL" ]; then echo "No URL entered. Aborting."; exit 1; fi

USERNAME="$(whoami)"
HOMEDIR="$HOME"
echo
echo "Using URL:      $BOARD_URL"
echo "Using user:     $USERNAME"
echo "Home directory: $HOMEDIR"
echo
read -rp "Look right? Press Enter to continue, Ctrl+C to cancel. "

# --- Update + packages ---
echo
echo ">> Updating system and installing packages (this can take a while)..."
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y unclutter chromium-browser

# --- Detect Chromium binary name ---
if command -v chromium-browser >/dev/null 2>&1; then
  CHROMIUM="chromium-browser"
elif command -v chromium >/dev/null 2>&1; then
  CHROMIUM="chromium"
else
  echo "!! Chromium not found after install. Aborting."; exit 1
fi
echo ">> Chromium binary: $CHROMIUM"

CHROME_FLAGS="--kiosk --noerrdialogs --disable-infobars --incognito --disable-features=Translate --check-for-update-interval=31536000"

# --- Write the watchdog script ---
echo ">> Writing watchdog script..."
cat > "$HOMEDIR/kiosk-watchdog.sh" << WATCHDOG
#!/bin/bash
URL="$BOARD_URL"
FLAGS="$CHROME_FLAGS"
export DISPLAY=:0
while true; do
  if ! pgrep -x $CHROMIUM >/dev/null; then
    $CHROMIUM \$FLAGS "\$URL" >/dev/null 2>&1 &
  fi
  sleep 30
done
WATCHDOG
chmod +x "$HOMEDIR/kiosk-watchdog.sh"

# --- Write the systemd watchdog service ---
echo ">> Installing watchdog systemd service..."
sudo tee /etc/systemd/system/kiosk-watchdog.service >/dev/null << SERVICE
[Unit]
Description=Kiosk Chromium watchdog
After=graphical.target

[Service]
User=$USERNAME
Environment=DISPLAY=:0
ExecStart=$HOMEDIR/kiosk-watchdog.sh
Restart=always

[Install]
WantedBy=graphical.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable kiosk-watchdog.service

# --- Disable screen blanking (autostart classic path if present) ---
echo ">> Configuring screen blanking + autostart..."
CLASSIC="/etc/xdg/lxsession/LXDE-pi/autostart"
if [ -f "$CLASSIC" ]; then
  echo ">> Classic LXDE autostart found."
  # Remove any prior entries we may have added, then append fresh
  sudo sed -i '/# msgboard-kiosk/d' "$CLASSIC"
  echo "@xset s off          # msgboard-kiosk" | sudo tee -a "$CLASSIC" >/dev/null
  echo "@xset -dpms          # msgboard-kiosk" | sudo tee -a "$CLASSIC" >/dev/null
  echo "@xset s noblank      # msgboard-kiosk" | sudo tee -a "$CLASSIC" >/dev/null
  echo "@unclutter -idle 0   # msgboard-kiosk" | sudo tee -a "$CLASSIC" >/dev/null
  echo ">> Using systemd watchdog to launch Chromium (not autostart)."
else
  echo ">> Classic autostart not found (likely Wayland/labwc). Setting up labwc autostart."
  mkdir -p "$HOMEDIR/.config/labwc"
  LBW="$HOMEDIR/.config/labwc/autostart"
  touch "$LBW"
  sed -i '/# msgboard-kiosk/d' "$LBW"
  echo "unclutter -idle 0 &   # msgboard-kiosk" >> "$LBW"
  echo ">> NOTE: On Wayland, also set raspi-config -> Display Options -> Screen Blanking -> No"
fi

echo
echo "=================================================="
echo " Setup complete."
echo
echo " Still to do manually (one time):"
echo "  1. sudo raspi-config -> System Options -> Boot/Auto Login -> Desktop Autologin"
echo "  2. (Wayland only) raspi-config -> Display Options -> Screen Blanking -> No"
echo
echo " Then reboot:   sudo reboot"
echo " The board launches fullscreen via the watchdog service."
echo "=================================================="
