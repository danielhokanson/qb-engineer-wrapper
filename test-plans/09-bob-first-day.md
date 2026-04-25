# Arc 9 — Bob's first hour on the floor

> **You are:** Bob ProductionWorker. It's 7 AM. You just walked in the
> shop door, coffee in hand. Sam (PM) sold a job to Acme Corp for 50
> brackets and yesterday Sam released it to the floor. Dan (Receiving)
> brought the steel up to bin A-3 first thing this morning. Your first
> task is to get the job started.
>
> **What needs to be true before you start:**
> - Job J-1001 exists in the **Materials Received** stage (created in
>   Arc 5, materials staged in Arc 8).
> - You have a PIN (1001) — set in Arc 1.
> - You're on a device that can act as the shop floor kiosk: a tablet,
>   a touchscreen monitor, or just a regular browser pointed at the
>   kiosk URL. Ideally with a barcode scanner or NFC reader attached.
>
> **Hand-off when done:** Yourself, in Arc 10. Same shift, same job —
> you're going to issue materials to it next.
>
> **Estimated time:** 15 minutes (most of which is sitting and
> watching the timer to make sure it's actually running).

---

## Why you're doing this

Three things have to happen before you can touch a machine: the system
needs to know you're at work today (clock in), you need to find the
job that's yours to run, and you need to start the timer so the labor
cost gets billed to the right job. Every shop you've ever worked at
has these three things — qb-engineer just calls them by slightly
different names than you might be used to.

This arc is mostly about validating that the **scan-to-clock-in** flow,
the **kiosk worker selection**, and the **timer + real-time kanban
update** all work cleanly. If any of those are awkward, the floor will
hate this product no matter what else it does.

---

## The walkthrough

### Step 1 — Open the shop floor kiosk

1. On your kiosk device, navigate to `/display/shop-floor` (your URL
   will be something like `https://qb-engineer.test/display/shop-floor`).
2. The screen should fill with a header bar (showing the time, search
   bar, working/break/unassigned counts) and a grid of worker cards —
   one for each person on the floor today, with their initials and
   "OUT" status to start.
3. **You should see your card** (BP, "Bob ProductionWorker", "OUT") in
   the grid alongside Carol, Dan, Mike, and Eddie. If your card is
   missing, the kiosk doesn't know you exist — back to Arc 1 to verify
   your account was created with the right role.

### Step 2 — Clock in

1. **Tap your badge on the NFC reader**, OR **scan your barcode** with
   the USB scanner, OR if you have neither, tap your worker card on
   screen — there should be a click-to-select fallback.
2. A PIN keypad pops up. Enter `1001`.
3. The keypad goes away. Your worker card should now show:
   - Status flipped from "OUT" to "IN" (or "WORKING")
   - A green status dot
   - A timer starting from 0
   - Possibly a list of jobs assigned to you, including J-1001

### Step 3 — Find your job

1. With your card selected, look for a panel or list of jobs assigned
   to you. **J-1001** (50 brackets, Acme Corp) should be in the list,
   showing it's in the **Materials Received** stage.
2. Tap J-1001. An action overlay should open with options like Start
   Timer, Mark Complete, etc.

### Step 4 — Start the timer

1. Tap **Start Timer**.
2. Two things should happen:
   - The job moves out of "Materials Received" and into **In
     Production** automatically (the act of starting the timer is the
     stage-advance signal)
   - A small timer appears on the job, ticking up
3. Your worker card on the kiosk should now show "In Production" or
   similar, and your "hours today" counter should be ticking.

### Step 5 — Confirm real-time sync to other screens (optional but useful)

This is the SignalR validation. If you can:

1. On a *different* device or browser, sign in as Mike Manager.
2. Navigate to **Kanban**.
3. Find the J-1001 card. It should already be sitting in the **In
   Production** column, with an indicator that Bob is actively timing
   it. You should see this *without refreshing the page* — the move
   should have shown up live the second you tapped Start Timer.

If this doesn't work — if Mike has to refresh to see the change — flag
it. The whole point of having a kanban board on a wall monitor is that
it updates as work happens.

### Step 6 — Let the timer run, then stop it

1. Wait at least 5 minutes (more is better — you're validating that
   the timer actually persists, not just that the UI changes).
2. Come back to the kiosk. Your card should still show the running
   timer, ticking up.
3. Tap your card → tap J-1001 → tap **Stop Timer**.
4. The timer stops. The job stays in "In Production" (you didn't
   complete it, just paused).
5. Your card may now show "On Break" or back to "IN" without an
   active timer — depending on how the kiosk models "stopped timer
   but still clocked in."

### Step 7 — Sanity check the time entry was recorded

Sign in as Bob in a regular browser (not the kiosk):

1. Go to **Time Tracking** (or **Account → My Time** — wherever the
   per-user time list lives).
2. There should be a single entry from today, against J-1001, for
   roughly the duration you let it run.
3. The entry should NOT be editable by Bob himself (only Mike Manager
   can correct other people's time, per Arc 16). It should be
   read-only with maybe a "Request correction" button.

---

## What you should see by the end

- [ ] Your worker card on the kiosk shows you as clocked in
- [ ] Job J-1001 is in the **In Production** stage on every kanban view
- [ ] A time entry exists for ~5+ minutes against J-1001 in your name
- [ ] Your "hours today" tile is non-zero
- [ ] The Mike-watching-kanban check from Step 5 worked (live update)

---

## What might be wrong (flag any of these)

### Kiosk / scan flow

- 🔴 **Badge tap does nothing** → scanner isn't paired with the device,
  or the device's kiosk-token has expired. Mike Manager has a
  re-pairing flow somewhere — find out where.
- 🔴 **PIN keypad accepts `0000` or `9999`** when you set yours to
  `1001` → PIN auth is broken. Major finding.
- 🔴 **My worker card isn't on the kiosk grid** → you're missing from
  the assigned-to-this-location list. Check your `WorkLocationId` in
  the user record.
- 🟡 **Three separate scans needed to clock in** (badge, then job,
  then timer) → can the kiosk infer "Bob's badge tap means start the
  job he last had open"? Note as a candidate optimization.
- 🟡 **The kiosk doesn't show me what jobs are mine** → I shouldn't
  have to know the job number from memory. The card should list my
  assigned work the moment I'm authenticated.

### Job / timer

- 🔴 **Timer doesn't survive a kiosk refresh** → if you stop and
  reload the page, the timer should still be running on the server.
- 🔴 **Starting the timer doesn't advance the stage** → manual stage
  advance is friction; the timer-start IS the "I'm working on it"
  signal.
- 🟡 **Two starts in a row create two separate time entries** instead
  of one continuous one → confusing for billing. Should consolidate
  or at least warn.

### Real-time sync (Step 5)

- 🔴 **Kanban doesn't update without a refresh** → SignalR is broken or
  not wired through nginx/Cloudflare. Open browser console on Mike's
  device, look for "WebSocket connection failed."
- 🟡 **The card visually moves but the assignee/time-on-task indicators
  don't refresh** → partial real-time. Worth a finding even though it
  works after refresh.

### Time entry record (Step 7)

- 🔴 **No time entry exists** → the timer was UI-only and didn't persist.
- 🔴 **Bob can edit his own time entries** → Bob can effectively bill
  for hours he didn't work. Major audit/security finding.
- 🟡 **The entry is editable by Bob but only certain fields** → still
  an audit problem; the whole entry should be read-only to the
  worker who created it.

---

## Hand-off

You stay signed in. **Continue to Arc 10** — same character, same
shift. You're about to issue 100 lbs of steel from bin A-3 to job
J-1001.
