# Arc 1 — Bootstrap the system

> **You are:** Jill Admin. The system is brand new — nothing exists yet,
> not even your own account. You're going to create yourself, set up
> the company, and then create accounts for everyone else on the team.
>
> **What needs to be true before you start:** A fresh, empty qb-engineer
> install. The home page should redirect you to a setup wizard, not a
> login screen.
>
> **Hand-off when done:** Sam SalesPM in Arc 2.
>
> **Estimated time:** 25 minutes.

---

## Why you're doing this

Test Manufacturing Co. just bought qb-engineer. You're the IT person
setting up the system before any real work happens. By the end of this
arc, the company exists in the database, all eight people on the team
have accounts they can log in to, and the basic reference data
(storage bins, etc.) is in place so the engineers and sales folks have
something to work with starting tomorrow.

---

## The walkthrough

### Step 1 — Initial setup wizard

1. Open the qb-engineer URL in a browser. You should land on a setup
   page, NOT a login page.
2. The wizard asks for your admin account. Fill in:
   - **First name:** `Jill`
   - **Last name:** `Admin`
   - **Email:** `jill@test.local`
   - **Password:** `Test1234!`
3. The wizard then asks for company details. Fill in:
   - **Company name:** `Test Manufacturing Co.`
   - **Primary location name:** `Main Plant`
   - **Address:** any plausible address (the validation might verify it
     against USPS — see "What might be wrong" below if it complains)
4. Submit. You should land on the dashboard, signed in as Jill, with
   "Welcome" type messaging.

### Step 2 — Confirm Jill is set up correctly

1. In the top-right header, click your avatar. The menu should show
   "Jill Admin" as the signed-in user.
2. Click **Account** → confirm your profile shows the values you
   entered.
3. In the sidebar, the **Admin** link should be visible (it's only
   shown to admins). Click it. You should see the admin home page with
   tiles for Users, Settings, Integrations, etc.

### Step 3 — Create the rest of the cast

Still signed in as Jill, go to **Admin → Users → New User**. Create
each of the following accounts. For each one:

- Fill in first name, last name, email
- Assign the role listed
- Click **Send setup link** OR **Set password directly** (whichever
  the dialog offers)
- If you set the password directly, use `Test1234!` for everyone

| First | Last | Email | Role |
|---|---|---|---|
| Sam | SalesPM | sam@test.local | PM |
| Eddie | Engineer | eddie@test.local | Engineer |
| Olivia | OfficeManager | olivia@test.local | OfficeManager |
| Mike | Manager | mike@test.local | Manager |
| Bob | ProductionWorker | bob@test.local | ProductionWorker |
| Carol | ProductionWorker | carol@test.local | ProductionWorker |
| Dan | ReceivingWorker | dan@test.local | ProductionWorker |

After creating each, you should see them in the user list with their
role tag visible.

### Step 4 — Set PINs for shop floor users

Bob, Carol, Dan, Mike, and Eddie will all need PINs to authenticate at
the shop floor kiosk later. Find each in the user list and:

1. Click the user → look for a "Set PIN" or "PIN" action
2. Enter the PIN from the cast doc:

| Person | PIN |
|---|---|
| Bob | 1001 |
| Carol | 1002 |
| Dan | 1003 |
| Mike | 9001 |
| Eddie | 9002 |

Save.

> **If there's no PIN field on the user edit page** — that's a real
> finding. Note it. Workers can't authenticate at the kiosk without a
> PIN, so something is missing.

### Step 5 — Create the storage bins

Production needs places to put materials. Go to **Inventory →
Storage Locations** (or wherever the bin admin lives — might be under
Admin instead).

Create four bins:

| Bin code | Description |
|---|---|
| A-1 | Raw materials, shelf 1 |
| A-2 | Raw materials, shelf 2 |
| A-3 | Raw materials, shelf 3 (steel will go here in Arc 7) |
| B-1 | Finished goods, ready to ship |

These can be flat (no parent) or nested under "Main Plant" if the UI
asks for a parent location. Either is fine.

### Step 6 — Quick reference-data sanity check

Click around to make sure these admin-managed lists exist with at
least default content. You don't need to add anything — just confirm
they're not empty:

- **Admin → Reference Data → Job Stages** — should have stages like
  "Quote Requested", "Materials Ordered", "Materials Received", "In
  Production", "QC", "Shipped", etc.
- **Admin → Reference Data → Track Types** — should have at least
  "Production" and probably "R&D"
- **Admin → Reference Data → Priorities** — should have Low / Medium
  / High / Critical or similar

If any of these lists is empty, that's a finding — the seed data
didn't apply.

### Step 7 — Verify everyone can log in

Sign Jill out. For each account you created (Sam, Eddie, Olivia, Mike,
Bob, Carol, Dan):

1. Go to the login page
2. Enter their email + password (`Test1234!`)
3. Confirm you land on the dashboard
4. Confirm the sidebar shows what you'd expect for their role:
   - **Sam** sees Customers, Quotes, Sales Orders, Backlog
   - **Eddie** sees Parts, Quality, Inventory
   - **Olivia** sees Vendors, POs, Invoices, Payments, Customer Returns
   - **Mike** sees everything Bob/Carol see plus admin-ish things
   - **Bob, Carol, Dan** see a stripped-down sidebar (Kanban, Time
     Tracking, maybe Inventory)
5. Sign out

You don't have to fully log in as each one — just confirm the door
opens. The actual role workflows happen in later arcs.

---

## What you should see by the end

- [ ] Jill Admin can sign in and access /admin/*
- [ ] Seven other accounts exist (Sam, Eddie, Olivia, Mike, Bob, Carol, Dan)
- [ ] Each has their assigned role
- [ ] Bob, Carol, Dan, Mike, and Eddie have PINs set
- [ ] Four storage bins exist (A-1, A-2, A-3, B-1)
- [ ] Job stages, track types, and priorities are not empty
- [ ] Each test user can sign in with `Test1234!` and see role-appropriate sidebar

---

## What might be wrong (flag any of these)

- 🔴 **Setup wizard doesn't appear** on first visit → the install isn't
  fresh, or the setup-required guard isn't firing. Try the database
  reset before continuing.
- 🔴 **Address validation rejects everything** → if the wizard requires
  a USPS-validated address but USPS isn't configured, this blocks
  setup. Either configure USPS in `.env` or note that the wizard needs
  a "skip validation" option.
- 🟡 **Creating eight users one at a time is tedious** → bulk-import
  via CSV would be a real productivity win for any new install. Note
  it.
- 🟡 **No "Set PIN" field on the user form** → blocks Step 4. Workers
  can't kiosk-auth without a PIN. The PIN should either be on the
  user create form or have its own dedicated screen.
- 🟢 **Reference data is empty after install** → seed data didn't
  apply. Either the install is missing the seed step or the seed
  failed silently. Big finding.
- 🟢 **No way to create a storage bin** → can't proceed to Arc 7.
  Inventory needs bins to exist before materials can land in them.
- 🟢 **A test user signs in to a sidebar they shouldn't have access to**
  (e.g., Bob sees the Admin link) → role-based UI gating is broken.

---

## Hand-off

Sign out as Jill. **Sam SalesPM picks up Arc 2** — Sam's job is to
create the first customer.
