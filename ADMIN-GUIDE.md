# ICS Message Board — Admin Guide

Everything you need to run the lobby/floor TV board from your phone or computer. No technical knowledge required.

---

## The two links

| What | Link | Who uses it |
|------|------|-------------|
| **The board** (what shows on the TV) | `https://message-board-rust-nine.vercel.app/display.html` | The Pi loads this automatically — you rarely open it |
| **Admin** (your control panel) | `https://message-board-rust-nine.vercel.app/admin.html` | You. **Bookmark this on your phone.** |
| **Shoutout form** (for anyone) | `https://message-board-rust-nine.vercel.app/shoutout.html` | Coworkers, via the QR code on the board |

Changes you make in Admin appear on the TV **within about 30 seconds**.

---

## Signing in

The admin page asks for an email and password the first time.

- **Email:** randy.kraft@gmail.com
- **Password:** the one you set (change it anytime in Supabase → Authentication)

It remembers you on that device, so you normally won't have to sign in again. There's a **Sign out** button by the title if you ever need it. Anyone can *view* the board, but only signed-in admins can change anything.

**Board online indicator:** just under the title you'll see a green **● Board online** when the TV/Pi is running, or a red **● Board offline** with the last-seen time if it has stopped. Quick way to check the board is alive without walking over to it.

---

## The tabs

The admin page has six tabs across the top: **Layout · Messages · Photos · Welcomes · People · Shoutouts.**

At the very top of the Layout tab is a **Live board preview** — a shrunken copy of the actual TV. Hit **Refresh** on it after a change to see it right away.

---

## Messages (the main event)

The rotating announcements in the center of the board.

**To add one:**
1. Go to **Messages**
2. (Optional) tap a **Quick template** — Meeting, Welcome, Safety, Congrats, Deadline — to pre-fill the text and style, then edit the blanks (`___`)
3. Type your message
4. Pick a **Type** — this sets the color accent:
   - **Info** = teal · **Success** = green · **Notice** = yellow · **Alert** = red
5. (Optional) add a **Label** — a little pill above the message, e.g. "HEADS UP"
6. (Optional) **Priority: High** — shows first, and is the one used by the Split / Photo-background layouts
7. Tap **Add message**

**Scheduling (all optional):**
- **Show from / until** — a one-time window; the message hides itself outside it
- **Repeat on days** — tick Mon/Wed/etc. to make it a recurring weekly message
- **From / Until time** — limit recurring messages to certain hours (e.g. a morning safety note)
- **QR code link** — paste a URL and a scannable code appears next to the message

**Managing them:** each message in the list has **Hide/Show**, **Edit**, and **Delete**. Hidden messages stay in the list but don't show on the TV.

---

## Photos & videos

Used by the Photo, Split, and Photo-background layouts.

- **Upload** an image, or a short **video** (MP4/WebM), **or** paste an image/video URL
- Add an optional **caption** (shows on full-screen and photo-background layouts)
- Photos get a gentle slow-zoom (Ken Burns) effect
- Videos play **muted**, up to 60 seconds each, in the full-screen photo layout; other layouts skip them
- **Hide/Show** and **Delete** work like messages. (Deleting removes it from the board; the stored file stays in the bucket.)

---

## Welcomes

New-hire / visitor greetings that appear in the bottom strip.

- Add a **Name** and optional **Subtitle** (e.g. "New IT Technician")
- **Auto-remove after** — optionally have it disappear on its own after 3/7/14/30 days
- Only shows on the TV while at least one welcome is active *and* the Welcomes strip panel is on (Layout tab)

---

## People (birthdays & anniversaries)

- Add a **Name**, pick **Birthday** or **Work anniversary**, and the **month/day**
- For anniversaries, add the **start year** to show "X years"
- These celebrate **automatically on the day**, as long as **Birthdays & anniversaries** is toggled on in the Layout tab

---

## Shoutouts (recognition)

Two ways they arrive:
1. **You add them** in the Shoutouts tab
2. **Coworkers submit them** by scanning the QR code shown on the board's shoutout panel (opens the shoutout form)

**Every shoutout is "staged" until you approve it** — nothing appears on the TV until you tap **Approve**. This lets you screen submissions and release a batch on your own cadence. Each has **Approve/Unapprove**, **Edit**, **Delete**.

To show the QR code and approved shoutouts on the TV, turn on **Shoutouts** in the Layout tab.

---

## Layout tab — controlling the TV

**Active layout** — pick one:
- **Messages + strip** — rotating messages up top, info strip along the bottom (the everyday choice)
- **Full-screen photo** — photos/videos fill the screen
- **Split** — photo on the left, top message on the right
- **Photo background** — message over a full-screen photo

**Theme** — Dark (default) or Light. Holiday accent colors turn on automatically in December, early July, and late October.

**Bottom strip panels** (Messages layout only) — toggle any of these on/off:
- Weather · APG stock ticker · Radar · **5-day forecast** · **News headlines** · **Quote of the day** · **Sports** (UND hockey, Vikings, Twins) · Shoutouts · Welcomes · Birthdays · Countdown

Weather and the ticker stay visible at all times; the rest rotate through the third slot.

**Countdown** — turn it on, set a **label** and **date** to show "X days until ___".

**Emergency banner** — flip it on and type a message for a red bar across the top of the board (the rest of the board stays visible). Use for weather, evacuations, etc. **Turn it off when the situation passes.**

**Auto-rotate layouts** — have the board cycle through several layouts automatically. Turn it on, tick 2+ layouts, and set seconds-per-layout. This overrides the single layout picker while it's on.

---

## The Raspberry Pi (the TV box)

You normally never touch this — it runs itself.

- **It boots straight into the board** and relaunches automatically if it ever crashes.
- **Overnight:** the screen turns off at 7:00 PM and back on at 6:00 AM, Monday–Friday.
- **To restart it:** unplug its power, wait 5 seconds, plug back in. It returns to the board in about a minute.
- **Board vs. games:** if this Pi is shared with RetroPie, power off and swap the SD card (BOARD ↔ RetroPie). Nothing is lost either way.
- **Is it alive?** Check the green **● Board online** dot at the top of the admin page.

---

## Quick troubleshooting

| Problem | Fix |
|---------|-----|
| A change didn't show on the TV | Wait 30 seconds; the board refreshes on a cycle. Still nothing? Check **● Board online** in admin. |
| Admin says **● Board offline** | The Pi lost power or network. Power-cycle the Pi (unplug/replug). |
| Weather/ticker panel is blank | Usually a temporary data hiccup; it refills on its own. |
| A shoutout isn't on the TV | It's probably still **staged** — approve it in the Shoutouts tab, and make sure the Shoutouts panel is on. |
| A welcome/birthday isn't showing | Confirm it's active *and* the matching strip panel is toggled on in Layout. |
| Can't edit anything | Make sure you're **signed in** (the page will prompt you). |
| Board shows the wrong WiFi / won't connect after a move | The Pi's network is set for **NETGEAR94**. A new location needs its WiFi added — ask your tech contact. |

---

*Board built on Supabase + Vercel + a Raspberry Pi kiosk. For setup/technical details, see `SETUP-COMPLETE.md`.*
