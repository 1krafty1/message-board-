#!/usr/bin/env python3
# ============================================================
# Optional phone-friendly control page for the message board Pi.
# Reach it from a phone on the same network:  http://msgboard.local:8080
#
# Setup:
#   sudo apt install -y python3-flask
#   Set a passcode below (PASSCODE).
#   Allow passwordless reboot:
#     echo "$USER ALL=(ALL) NOPASSWD: /sbin/reboot" | sudo tee /etc/sudoers.d/board-reboot
#   Start at boot: add to autostart ->  @python3 /home/USERNAME/reboot-server.py
# ============================================================
from flask import Flask, request, redirect
import subprocess

# ---- Change this to any code you like (anyone on the LAN who knows it can reboot) ----
PASSCODE = "1234"
# --------------------------------------------------------------------------------------

app = Flask(__name__)

PAGE = '''<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Board Control</title>
<style>
 body{{font-family:system-ui,sans-serif;background:#0d1b2a;color:#e8eef5;text-align:center;padding:32px}}
 h1{{color:#5fd0df;font-size:22px}}
 input{{font-size:18px;padding:12px;border-radius:10px;border:1px solid #1b9aaa;background:#0a1622;
   color:#e8eef5;width:80%;max-width:240px;margin:10px 0;text-align:center}}
 button{{font-size:19px;font-weight:700;padding:16px 36px;margin:10px;border:none;border-radius:12px;cursor:pointer;width:80%;max-width:280px}}
 .reboot{{background:#1b9aaa;color:#fff}} .restart{{background:#3d3a14;color:#ffe07a}}
 .msg{{margin-top:16px;color:#9fb3c8}}
</style></head><body>
<h1>Message Board Control</h1>
<form method="post" action="/reboot">
  <input name="code" type="password" placeholder="Passcode" required><br>
  <button class="reboot">Reboot Pi</button>
</form>
<form method="post" action="/restart">
  <input name="code" type="password" placeholder="Passcode" required><br>
  <button class="restart">Restart display only</button>
</form>
<div class="msg">{msg}</div>
</body></html>'''

@app.route("/")
def home():
    return PAGE.format(msg="")

@app.route("/reboot", methods=["POST"])
def reboot():
    if request.form.get("code") != PASSCODE:
        return PAGE.format(msg="Wrong passcode."), 403
    subprocess.Popen(["sudo", "reboot"])
    return PAGE.format(msg="Rebooting now...")

@app.route("/restart", methods=["POST"])
def restart():
    if request.form.get("code") != PASSCODE:
        return PAGE.format(msg="Wrong passcode."), 403
    subprocess.Popen(["bash", "-c", "pkill chromium; pkill chromium-browser"])
    return PAGE.format(msg="Restarting display...")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
