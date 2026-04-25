# Cast and setup

The people you'll be playing, and what you need before Arc 1 starts.

---

## Before you start: get the environment ready

You need:

- A running qb-engineer install. URL given to you separately.
- Database in **fresh, empty** state. If it isn't, run
  `docker compose down -v && ./refresh.sh --recreate-db` from the deploy
  host before starting.
- This whole `test-plans/` folder open in a tab (or printed). You'll be
  flipping between arcs.
- A browser that lets you keep multiple sessions open easily — Chrome
  profiles, Firefox containers, or just two different browsers (Chrome
  for Bob, Firefox for Mike). Saves a lot of sign-out/sign-in friction.
- A scratch notes file or a sticky pad to flag findings.

Optional but very useful for Act III:

- A USB barcode scanner OR an NFC reader OR a phone camera that can read
  QR codes. Most arcs have a "you can also click this" fallback if you
  don't have hardware, but the *point* of validating shop floor is to
  use the same hardware the workers will.

---

## The cast

Eight characters. Naming convention is `<First name> <Role>` so you can
always tell from the name what hat you're wearing.

| Character | Role in qb-engineer | Why they exist in the story |
|---|---|---|
| **Jill Admin** | Admin | Sets up the system, creates everyone else, fixes things nobody else can |
| **Sam SalesPM** | PM (Project Manager) | Brings in customers, writes quotes, owns the order until it's in production |
| **Eddie Engineer** | Engineer | Designs parts, defines the BOM, runs QC inspections |
| **Olivia OfficeManager** | Office Manager | Vendors, POs, invoices, payments, collections, returns — the back office |
| **Mike Manager** | Manager | Supervises shop floor, approves variances, fixes bad scans, handles holds |
| **Bob ProductionWorker** | Production Worker | The hero of Act III. Operates the machine, runs the work |
| **Carol ProductionWorker** | Production Worker | Bob's counterpart on the second shift. Picks up where Bob leaves off |
| **Dan ReceivingWorker** | Production Worker (assigned to receiving) | Receives inbound shipments, puts material in bins. Same role as Bob/Carol but works at the dock |

> **Note on Dan's role:** qb-engineer doesn't have a separate "Receiving"
> role — receiving is just one job a Production Worker can do. Dan
> exists as his own character in the cast so the story arcs can clearly
> say "now Dan does this." Under the hood his account has the same role
> as Bob and Carol.

### Login credentials (set during Arc 1)

Pick a single password that's easy to remember and use it for everyone
during testing — `Test1234!` works (8 chars, mixed case, digit, symbol —
satisfies the default policy). Email convention:

| Character | Email |
|---|---|
| Jill Admin | jill@test.local |
| Sam SalesPM | sam@test.local |
| Eddie Engineer | eddie@test.local |
| Olivia OfficeManager | olivia@test.local |
| Mike Manager | mike@test.local |
| Bob ProductionWorker | bob@test.local |
| Carol ProductionWorker | carol@test.local |
| Dan ReceivingWorker | dan@test.local |

### PINs (for shop floor kiosk auth)

The shop floor display uses a 4-digit PIN, separate from the password.
Use distinct PINs so you can tell whose actions are whose in the audit
log:

| Character | PIN |
|---|---|
| Bob ProductionWorker | 1001 |
| Carol ProductionWorker | 1002 |
| Dan ReceivingWorker | 1003 |
| Mike Manager | 9001 |
| Eddie Engineer | 9002 |

(Sam, Olivia, and Jill don't normally touch the kiosk — no PIN needed
unless an arc says otherwise.)

---

## The non-character entities you'll create

These aren't users — they're things in the system. Listed here so you
have the canonical names and IDs to expect as the arcs reference them.

| What | Name / ID | Created in arc |
|---|---|---|
| Company | "Test Manufacturing Co." | 1 |
| Company location | "Main Plant" | 1 |
| Customer | "Acme Corp" | 2 |
| Vendor | "Steel Supply Inc." | 6 |
| Raw material part | RAW-001 — "1/4-inch hot-rolled steel, by the pound" | 3 |
| Assembly part | ASSY-100 — "Acme bracket, 4-hole" | 3 |
| Storage bins | A-1, A-2, A-3 (raw materials), B-1 (finished goods) | 1 |
| First quote | Q-001 (50 brackets) | 4 |
| First sales order | SO-001 | 5 |
| First production job | J-1001 | 5 |
| Second production job | J-1002 (multi-shift) | 14 |
| First PO to vendor | PO-001 | 6 |
| First shipment | SH-001 | 17 |
| First invoice | INV-001 | 18 |
| First customer return | CR-001 | 21 |

If your IDs come out differently because you're on a not-fresh database,
that's fine — the *names* and *types* are what matter, not the numeric
suffixes.

---

## What "doing the test plan" feels like

You'll spend an arc playing one character, then the arc tells you "now
sign out, sign in as so-and-so, open Arc N+1." Each character switch is
a deliberate scene break. By the end you'll have inhabited all eight
roles and watched the same one customer's order go from "we don't know
they exist" to "we shipped, billed, and got paid" — with a small
detour through a return.

The whole point is for the **friction** of switching roles to expose
the system's weak handoffs. If sign-in-as-Mike-then-sign-in-as-Bob
loses something, that's a finding. Note it.
