# Message Board — Complete Setup Guide

Everything to go from nothing to a live TV board, in order. Work top to bottom; each section assumes the previous ones are done.

What you're building: a TV message board driven by Supabase, controlled from your phone via an admin page, displayed on a Raspberry Pi in kiosk mode. Four layouts, an info strip (weather, APG ticker, radar, welcomes, shoutouts, countdown, birthdays), scheduled + recurring messages, photos, QR codes, an emergency banner, and auto-rotate.

---

# Part 1 — Supabase backend

## 1.1 Create the project
Sign in at supabase.com, create a project. Note the project name; you'll grab keys in 1.4.

## 1.2 Run the base schema
**SQL Editor → New query →** paste and run:

```sql
-- Messages
create table messages (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  type text default 'info',          -- info | success | notice | alert
  label text,
  priority int default 0,            -- 1 = high (sorts first)
  active boolean default true,
  created_at timestamptz default now()
);

-- Photos
create table photos (
  id uuid primary key default gen_random_uuid(),
  url text not null,
  caption text,
  active boolean default true,
  created_at timestamptz default now()
);

-- Welcomes
create table welcomes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  subtitle text,
  active boolean default true,
  created_at timestamptz default now()
);

-- Board settings (single row)
create table board_settings (
  id uuid primary key default gen_random_uuid(),
  layout text default 'messages',    -- messages | photo | split | photobg
  show_weather boolean default true,
  show_ticker boolean default true,
  show_welcomes boolean default true
);
insert into board_settings (layout, show_weather, show_ticker, show_welcomes)
values ('messages', true, true, true);

-- RLS + anon access (internal board)
alter table messages enable row level security;
alter table photos enable row level security;
alter table welcomes enable row level security;
alter table board_settings enable row level security;
create policy "anon messages" on messages      for all using (true) with check (true);
create policy "anon photos" on photos           for all using (true) with check (true);
create policy "anon welcomes" on welcomes       for all using (true) with check (true);
create policy "anon settings" on board_settings for all using (true) with check (true);
```

## 1.3 Run the three wave migrations
Run these **in order**, each once, in the SQL Editor. (Files: SETUP-wave1.sql, SETUP-wave2.sql, SETUP-wave3.sql — contents are also inlined below.)

**Wave 1 — scheduling, QR, emergency, countdown, people:**
```sql
alter table messages add column if not exists start_at   timestamptz;
alter table messages add column if not exists end_at     timestamptz;
alter table messages add column if not exists qr_url     text;
alter table welcomes add column if not exists expires_at timestamptz;
alter table board_settings add column if not exists emergency_on   boolean default false;
alter table board_settings add column if not exists emergency_text text;
alter table board_settings add column if not exists show_countdown boolean default false;
alter table board_settings add column if not exists countdown_label text;
alter table board_settings add column if not exists countdown_date  timestamptz;
alter table board_settings add column if not exists show_birthdays  boolean default false;
create table if not exists people (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text default 'birthday',
  month int not null, day int not null, year int,
  active boolean default true,
  created_at timestamptz default now()
);
alter table people enable row level security;
create policy "anon people" on people for all using (true) with check (true);
```

**Wave 2 — radar + auto-rotate:**
```sql
alter table board_settings add column if not exists show_radar boolean default false;
alter table board_settings add column if not exists autorotate_on      boolean default false;
alter table board_settings add column if not exists autorotate_layouts text default 'messages,photo';
alter table board_settings add column if not exists autorotate_seconds int default 30;
```

**Wave 3 — recurring messages + shoutouts:**
```sql
alter table messages add column if not exists days_of_week text;
alter table messages add column if not exists time_start  text;
alter table messages add column if not exists time_end    text;
create table if not exists shoutouts (
  id uuid primary key default gen_random_uuid(),
  recipient text not null, message text not null, from_name text,
  approved boolean default false, active boolean default true,
  created_at timestamptz default now()
);
alter table shoutouts enable row level security;
create policy "anon shoutouts" on shoutouts for all using (true) with check (true);
alter table board_settings add column if not exists show_shoutouts boolean default false;
```

## 1.4 Storage bucket (for uploaded photos)
Skip if you'll only paste image URLs. Otherwise:
1. **Storage → New bucket →** name `board-photos` → **Public bucket ON** → Create.
2. **Storage → Policies → New policy** on `board-photos`: allow **INSERT** and **SELECT** for role `anon`, definition `true` (or the "allow everyone" template).

## 1.5 Grab your keys
**Project Settings → API** → copy the **Project URL** and the **anon public key**.

---

# Part 2 — The two web pages

## 2.1 Paste keys
Open `display.html` and `admin.html`. At the top of the `<script>` block in **each**, fill in the CONFIG:
```js
const SUPABASE_URL = "https://xxxx.supabase.co";
const SUPABASE_ANON_KEY = "eyJ...";
```
`admin.html` also has `STORAGE_BUCKET` (leave as `board-photos`).

## 2.2 Weather + stock keys (display.html only, both free, no card)
- **OpenWeather:** openweathermap.org → API keys → set `OPENWEATHER_KEY`. Grand Forks lat/lon are preset. New keys take ~2 hours to activate. (Also powers the radar tiles.)
- **Finnhub:** finnhub.io → free key → set `FINNHUB_KEY`. Symbol preset to `APG`. Free quotes may be delayed.
- Leaving either as the `YOUR-...` placeholder just leaves that panel blank — no errors.

