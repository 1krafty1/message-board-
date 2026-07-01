# Message Board — Raspberry Pi Bundle

Everything to turn a fresh Raspberry Pi OS install into the message board kiosk, on a spare card (your RetroPie card stays untouched).

Files:
- `setup-kiosk.sh` — one-shot installer (packages, watchdog, screen-blanking, autostart)
- `reboot-server.py` — optional phone control page (reboot / restart display, passcode-protected)
- `README.md` — this file

---

## Before you touch the Pi

Get `display.html` live and confirm it works in a normal browser first — the Pi just loads that URL.
- Deploy `display.html` + `admin.html` to Vercel, **with your Supabase + API keys already pasted in.**
- Open `https://your-board.vercel.app/display.html` on your computer. If it shows the board, you're good.

---

## 1. Flash a spare card

Raspberry Pi Imager → **Raspberry Pi OS (64-bit) Desktop**. Click the gear/edit icon and set:
- Hostname: `msgboard`  (distinct from RetroPie's `retropie` so they don't clash on the network)
- Enable SSH
- Username + password (remember them)
- Wi-Fi SSID + password (or use Ethernet)
- Locale / timezone

Write the card. Label it "BOARD" so you don't mix it with the RetroPie card.

## 2. First boot

Put the card in, connect HDMI + keyboard, power on. Let it reach the desktop and finish any updates.

## 3. Copy this bundle onto the Pi

Easiest: from your computer, copy the folder over SSH (Pi must be on the network):
```
scp -r pi-kiosk msgboard.local:/home/YOUR-USERNAME/
```
Or just copy `setup-kiosk.sh` onto a USB stick and drop it in your home folder.

## 4. Run the installer

On the Pi (terminal, or SSH in: `ssh msgboard.local`):
```
cd ~/pi-kiosk
chmod +x setup-kiosk.sh
./setup-kiosk.sh
```
It asks for your board URL, then handles packages, the watchdog service, screen-blanking, and cursor-hide automatically.

## 5. Two manual one-time settings

The installer prints these at the end:
1. `sudo raspi-config` → **System Options → Boot / Auto Login → Desktop Autologin**
2. (Only if your Pi uses Wayland, the script tells you) `sudo raspi-config` → **Display Options → Screen Blanking → No**

## 6. Reboot
```
sudo reboot
```
It comes up fullscreen on the board. The watchdog relaunches Chromium within 30s if it ever crashes.

---

## Remote control from your phone

### Option A — SSH (recommended, nothing to maintain)
Install **Termius** (free, iOS/Android). Add host `msgboard.local`, your username + password. Save these as one-tap snippets:
- Reboot: `sudo reboot`
- Restart display only: `pkill chromium; pkill chromium-browser`

Works anywhere on the same network. (For off-network access, add Tailscale later.)

### Option B — Web button page (for non-technical people)
A passcode-protected page you open in your phone browser.
```
sudo apt install -y python3-flask
# copy reboot-server.py into your home folder if it isn't already
nano ~/reboot-server.py          # set PASSCODE near the top
echo "$USER ALL=(ALL) NOPASSWD: /sbin/reboot" | sudo tee /etc/sudoers.d/board-reboot
```
Start it at boot — add to the autostart file the installer used:
- Classic path: add a line `@python3 /home/YOUR-USERNAME/reboot-server.py`
- labwc path (`~/.config/labwc/autostart`): add `python3 /home/YOUR-USERNAME/reboot-server.py &`

Then from your phone (same network): `http://msgboard.local:8080`

Security note: the page is only as private as your LAN + the passcode. Fine for a trusted office network; use SSH instead if that's a concern.

---

## Everyday operation

- **Switch the Pi back to gaming:** power off, swap in the RetroPie card, power on.
- **Switch back to the board:** swap the BOARD card back in.
- **Change the board content:** use `admin.html` from your phone — no Pi access needed.
- **Change the board URL on the Pi:** edit `~/kiosk-watchdog.sh`, then `sudo systemctl restart kiosk-watchdog`.
- **Check the watchdog:** `systemctl status kiosk-watchdog`
- **Get out of kiosk to fix something:** `Ctrl+Alt+T` for a terminal, or SSH in.

---

## Troubleshooting

- **Black screen / no Chromium:** `systemctl status kiosk-watchdog` — if failed, check the URL in `~/kiosk-watchdog.sh` is reachable.
- **Screen goes to sleep:** re-check the screen-blanking step (Wayland needs the raspi-config Display Options setting, not just xset).
- **Board loads but no weather/stock:** those keys live in `display.html` on Vercel, not on the Pi — fix them there and redeploy.
- **Wrong Chromium name:** the script auto-detects `chromium-browser` vs `chromium`; if you swap OS versions, re-run the script.
