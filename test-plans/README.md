# QB Engineer test plans

A library of **story-driven test scripts** for validating qb-engineer end-to-end
through real human use. Each script ("arc") is a short narrative — *who* you
are, *why* you're doing this, and *what to click*. You play the role of a
specific employee and complete a piece of work that hands off to another
employee in a later arc.

These are **not** automated tests. A human runs them, in order, signing in as
different users along the way. The point is to find missing features,
awkward flows, and broken handoffs that automated tests would never catch.

---

## How to use this folder

1. **Read this whole README once.** It's short.
2. **Read [`00-cast-and-setup.md`](./00-cast-and-setup.md).** It introduces
   the people you'll be playing and tells you how to get the test
   environment ready.
3. **Skim [`THREADS.md`](./THREADS.md) and [`FIELDS.md`](./FIELDS.md)**
   if you want to understand *why* the arcs are sequenced the way they
   are and which fields downstream arcs depend on. Optional for a
   tester just running through; required reading for anyone modifying
   the plan.
4. **Run the arcs in numerical order.** Arc 2 needs the customer Arc 1 set up
   the system to be able to create. Arc 9 needs the materials Arc 7
   delivered. Skipping ahead leaves you stuck.
4. **For each arc**, sign in as the named character, follow the steps, check
   the verification list, then sign out and switch to the next character
   the arc tells you to hand off to.
5. **When something is wrong** — and finding wrong things is the whole point
   — write a quick note in the arc's margin or a separate notes file. The
   bottom of every arc has a "What might be wrong (flag any of these)"
   section with examples of the kind of thing to call out.

One tester running solo, switching between accounts, can do all 23 arcs in
about 6–8 hours of focused time. Multiple testers can split it up by act —
just respect the dependencies in the index below.

---

## The arc index

| # | Arc | Lead character | Hand-off to | What you produce |
|---|---|---|---|---|
| **Act I — Setup and the first order** | | | | |
| 1 | Bootstrap the system | Jill Admin | Sam | Company location, all test users, reference data |
| 2 | First customer | Sam SalesPM | Sam | Customer "Acme Corp" + contact + address |
| 3 | First parts (raw + assembly + routing) | Eddie Engineer | Sam | Part RAW-001 (steel), Part ASSY-100 (bracket) with BOM + operations |
| 4 | Estimate → Quote → accepted | Sam SalesPM | Sam | Quote Q-001 (Accepted) for 50 brackets |
| 5 | Sales Order from Quote | Sam SalesPM | Mike | SO-001 confirmed, Job J-1001 lands in backlog |
| **5b** ⭐ | Mike releases J-1001 to the floor (assigns to Bob, sets priority) | Mike Manager | Olivia | J-1001 assigned + visible on Bob's kiosk queue |
| **Act II — Procurement and receiving** | | | | |
| **6a** ⭐ | Olivia spots the steel shortage that motivates the PO | Olivia OfficeManager | Olivia | Shortage report — 60 lbs RAW-001 needed, none on hand |
| 6 | First vendor + first PO | Olivia OfficeManager | Dan | Vendor V-001, PO PO-001 sent (100 lbs ordered) |
| 7 | Materials arrive (first scans!) | Dan ReceivingWorker | Dan | PO-001 received, items waiting to be put away |
| 8 | Put materials away in bins | Dan ReceivingWorker | Bob | Bin A-3 has 100 lbs of steel |
| **Act III — The shop floor (the heart of the validation)** | | | | |
| 9 | Bob's first hour: clock in, pick up job, start timer | Bob ProductionWorker | Bob | J-1001 In Production, 30 min logged |
| 10 | Issue material to the job | Bob ProductionWorker | Bob | 60 lbs steel issued from A-3 against J-1001 (40 lbs left) |
| 11 | Operation complete, advance the job | Bob ProductionWorker | Sam (peek), Eddie (real) | J-1001 in QC stage |
| **11b** ⭐ | Sam peeks at customer-facing order status (read-only) | Sam SalesPM | Carol | Confirms Acme detail page reflects production progress live |
| **11c** ⭐ | Carol releases J-1002 (smaller second run) and runs first ops | Carol ProductionWorker | Eddie | J-1002 In Production, 20 lbs more steel issued (20 lbs left in A-3) |
| 12 | QC inspection (handoff Bob → Eddie → Bob) | Eddie Engineer | Bob | Inspection passed, J-1001 ready to ship |
| 13 | Hit a problem, escalate to manager | Bob → Mike Manager | Bob | Hold placed on J-1002 and lifted |
| 14 | Multi-shift handoff on J-1002 | Bob + Carol ProductionWorker | Carol | J-1002 spans two shifts cleanly |
| 15 | Cycle count + variance approval | Bob → Mike Manager | Mike | A-3 actual = 18 lbs vs expected = 20 lbs; 2-lb shrinkage flagged |
| 16 | Manager scan undo / time correction | Mike Manager | Jill | Bob's missed clock-out corrected with audit trail |
| **16b** ⭐ | Bob forgot his PIN; Jill resets it | Jill Admin (with Bob present) | Olivia | Bob can kiosk again; admin-support flow validated |
| **Act IV — Closing the order** | | | | |
| 17 | Pick, pack, ship | Olivia OfficeManager | Olivia | Shipment SH-001 (50 + N brackets) marked shipped |
| 18 | Invoice the customer | Olivia OfficeManager | Olivia | Invoice INV-001 sent to Acme |
| 19 | Receive payment, apply to invoice | Olivia OfficeManager | Olivia | INV-001 paid in full |
| **Act V — Real-world bumps** | | | | |
| 20 | Overdue invoice / collections | Olivia OfficeManager | Olivia | Reminder sent against a contrived overdue invoice; aging works |
| 21 | Customer initiates a return (RMA) | Olivia OfficeManager | Dan | CR-001 created against SH-001, 5 brackets coming back |
| 22 | Return received at dock + inspected | Dan + Eddie | Sam | CR-001 received, dispositioned |
| **22b** ⭐ | Sam follows up with Acme post-return | Sam SalesPM | Olivia | ContactInteraction logged; relationship loop closed |
| 23 | Credit memo + customer made whole | Olivia OfficeManager | — | CM-001 issued against INV-001; Acme balance → $0 |

