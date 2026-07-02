#!/bin/bash
# Overnight screen schedule: TV off 7pm, on 6am, Mon-Fri.
# Run once on the Pi:  cd ~/pi-kiosk && chmod +x install-schedule.sh && ./install-schedule.sh
set -e
cd "$(dirname "$0")"
cp screen-schedule.sh "$HOME/screen-schedule.sh"
chmod +x "$HOME/screen-schedule.sh"
sudo apt install -y cec-utils || echo "cec-utils install failed (optional - HDMI-CEC TV power); continuing"
( crontab -l 2>/dev/null | grep -v "screen-schedule.sh" ; \
  echo "0 19 * * 1-5 $HOME/screen-schedule.sh off" ; \
  echo "0 6  * * 1-5 $HOME/screen-schedule.sh on" ) | crontab -
echo "Done: screen off 7:00pm, on 6:00am, Monday-Friday."
echo "Test now with:  ~/screen-schedule.sh off   then   ~/screen-schedule.sh on"