## 2.3 Deploy
**Vercel (recommended):** put both files in a repo and deploy. You'll get:
- `https://your-board.vercel.app/display.html` → the Pi loads this
- `https://your-board.vercel.app/admin.html` → bookmark on your phone

**Confirm before touching the Pi:** open the display URL in a normal browser. You should see the board (empty messages is fine). If it loads, the backend + keys are good.

---

# Part 3 — Raspberry Pi (spare card; RetroPie card stays untouched)

## 3.1 Flash a spare card
Raspberry Pi Imager → **Raspberry Pi OS (64-bit) Desktop**. Click the gear and set:
- Hostname: `msgboard` (distinct from RetroPie's `retropie`)
- Enable SSH; set username + password
- Wi-Fi SSID + password (or Ethernet)
- Locale/timezone

Write it. Label the card "BOARD."

## 3.2 First boot
Insert card, connect HDMI (use the port nearest USB-C / labeled HDMI0 on Pi 4/5) + keyboard, power on. Let it reach the desktop.

## 3.3 Run the installer
Copy the `pi-kiosk` folder to the Pi (over SSH: `scp -r pi-kiosk msgboard.local:/home/YOUR-USERNAME/`, or via USB stick). Then:
```
cd ~/pi-kiosk
chmod +x setup-kiosk.sh
./setup-kiosk.sh
```
It asks for your board URL, then installs packages, the Chromium watchdog (auto-restarts if it crashes), screen-blanking off, and cursor hide.

## 3.4 Two manual settings (the installer prints these)
1. `sudo raspi-config` → **System Options → Boot/Auto Login → Desktop Autologin**
2. (Wayland only, if the script says so) `sudo raspi-config` → **Display Options → Screen Blanking → No**

## 3.5 Reboot
```
sudo reboot
```
It comes up fullscreen on the board.

## 3.6 HDMI display quirk (if you hit it)
If the TV looked fine at boot but scrambled once the OS loaded (this was the Windows symptom), force an exact mode. Edit `/boot/firmware/config.txt`:
```
disable_overscan=1
hdmi_force_hotplug=1
# if it still picks a bad mode, force 1080p60:
hdmi_group=1
hdmi_mode=16
```
Reboot. (On newer KMS Pi OS, auto-detect usually works; only add these if needed.)

---

# Part 4 — Optional Pi extras

## 4.1 Overnight screen off
Physically powers the TV/HDMI off at night, on in the morning.
```
sudo apt install -y cec-utils        # optional: lets it turn the actual TV off via HDMI-CEC
chmod +x ~/screen-schedule.sh
./screen-schedule.sh off              # test dark
./screen-schedule.sh on               # test back
crontab -e
```
Add (example: off 7pm / on 6am weekdays — adjust):
```
0 19 * * 1-5 /home/YOUR-USERNAME/screen-schedule.sh off
0 6  * * 1-5 /home/YOUR-USERNAME/screen-schedule.sh on
```

## 4.2 Remote reboot from your phone
**Simplest — SSH:** install Termius, add host `msgboard.local` + your login. Save snippets:
- Reboot: `sudo reboot`
- Restart display only: `pkill chromium; pkill chromium-browser`

**Web button (for non-technical people):** see `reboot-server.py` in the bundle — set a passcode, allow passwordless reboot, autostart it, reach it at `http://msgboard.local:8080`.

---

# Part 5 — Daily use (admin.html, by tab)

- **Layout** — pick the active layout; toggle strip panels (weather, ticker, radar, welcomes, shoutouts, birthdays, countdown); set the emergency banner; configure auto-rotate.
- **Messages** — add/edit/hide/delete. Priority "High" shows first and is the one used in Split/Photo-bg layouts. Optional: show-from/until window, repeat-on-days (recurring), from/until times, QR link.
- **Photos** — upload or paste a URL, optional caption. Used by photo/split/photo-bg layouts.
- **Welcomes** — name + subtitle; optional auto-remove after N days.
- **People** — birthdays/anniversaries; auto-celebrate on the day (needs the Layout toggle on).
- **Shoutouts** — post recognition; stays staged until you **Approve**. Queue a batch, release on a cadence.

## Switching the Pi between board and games
Power off, swap the card (BOARD ↔ RetroPie), power on. Nothing is lost either way.

---

# Part 6 — Tightening security later (optional)
The anon policies let anyone with the key read/write — fine for a trusted internal network. To lock down: make a read-only `select` policy for everyone and restrict writes to authenticated users, then add a Supabase login to `admin.html`. Or keep `admin.html` off the public internet (LAN only). Ask when you want this wired up.

---

# Quick reference — what each file is
- `display.html` — the TV view (loads on the Pi)
- `admin.html` — your phone/laptop control panel
- `SETUP-COMPLETE.md` — this guide
- `SETUP-wave1/2/3.sql` — the migrations (already inlined above)
- `pi-kiosk-bundle.zip` — `setup-kiosk.sh`, `screen-schedule.sh`, `reboot-server.py`, README, and the SQL files