⭐ = arcs added during the thread / field audit (see [`THREADS.md`](./THREADS.md)).

**~80% of the validation value is in Act III.** Acts I, II, and IV exist so
Act III has something real to chew on. Act V exposes the parts of the system
people forget exist (collections, RMAs) and makes sure they actually work.

---

## How to flag a problem

Three categories. Use whichever feels right per finding:

- 🔴 **Broken** — something that should work doesn't. Page errors, blank
  screens, "Save" buttons that do nothing, scans that don't register.
- 🟡 **Awkward** — it works, but it's clearly the wrong shape. Three clicks
  where one would do. A scan flow that requires the user to look up a code
  on paper. A field that's auto-fillable but isn't.
- 🟢 **Missing** — the system has no way to do the thing the script asks for.
  A button you'd expect doesn't exist. A page that should list X is empty.
  A handoff has no notification.

For each finding, capture: which arc, which step, what you saw, what you
expected, screenshot if visual. A simple notes file with one bullet per
finding is enough — fancy templates add friction.

---

## Resetting between runs

Each pass through the test plan leaves the database full of test customers,
jobs, invoices, and the like. Two strategies:

- **Fresh install for each run** — wipe the database via
  `docker compose down -v && ./refresh.sh --recreate-db`, then start at
  Arc 1. Useful for clean before/after comparisons. Takes 5 minutes to
  reset.
- **Cumulative state** — leave everything in place and re-run starting from
  whatever arc you want to revalidate. Useful when you've fixed a bug in
  one area and want to confirm the fix without re-running the full 8-hour
  protocol. Just be aware that customer/job/invoice IDs in the doc
  ("J-1001", "INV-001") may not match — they'll be J-100N for whatever N
  your system is on.

Most useful pattern in practice: full fresh-install run for a release
candidate, then targeted re-runs of affected arcs after each bug-fix
deploy.

---

## What's not in here yet

These arcs cover the **revenue lifecycle** end to end. The following
features have their own surface in qb-engineer but aren't yet covered as
test arcs — they may warrant their own follow-on plan:

- AI Assistant / RAG document Q&A
- Compliance forms (W-4, I-9) employee self-service flow
- Training & LMS modules (taking a course, quiz)
- Dashboard customization & ambient mode
- EDI trading partners
- Scheduled tasks & MRP nightly run
- Detailed reporting / report builder
- Multi-location inventory transfers
- Recurring orders / subscription billing

If a tester finds one of these areas underserved during the main run,
escalate it as a "missing arc" finding and we'll add it.
