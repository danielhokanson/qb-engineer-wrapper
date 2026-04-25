# Arc Writing Guide

**Audience:** the human writing the remaining test-plan arcs.

This is everything I (the previous AI session) gathered about the
unwritten arcs but didn't get around to drafting. Use it as the spec
sheet for each arc so you don't have to re-derive context per arc.

When this folder migrates to `qb-engineer-test`, this file goes with
it (the underscore prefix sorts it to the top).

---

## What's already written

| File | Status |
|---|---|
| `README.md` | ✅ — arc index, severity legend, reset strategies |
| `00-cast-and-setup.md` | ✅ — characters, credentials, PINs, canonical entity IDs |
| `01-bootstrap.md` | ✅ — Arc 1 (Jill admin setup) |
| `09-bob-first-day.md` | ✅ — Arc 9 (Bob clocks in, picks up job, starts timer). **Use this as the format template.** |
| `THREADS.md` | ✅ — character + entity threads (which arcs touch which entities) |
| `FIELDS.md` | ✅ — field-level lineage per entity |
| Everything else | ❌ — 23 arcs to write (this guide is for those) |

## The arc format

Open `09-bob-first-day.md` and use it as the template. Sections, in order:

1. **Title** — `# Arc N — <short title>`
2. **Story-so-far block** (blockquote) — who you are, what's true before
   you start, what needs to be in the system, who you hand off to, est.
   time
3. **Why you're doing this** — one paragraph; the validation goal, not
   the steps
4. **The walkthrough** — numbered steps grouped under `### Step N — …`
   subheaders. Each step is a few sentences plus what should happen.
5. **What you should see by the end** — checklist of post-conditions
6. **What might be wrong (flag any of these)** — bulleted findings
   under category subheaders, each prefixed with 🔴 / 🟡 / 🟢
7. **Hand-off** — one sentence telling the tester what to do next
   (sign out, switch character, open Arc N+1)

Severity legend: 🔴 Broken, 🟡 Awkward, 🟢 Missing.

---

## Cross-cutting reference

### Cast (creds set in Arc 1)

All passwords: `Test1234!`. Email pattern: `<first>@test.local`.

| Character | Email | PIN | Role |
|---|---|---|---|
| Jill Admin | jill@test.local | — | Admin |
| Sam SalesPM | sam@test.local | — | PM |
| Eddie Engineer | eddie@test.local | 9002 | Engineer |
| Olivia OfficeManager | olivia@test.local | — | Office Manager |
| Mike Manager | mike@test.local | 9001 | Manager |
| Bob ProductionWorker | bob@test.local | 1001 | Production Worker |
| Carol ProductionWorker | carol@test.local | 1002 | Production Worker |
| Dan ReceivingWorker | dan@test.local | 1003 | Production Worker (receiving) |

### Canonical entity IDs (as referenced in arcs)

These are the IDs the arcs use for narrative continuity. The app
actually generates `J-1`, `QT-00001`, `SO-00001`, etc., but we keep the
narrative IDs for readability. See the original 00-cast-and-setup
table for the user-decided canon.

- Customer: "Acme Corp" (Arc 2)
- Vendor: "Steel Supply Inc." (Arc 6)
- Parts: RAW-001 (steel), ASSY-100 (bracket) (Arc 3)
- Bins: A-1, A-2, A-3 raw, B-1 finished (Arc 1)
- Quote: Q-001 (Arc 4)
- SO: SO-001 (Arc 5)
- Jobs: J-1001 (Arc 5), J-1002 (Arc 11c)
- PO: PO-001 (Arc 6)
- Shipment: SH-001 (Arc 17)
- Invoice: INV-001 (Arc 18)
- Customer Return: CR-001 (Arc 21)
- Credit Memo: CM-001 (Arc 23) — flag as 🟢 Missing if entity not built

### Cross-cutting "what might be wrong" hints to reuse

These show up in many arcs — keep them in mind:
- **Notification didn't fire** to the next person in the handoff chain
  (THREADS.md has the canonical notification table by arc)
- **Field that should auto-populate didn't** (e.g., customer pre-fills
  on quote, ship-to defaults from customer's primary address)
- **Save button stays enabled with required field empty**
- **Page title doesn't update** when a name changes
- **Mobile/responsive layout broken** at < 768px

---

## Per-arc specs

Per-arc format used below:

> **Lead** — character driving this arc
> **Pre-conditions** — what must be true from earlier arcs
> **Goal** — what gets created/changed
> **UI surfaces** — pages/dialogs touched
> **Steps (sketch)** — ordered, brief; flesh out into 3-7 numbered steps in the arc file
> **Verification** — checklist for "what you should see by the end"
> **Wrong-flags** — arc-specific findings to watch for (in addition to the cross-cutting ones)
> **Notes** — gotchas, things to verify against the running app

---

## Act I — Setup and the first order

### Arc 2 — First customer (`02-first-customer.md`)

> **Lead:** Sam SalesPM
> **Pre-conditions:** Arc 1 done; Sam can log in; reference data (states, payment terms, address types) loaded
> **Goal:** Customer "Acme Corp" + first Contact + at least one Address
> **UI surfaces:** `/customers` (list) → "New Customer" button → CustomerCreateDialog → after save, redirect to `/customers/:id/overview`
> **Steps (sketch):**
>   1. Open Customers, click "New Customer"
>   2. Fill: Name "Acme Corp", IsTaxExempt off, Credit Limit $1,000,000, Credit Terms Net30
>   3. Save → land on customer detail
>   4. Open Contacts tab → "New Contact" → fill name + email + phone + role "Buyer"
>   5. Open Addresses tab → "New Address" → Bill-to + Ship-to (single address marked both)
> **Verification:**
>   - Customer appears in list
>   - Detail page shows name, contact, address, $0 outstanding balance
>   - Stats bar reads: 0 estimates, 0 quotes, 0 orders, 0 jobs, 0 invoices
> **Wrong-flags:**
>   - 🟡 Form requires fields not in `FIELDS.md` Customer table → over-validation
>   - 🟢 No checkbox for IsTaxExempt → field exists server-side per migration but UI may not surface it
>   - 🟡 Address-form state dropdown missing or wrong order
>   - 🔴 Tax exemption toggle requires cert # but doesn't say so
> **Notes:** Server fields IsTaxExempt + TaxExemptionId added in `Add_TaxExempt_And_InvoiceCustomerPO` migration — UI may not yet render them, that's a finding not a bug.

### Arc 3 — First parts (`03-first-parts.md`)

> **Lead:** Eddie Engineer (Sam observes)
> **Pre-conditions:** Arc 2 done (customer exists for context, though parts aren't customer-scoped)
> **Goal:** Two parts (RAW-001 raw material, ASSY-100 assembly) with BOM linking ASSY → RAW, plus routing/operations on ASSY-100
> **UI surfaces:** `/parts` → "New Part" → PartCreateDialog → PartDetailDialog (BOM tab, Operations tab)
> **Steps (sketch):**
>   1. Eddie creates RAW-001: type Buy, status Active, UoM lbs, standard cost $X, reorder point + reorder qty set
>   2. Eddie creates ASSY-100: type Make, status Active, UoM each, standard cost (or auto-rolled)
>   3. Open ASSY-100 → BOM tab → add RAW-001 with qty 1.2 (lbs per bracket)
>   4. Open ASSY-100 → Operations tab → add 4 operations: Cut (5min), Drill (10min), Inspect (3min), Pack (2min). Assign work centers if available.
>   5. (Optional) Sam pops in to check: opens ASSY-100 to verify pricing context for upcoming quote
> **Verification:**
>   - Both parts appear in catalog
>   - ASSY-100 BOM shows 1.2 lbs RAW-001
>   - ASSY-100 routing shows 4 operations with estimated minutes
>   - Eddie's user shows in part's "created by"
> **Wrong-flags:**
>   - 🟡 Reorder point + qty fields missing from create form (server-side they exist; UI may not surface)
>   - 🟢 No way to assign work centers to operations → Mike won't be able to release work properly later
>   - 🔴 BOM line accepts a Make part as a child → should only allow Buy or Stock
>   - 🟡 Operations don't auto-number sequentially
> **Notes:** This is the foundation arc for everything Acts II–IV. If parts aren't right, every downstream arc compounds the problem.

### Arc 4 — Estimate → Quote → accepted (`04-quote.md`)

> **Lead:** Sam SalesPM
> **Pre-conditions:** Arcs 2 + 3 done (customer + parts exist)
> **Goal:** Quote QT-00001 (or canonical Q-001) for 50 brackets, status = Accepted
> **UI surfaces:** Customer detail → Estimates tab (create estimate first), then Quotes tab (convert), or `/quotes` direct
> **Steps (sketch):**
>   1. From Acme detail → Estimates tab → "New Estimate" → estimated amount $2,000 (rough)
>   2. Convert estimate to quote → fills line items: ASSY-100 × 50 × $40 = $2,000
>   3. Set quote validity (30 days), customer PO field if known, notes
>   4. Mark quote as Sent (verify "send" actually emails the contact's address — this is a real validation point)
>   5. Mark quote as Accepted (simulating customer reply)
> **Verification:**
>   - Estimate exists, status Converted
>   - Quote QT-00001 exists, status Accepted, line total $2,000, tax line based on Acme's IsTaxExempt
>   - Customer detail stats bar updated (1 estimate, 1 quote)
>   - Notification fired to Mike or production planner ("new accepted quote — ready for SO")
> **Wrong-flags:**
>   - 🔴 "Send" button doesn't actually email
>   - 🟡 Quote PDF doesn't include the customer PO field
>   - 🟢 No conversion path estimate → quote
>   - 🟡 Quote line price doesn't auto-fill from part standard cost
> **Notes:** Estimates have NO display number until converted; they're referenced by DB id. Quote first gets QT-00001 on conversion (or on direct create).

### Arc 5 — Sales Order from Quote (`05-sales-order.md`)

> **Lead:** Sam SalesPM
> **Pre-conditions:** Arc 4 done (Quote = Accepted)
> **Goal:** SO-00001 confirmed; Job J-1 spawned automatically into Backlog
> **UI surfaces:** Quote detail → "Convert to SO" action → SO appears in `/sales-orders` → confirm action
> **Steps (sketch):**
>   1. Open Q-001, click "Convert to Sales Order"
>   2. Confirm SO inheriting customer + lines + prices
>   3. Set requested ship date (30 days from today)
>   4. Confirm ship-to address (defaults from customer)
>   5. Customer PO field — enter Acme's reference (e.g., "ACME-PO-2026-04")
>   6. Click "Confirm" → SO transitions Draft → Confirmed → triggers OnSalesOrderConfirmed_AutoCreateJobs
>   7. Verify a Job J-1 was auto-created and lives in the Production track Backlog stage
> **Verification:**
>   - SO-00001 exists, Confirmed
>   - Job J-1 exists in Production board's Backlog
>   - Customer PO appears on SO
>   - Notification fired to Mike: "New work in backlog"
> **Wrong-flags:**
>   - 🔴 Job not auto-created on SO confirm → broken event handler
>   - 🟡 Ship-to address doesn't pre-fill from customer
>   - 🟡 Customer PO field missing
>   - 🔴 SO can be confirmed without all required fields → over-permissive
> **Notes:** OnSalesOrderConfirmed_AutoCreateJobs is the handler that creates Jobs. Verify it fired by checking activity log on the SO.

### Arc 5b ⭐ — Mike releases J-1 to the floor (`05b-mike-releases-job.md`)

> **Lead:** Mike Manager
> **Pre-conditions:** Arc 5 done (J-1 in Backlog)
> **Goal:** J-1 assigned to Bob, priority set, stage advanced from Backlog → Materials Ordered, visible on Bob's kiosk queue
> **UI surfaces:** `/backlog` (or `/kanban` Production board) → J-1 detail dialog → assign action, priority dropdown, stage advance
> **Steps (sketch):**
>   1. Mike opens Backlog or Production kanban
>   2. Opens J-1 detail dialog
>   3. Sets assignee = Bob ProductionWorker
>   4. Sets priority = High (or whatever — point is it changes from default)
>   5. Advances stage Backlog → Materials Ordered (or whatever the first post-backlog stage is)
>   6. Saves
> **Verification:**
>   - J-1 has assignee Bob in card and detail
>   - J-1 priority chip shows High
>   - J-1 has moved out of Backlog onto the kanban board
>   - Bob (in another browser tab) sees J-1 on his kiosk queue
>   - Activity log entry: "Mike assigned to Bob"; "Mike advanced stage to Materials Ordered"
>   - Notification to Bob: "You have a new job: J-1"
> **Wrong-flags:**
>   - 🔴 Assignee dropdown empty (no users with worker role visible)
>   - 🔴 Stage advance doesn't fire notification
>   - 🟢 Bob's kiosk doesn't show "my jobs" — has to navigate manually
>   - 🟡 No work-center qualification check (Bob assigned to a job whose ops require a work center he isn't qualified on)
> **Notes:** Work-center qualification was schema-added in `fdac087`; the assignment flow may not yet enforce it. That's a 🟢 finding worth flagging.

---

## Act II — Procurement and receiving

### Arc 6a ⭐ — Olivia spots steel shortage (`06a-shortage-check.md`)

> **Lead:** Olivia OfficeManager
> **Pre-conditions:** Arc 5b done (J-1 needs 60 lbs RAW-001; reorder point set on RAW-001)
> **Goal:** Shortage report identifies RAW-001 short by 60 lbs (none on hand vs. 60 needed)
> **UI surfaces:** `/inventory` → Stock tab or Shortage report; possibly `/auto-po` or MRP
> **Steps (sketch):**
>   1. Olivia opens inventory / shortage view
>   2. Filters or scans for parts below reorder point or with open demand
>   3. Sees RAW-001 flagged: 0 on hand, 60 lbs demand from J-1
>   4. Notes the recommended order qty (whatever reorder qty is set, probably 100 lbs)
> **Verification:**
>   - Shortage view shows RAW-001 with the right numbers
>   - Demand source is traceable to J-1 (clickable link)
> **Wrong-flags:**
>   - 🟢 No shortage view exists
>   - 🟡 Shortage view shows RAW-001 but doesn't link back to J-1 (the demand)
>   - 🔴 Demand calc wrong (e.g., shows 50 lbs not 60 — missed the BOM qty multiplier)
> **Notes:** This arc is a setup for Arc 6 (the actual PO). It validates that there's a real reason to order — not "we just decided to."

### Arc 6 — First vendor + first PO (`06-vendor-and-po.md`)

> **Lead:** Olivia OfficeManager
> **Pre-conditions:** Arc 6a done (Olivia knows what to order)
> **Goal:** Vendor "Steel Supply Inc." created; PO-00001 issued for 100 lbs RAW-001
> **UI surfaces:** `/vendors` → New Vendor → VendorCreateDialog; then `/purchase-orders` → New PO
> **Steps (sketch):**
>   1. Olivia creates vendor: name, primary contact, email, address, payment terms (Net30), lead time (7 days)
>   2. Optionally sets vendor as default vendor for RAW-001 (if that linkage exists)
>   3. Creates new PO → vendor = Steel Supply Inc.
>   4. Adds line: RAW-001 × 100 lbs @ market price
>   5. Sets expected delivery date (today + 7 days)
>   6. Marks PO as Sent (validates "send" actually emails vendor)
> **Verification:**
>   - Vendor in `/vendors` list
>   - PO-00001 status Sent
>   - Linked to Steel Supply Inc., line shows RAW-001 × 100
>   - PO PDF generates with header data filled
>   - Optionally: PO references the demand source (J-1) — if that linkage exists
> **Wrong-flags:**
>   - 🔴 Vendor save button does nothing
>   - 🟡 PO line dropdown for parts doesn't filter to Buy-type parts
>   - 🟡 PO doesn't auto-pre-fill from RAW-001's default vendor
>   - 🟢 PO can't be linked to a job/SO (the demand source)
> **Notes:** RfqService can also generate POs via the RFQ → PO flow. Pick whichever path matches the user's mental model; flag if both exist and confuse the operator.

### Arc 7 — Materials arrive (`07-materials-receive.md`)

> **Lead:** Dan ReceivingWorker
> **Pre-conditions:** Arc 6 done (PO-00001 is Sent / open)
> **Goal:** PO-00001 fully received via scan flow; receiving record created; items in receiving holding area
> **UI surfaces:** `/inventory/receiving` (or shop floor receiving kiosk) → scan PO → enter qty
> **Steps (sketch):**
>   1. Dan opens receiving view
>   2. Scans PO barcode (or types PO number)
>   3. Receiving form opens with PO line: RAW-001 × 100 lbs expected
>   4. Dan scans the part barcode on the inbound material → confirms RAW-001
>   5. Enters qty = 100 lbs (or scans quantity from packing slip)
>   6. Optionally captures lot number (if RAW-001 is lot-tracked)
>   7. Optionally fail/pass receiving inspection
>   8. Saves → receiving record created; PO line "received qty" updates; PO status → Receiving (or Closed if fully received)
> **Verification:**
>   - PO-00001 status = Closed (or Receiving if partial)
>   - ReceivingRecord exists with Dan as receiving worker
>   - RAW-001 inventory now shows 100 lbs in a "receiving holding" or unallocated bin
>   - Notification to Olivia: "PO-00001 fully received"
> **Wrong-flags:**
>   - 🔴 Scanner doesn't pair with the receiving page
>   - 🟡 Has to type PO number from paper — no scan flow
>   - 🔴 Qty over-receive accepted silently (e.g., Dan enters 150 vs expected 100)
>   - 🟢 Lot number capture missing for lot-tracked parts
>   - 🟢 No mismatch warning (scanned part doesn't match PO line)
> **Notes:** First scan flow in the test plan — really validate the hardware path here. Mention paper-based fallback if scanner unavailable.

### Arc 8 — Put materials away in bins (`08-put-away.md`)

> **Lead:** Dan ReceivingWorker
> **Pre-conditions:** Arc 7 done (RAW-001 received but not in a permanent bin)
> **Goal:** 100 lbs RAW-001 in bin A-3
> **UI surfaces:** `/inventory` → Put-away view (or scan-driven bin assignment)
> **Steps (sketch):**
>   1. Dan opens put-away queue → sees 100 lbs RAW-001 awaiting placement
>   2. Scans the bin barcode for A-3
>   3. Scans the material (RAW-001)
>   4. Confirms qty = 100
>   5. Submits → BinMovement record created (Receiving holding → A-3); BinContent for A-3 + RAW-001 created/updated
> **Verification:**
>   - Bin A-3 contents show 100 lbs RAW-001
>   - Receiving holding empty
>   - BinMovement audit shows the transfer
>   - Notification to Bob: "Material ready for J-1" (if that linkage exists)
> **Wrong-flags:**
>   - 🟡 No put-away queue → Dan has to remember what was just received
>   - 🔴 Bin barcode scan doesn't recognize A-3 (bin scan barcodes not generated)
>   - 🔴 Allows put-away to a bin not configured for raw materials
>   - 🟢 No suggestion of "put it where it usually goes" based on Part.DefaultStorageLocation
> **Notes:** This + Arc 7 are the put-it-in-then-find-it-later validation. If the scan flow is awkward here, it's awkward everywhere.

---

## Act III — The shop floor (the heart of the validation)

### Arc 10 — Issue material to job (`10-issue-material.md`)

> **Lead:** Bob ProductionWorker
> **Pre-conditions:** Arc 9 done (Bob clocked in, J-1 In Production); Arc 8 done (RAW-001 in A-3)
> **Goal:** 60 lbs RAW-001 issued from A-3 to J-1; A-3 now holds 40 lbs
> **UI surfaces:** Kiosk job detail → "Issue Material" action; or scan flow on issue scanner
> **Steps (sketch):**
>   1. Bob, on the kiosk, opens J-1
>   2. Taps "Issue Material" — UI suggests RAW-001 (from BOM) and qty 60 lbs (1.2 lbs × 50 brackets)
>   3. Bob scans bin A-3 to confirm source
>   4. Bob scans RAW-001 to confirm part
>   5. Confirms qty 60 → BinMovement (A-3 → J-1 issued); BinContent for A-3 decremented to 40 lbs
> **Verification:**
>   - A-3 now shows 40 lbs RAW-001
>   - J-1 cost rollup includes the issued material
>   - BinMovement audit shows the issue
>   - Activity log on J-1 captures "Bob issued 60 lbs RAW-001 from A-3"
> **Wrong-flags:**
>   - 🟡 Has to manually type qty 60 — not pre-filled from BOM
>   - 🔴 Allows issuance > available qty (e.g., 200 lbs from a bin with 100)
>   - 🟢 No "issue all required materials" bulk action
>   - 🔴 Job cost doesn't update after issue
> **Notes:** Material issue is one of the highest-friction flows in real shops. If this is awkward, the floor will refuse to use it.

### Arc 11 — Operation complete, advance the job (`11-op-complete.md`)

> **Lead:** Bob ProductionWorker
> **Pre-conditions:** Arc 10 done (material issued; Bob still on timer)
> **Goal:** Bob completes Cut (or current operation), J-1 advances to next stage (probably QC); timer logged
> **UI surfaces:** Kiosk J-1 detail → "Mark Operation Complete" or "Advance Stage"
> **Steps (sketch):**
>   1. Bob taps J-1 on kiosk
>   2. Taps "Mark Operation Complete" (or similar — verify exact label)
>   3. Optionally captures qty produced (50 brackets if all done)
>   4. Confirms — operation marked complete; if final operation, stage advances Production → QC
>   5. Timer auto-stops or prompts Bob to stop manually
> **Verification:**
>   - Operation shows complete with timestamp + Bob as operator
>   - Stage advanced to QC (or whatever's next)
>   - Time entry captured for the duration Bob was timing
>   - If final op: 50 brackets in B-1 (finished goods bin) — depends on whether the system auto-receives output to B-1
>   - Notification to Eddie: "J-1 ready for inspection"
> **Wrong-flags:**
>   - 🟡 Doesn't ask for qty produced — assumes 100% yield
>   - 🟢 No auto-receipt to finished-goods bin → Bob has to manually put away
>   - 🔴 Stage advances even if material wasn't issued (no validation of prereqs)
> **Notes:** Verify what stage advance does to assignee — does Eddie get auto-assigned for QC, or does Mike have to assign?

### Arc 11b ⭐ — Sam peeks at order status (`11b-sam-peeks.md`)

> **Lead:** Sam SalesPM (read-only)
> **Pre-conditions:** Arcs 5–11 done; J-1 is mid-flight
> **Goal:** Confirms the customer-facing detail page reflects production progress in real time
> **UI surfaces:** `/customers/<acme>/overview`, jobs tab, orders tab
> **Steps (sketch):**
>   1. Sam opens Acme detail
>   2. Goes to Orders tab → sees SO-00001 with progress indicator
>   3. Goes to Jobs tab → sees J-1 with current stage (QC, in flight, etc.)
>   4. Verifies the data matches what's on the kanban board (open in another tab as Mike)
> **Verification:**
>   - Customer detail mirrors the operational reality
>   - SO line shows fulfillment progress (e.g., "0 of 50 shipped")
>   - Activity log includes the recent operation events
> **Wrong-flags:**
>   - 🔴 Customer detail stats are stale (require refresh to update)
>   - 🟡 No way for Sam to see "what stage is the job at" without going to kanban
>   - 🟢 No customer-facing portal at all (just internal view)
> **Notes:** Pure read-only validation. If the data doesn't flow cleanly to the customer-facing view, sales loses trust in the system.

### Arc 11c ⭐ — Carol releases J-2 (`11c-carol-releases-j2.md`)

> **Lead:** Carol ProductionWorker (with Mike in supporting role)
> **Pre-conditions:** Earlier arcs done; Mike has authority to release; ASSY-100 still has demand or Carol is making a smaller second run
> **Goal:** J-2 (smaller second run, also ASSY-100) created and Carol runs first ops; 20 more lbs RAW-001 issued
> **UI surfaces:** Backlog → release → Carol's kiosk
> **Steps (sketch):**
>   1. Mike (or Carol if she has authority) creates a smaller second job J-2 for, say, 15 brackets
>   2. Mike releases to Carol; J-2 lands on her kiosk
>   3. Carol clocks in, picks up J-2, starts timer
>   4. Carol issues 18 lbs RAW-001 from A-3 (1.2 × 15 = 18 lbs); A-3 now has 22 lbs
>   5. Carol completes Cut + Drill operations
> **Verification:**
>   - J-2 In Production
>   - Carol has time entries on J-2
>   - A-3 shows 22 lbs RAW-001
> **Wrong-flags:** mostly inherited from Arcs 9–11
> **Notes:** Purpose of this arc is to make Arc 14 (multi-shift) and Arc 15 (cycle count) actually meaningful. Without J-2, the cycle count variance is hard to detect.

### Arc 12 — QC inspection (`12-qc-inspection.md`)

> **Lead:** Eddie Engineer (Bob hands off and back)
> **Pre-conditions:** Arc 11 done (J-1 in QC stage)
> **Goal:** Eddie passes inspection on J-1; J-1 advances to Ready to Ship
> **UI surfaces:** `/quality` → Inspections tab → J-1 (or scan flow on inspection station)
> **Steps (sketch):**
>   1. Eddie opens Quality → inspections queue → sees J-1 awaiting QC
>   2. Opens inspection form (per the QC template on ASSY-100, if defined; otherwise freehand)
>   3. Goes through checklist, marks pass/fail per item
>   4. Submits as Pass overall → J-1 advances QC → Ready to Ship
>   5. Hand-off back to Bob: "your job is past QC, get it to packing"
> **Verification:**
>   - Inspection record exists, linked to J-1, marked Pass, Eddie as inspector
>   - J-1 stage = Ready to Ship
>   - Notification to Olivia: "J-1 ready to ship"
> **Wrong-flags:**
>   - 🟢 No inspection form for ASSY-100 → falls back to freehand notes
>   - 🟡 Inspection can be saved without recording any checks
>   - 🔴 Pass without going through any checks at all
> **Notes:** QC templates are configurable per part; if ASSY-100 didn't get one set in Arc 3, that's worth flagging.

### Arc 13 — Hit a problem, escalate (`13-hold-and-escalate.md`)

> **Lead:** Bob → Mike Manager
> **Pre-conditions:** J-2 (or J-1 mid-Arc-11) running
> **Goal:** Hold placed on a job; Mike approves the hold (or Bob places, Mike lifts); escalation flow exercised
> **UI surfaces:** Kiosk job detail → "Place Hold" action → AddHoldDialog; Mike's notifications/board
> **Steps (sketch):**
>   1. Bob is mid-operation, hits a problem (e.g., material defect, machine down)
>   2. Bob taps "Place Hold" on J-2, picks hold type (Material Defect / Machine Issue / Other), enters notes
>   3. J-2 status changes to Hold; visual indicator on kanban
>   4. Notification to Mike: "Bob placed hold on J-2"
>   5. Mike opens the hold, reviews notes, decides to lift
>   6. Mike lifts hold, optionally with notes; J-2 returns to In Production
> **Verification:**
>   - StatusEntry created for the hold (Category = Hold)
>   - StatusEntry has end timestamp once Mike lifts
>   - Activity log captures place + lift events with both users
>   - J-2 stage stays where it was — hold is orthogonal to stage
> **Wrong-flags:**
>   - 🔴 Worker can lift their own hold (defeats the escalation purpose)
>   - 🟡 Hold types not configurable
>   - 🟢 No way to attach a photo of the defect
> **Notes:** This validates the StatusEntry hold category. The schema commit `fdac087` added WorkCenterId to StatusEntry — verify it's populated when Bob places the hold (he was at a specific work center).

### Arc 14 — Multi-shift handoff on J-2 (`14-multi-shift.md`)

> **Lead:** Bob + Carol
> **Pre-conditions:** J-2 running, Bob currently on it
> **Goal:** J-2 spans two shifts cleanly — Bob clocks out mid-job, Carol clocks in, picks it up, finishes it
> **UI surfaces:** Kiosk for both workers
> **Steps (sketch):**
>   1. Bob is timing on J-2; clocks out for end of shift (Stop Timer + Clock Out)
>   2. J-2 timer pauses; J-2 stays in current stage
>   3. Carol clocks in (PIN 1002 on kiosk)
>   4. Carol opens her kiosk → sees J-2 in "in flight, no current operator" state (or in her queue if Mike re-assigned)
>   5. Carol picks up J-2, starts her own timer
>   6. Carol completes the job
> **Verification:**
>   - Two distinct time entries on J-2: Bob (with end time) and Carol (continuing)
>   - Total job time = sum of both
>   - Activity log shows the handoff cleanly
> **Wrong-flags:**
>   - 🔴 Carol can't see the job because it's still "assigned to Bob"
>   - 🟡 No visual cue that "this job was someone else's earlier"
>   - 🔴 Bob's time entry never closed → bills hours after he went home
> **Notes:** Common shop reality. Validate that one operator's work doesn't lock the job to them.

### Arc 15 — Cycle count + variance (`15-cycle-count.md`)

> **Lead:** Bob → Mike (variance approval)
> **Pre-conditions:** A-3 should have 22 lbs RAW-001 expected (post Arc 11c); cycle count finds 18 lbs (2 lbs shrinkage)
> **Goal:** Cycle count flags variance; Mike approves; A-3 corrected to actual
> **UI surfaces:** `/inventory` → Cycle Count action → CountDialog; Mike's variance approvals queue
> **Steps (sketch):**
>   1. Bob opens cycle count for A-3
>   2. System shows expected qty (22 lbs)
>   3. Bob counts physically, enters actual = 18 lbs
>   4. System flags variance, requires reason (Shrinkage / Damage / Lost / Other)
>   5. Bob picks Shrinkage, submits → variance pending Mike approval
>   6. Mike opens variance, reviews, approves
>   7. A-3 BinContent corrected to 18 lbs
> **Verification:**
>   - BinMovement record for the correction (-4 lbs, reason Shrinkage)
>   - A-3 now 18 lbs
>   - Activity log includes both Bob's count and Mike's approval
> **Wrong-flags:**
>   - 🟢 No variance approval workflow — corrections happen instantly without manager sign-off
>   - 🔴 Variance reason not recorded
>   - 🟡 Bob can approve his own variance
> **Notes:** This is why Arc 11c exists — it ensures there's actual material movement to count against.

### Arc 16 — Manager scan undo / time correction (`16-time-correction.md`)

> **Lead:** Mike Manager
> **Pre-conditions:** Bob has a recent time entry with an obvious error (forgot to clock out → 16-hour shift)
> **Goal:** Mike corrects Bob's missed clock-out with audit trail (TimeCorrectionLog)
> **UI surfaces:** `/admin/time-corrections` (or `/time-tracking` admin view)
> **Steps (sketch):**
>   1. Setup: arrange for Bob to have a time entry with an end time of "tomorrow morning" (clocked in but never out)
>   2. Mike opens time corrections / Bob's timesheet
>   3. Selects the bad entry
>   4. Edits end time to actual end of shift
>   5. Required reason field — enters "Forgot to clock out"
>   6. Saves → TimeCorrectionLog created with original value, new value, reason, Mike as corrector
> **Verification:**
>   - Time entry now has correct duration
>   - TimeCorrectionLog exists, linked to the entry, snapshot of original data preserved
>   - Activity log includes the correction
> **Wrong-flags:**
>   - 🟢 Reason field not required → audit trail useless
>   - 🟡 Original value not snapshotted → can't see what it was before
>   - 🔴 Bob himself can edit his own entry (should be locked to admin/manager)
> **Notes:** TimeCorrectionLog already exists per CLAUDE.md. Verify the snapshot of original value is in the log row.

### Arc 16b ⭐ — Bob forgot his PIN (`16b-pin-reset.md`)

> **Lead:** Jill Admin (with Bob in person)
> **Pre-conditions:** Bob can't kiosk because he forgot his PIN
> **Goal:** Jill resets Bob's PIN; Bob can kiosk again
> **UI surfaces:** `/admin/users` → Bob's profile → "Reset PIN" action
> **Steps (sketch):**
>   1. Bob tells Jill he forgot his PIN
>   2. Jill opens admin → Users → finds Bob
>   3. Clicks "Reset PIN" — generates a new PIN or lets Jill set it
>   4. Tells Bob the new PIN (e.g., still 1001 since the test cast assumes that, or a new one)
>   5. Bob tries the kiosk with the new PIN — works
> **Verification:**
>   - Bob's PinHash field updated server-side
>   - Activity log shows Jill reset Bob's PIN (do NOT log the actual PIN value)
>   - Bob can authenticate at the kiosk
> **Wrong-flags:**
>   - 🔴 New PIN displayed in plaintext on screen and persisted in audit log → security finding
>   - 🟢 No PIN reset UI exists at all
>   - 🟡 PIN reset doesn't email/notify Bob (not always wanted)
> **Notes:** This validates the admin support flow under realistic friction. Common real-world scenario.

---

## Act IV — Closing the order

### Arc 17 — Pick, pack, ship (`17-pick-pack-ship.md`)

> **Lead:** Olivia OfficeManager
> **Pre-conditions:** J-1 + J-2 both at Ready to Ship; finished goods in B-1
> **Goal:** Shipment SH-00001 created with 50 (or 50+15) brackets, marked shipped
> **UI surfaces:** `/shipments` → New Shipment, or Pick Wave flow → /shipping
> **Steps (sketch):**
>   1. Olivia opens shipments queue → sees SO-00001 ready
>   2. Creates Shipment from SO-00001
>   3. Pick: scans B-1 → scans 50 ASSY-100 → confirms qty
>   4. Pack: enters package dimensions/weight, generates packing slip PDF
>   5. Ship: enters carrier + tracking number (manually if no carrier API), marks Shipped
>   6. SH-00001 now Shipped; B-1 decremented; SO line fulfillment updated
> **Verification:**
>   - SH-00001 in Shipped state
>   - B-1 inventory decremented
>   - SO-00001 line shows 50 of 50 shipped
>   - Tracking link in customer notification
>   - J-1 stage advances to Shipped (if linked)
> **Wrong-flags:**
>   - 🔴 Carrier/tracking field free-text only; no validation
>   - 🟡 Packing slip PDF doesn't reflect the actual picked items
>   - 🟢 No "send tracking to customer" action
> **Notes:** Carrier integration is mock-only currently. The "send" actions become real when you wire UPS/FedEx/USPS.

### Arc 18 — Invoice the customer (`18-invoice.md`)

> **Lead:** Olivia OfficeManager
> **Pre-conditions:** SH-00001 Shipped
> **Goal:** Invoice INV-00001 created from shipment, sent to Acme
> **UI surfaces:** `/invoices` → New Invoice from Shipment, or auto-prompt after shipment
> **Steps (sketch):**
>   1. Olivia opens invoices → "Create from Shipment" → picks SH-00001
>   2. Invoice INV-00001 generated with line items, prices from SO, tax calc based on Acme's IsTaxExempt + ship-to state
>   3. Customer PO from SO is propagated to invoice (per the Add_TaxExempt_And_InvoiceCustomerPO migration)
>   4. Due date auto-computed from invoice date + Acme's CreditTerms (Net30)
>   5. Olivia marks Sent; verifies invoice PDF emails to contact
> **Verification:**
>   - INV-00001 in Sent state
>   - Invoice total matches SO line × shipment qty + tax
>   - If Acme IsTaxExempt = false: tax line present
>   - If Acme IsTaxExempt = true: tax line zero/absent
>   - Customer PO appears on invoice
>   - Due date = invoice date + 30
> **Wrong-flags:**
>   - 🔴 Tax line ignores customer's IsTaxExempt flag
>   - 🟡 Customer PO field missing on invoice (server has it, UI may not)
>   - 🔴 Due date doesn't honor credit terms
> **Notes:** This is the ⚡ accounting boundary feature — only available in standalone mode. If they've connected QB, this should be read-only.

### Arc 19 — Receive payment (`19-payment.md`)

> **Lead:** Olivia OfficeManager
> **Pre-conditions:** INV-00001 Sent
> **Goal:** Payment received, applied to INV-00001, invoice marked Paid
> **UI surfaces:** `/payments` → New Payment → PaymentDialog
> **Steps (sketch):**
>   1. Olivia opens payments → "New Payment"
>   2. Selects customer Acme
>   3. Enters amount = invoice total, method (Check), reference (check #)
>   4. Selects which invoice(s) to apply to → INV-00001 full amount
>   5. Saves → PaymentApplication created; INV-00001 status → Paid; Acme outstanding balance → $0
> **Verification:**
>   - PMT-00001 exists, applied to INV-00001
>   - INV-00001 status Paid, balance $0
>   - Acme outstanding balance $0
>   - J-1 stage = Payment Received (terminal)
> **Wrong-flags:**
>   - 🔴 Over-payment accepted silently (no warning, just creates a credit)
>   - 🟡 Can't split a payment across multiple invoices
>   - 🟢 No reconciliation against bank deposit
> **Notes:** Also ⚡ accounting boundary — standalone-mode only.

---

## Act V — Real-world bumps

### Arc 20 — Overdue invoice / collections (`20-collections.md`)

> **Lead:** Olivia OfficeManager
> **Pre-conditions:** Need a contrived overdue invoice (e.g., create a second invoice with backdated invoice date so it's > 30 days old, OR run against a different customer's pre-aged invoice from seed data)
> **Goal:** Reminder sent against overdue invoice; aging report works
> **UI surfaces:** `/reports` → AR Aging report; `/invoices` filtered by Overdue
> **Steps (sketch):**
>   1. Olivia opens AR Aging report → sees the overdue invoice in the 30-60 day bucket
>   2. Opens the invoice
>   3. Triggers "Send Reminder" action → email goes to customer contact
>   4. Activity log captures the reminder send
>   5. Verify subsequent reminders escalate (different template at 60+, 90+ days)
> **Verification:**
>   - Aging report shows correct bucketing
>   - Reminder email actually sent (check the SMTP/log/queue)
>   - Activity log captures sends
> **Wrong-flags:**
>   - 🔴 Aging buckets calculated wrong (off-by-one)
>   - 🟡 Same reminder template at all aging stages
>   - 🟢 No customer statement view (single document showing all open invoices)
> **Notes:** AR aging is implemented as a Report per CLAUDE.md. Validate the pre-built template works.

### Arc 21 — Customer initiates return (`21-return.md`)

> **Lead:** Olivia OfficeManager
> **Pre-conditions:** SH-00001 + INV-00001 exist
> **Goal:** RMA-00001 created against SH-00001 for 5 brackets
> **UI surfaces:** Customer detail → Returns tab → "New Return", or `/customer-returns` → New
> **Steps (sketch):**
>   1. Olivia opens Acme detail → Returns tab → New Return
>   2. Selects original shipment SH-00001 / original invoice INV-00001
>   3. Selects line items: ASSY-100 × 5 (of the 50 originally shipped)
>   4. Enters reason ("damaged in transit") + notes
>   5. Sets expected return date
>   6. Optionally toggles "Create rework job" (would auto-spawn a J-3 if accepted)
>   7. Saves → RMA-00001 in Requested status
>   8. Customer-facing notification with RMA number + return instructions
> **Verification:**
>   - RMA-00001 exists, linked to SH-00001 + INV-00001
>   - Status = Requested
>   - Customer notification sent with RMA #
>   - If rework job toggled: J-3 created in Backlog
> **Wrong-flags:**
>   - 🔴 Allows return qty > shipped qty
>   - 🟡 Original shipment field free-text instead of dropdown
>   - 🟢 No customer-facing return portal — Olivia has to enter manually after a phone call
> **Notes:** RMA prefix is `RMA-`, not `CR-` — the test plan and code use different conventions; either is fine but flag the inconsistency.

### Arc 22 — Return received at dock + inspected (`22-return-receive.md`)

> **Lead:** Dan + Eddie
> **Pre-conditions:** RMA-00001 in Requested status; physical return arrived
> **Goal:** RMA-00001 received at dock by Dan, inspected by Eddie, dispositioned
> **UI surfaces:** Receiving (similar to Arc 7) but in return mode; Quality (similar to Arc 12) for inspection
> **Steps (sketch):**
>   1. Dan opens receiving / returns queue → sees RMA-00001 expected
>   2. Scans RMA → confirms 5 ASSY-100 brackets received
>   3. Marks RMA → Received; goods placed in returns holding bin
>   4. Eddie picks up returns inspection queue → opens RMA-00001
>   5. Inspects each bracket; dispositions: Scrap / Rework / Restock
>   6. Submits disposition → RMA → Inspected; downstream actions kicked off (e.g., Scrap → write-off, Rework → new job, Restock → into B-1)
> **Verification:**
>   - RMA status progresses Requested → Received → Inspected
>   - Activity log captures Dan + Eddie events
>   - Disposition properly drives next step (verify against actual code path)
> **Wrong-flags:**
>   - 🟡 Inspection allows save without disposition
>   - 🟢 No photo capture for the defect
>   - 🔴 Restock disposition doesn't actually return inventory to B-1
> **Notes:** Inspection flow may overlap with Arc 12 — flag if the UX is identical or different.

### Arc 22b ⭐ — Sam follows up post-return (`22b-sam-follow-up.md`)

> **Lead:** Sam SalesPM
> **Pre-conditions:** Arc 22 done (return resolved)
> **Goal:** Sam logs a ContactInteraction (call/email/note) with Acme about the return; relationship loop closed
> **UI surfaces:** Customer detail → Interactions tab → New Interaction
> **Steps (sketch):**
>   1. Sam opens Acme detail → Interactions tab
>   2. Clicks New Interaction → type Call (or Email)
>   3. Selects which contact at Acme he spoke with
>   4. Enters notes about the conversation, references RMA-00001
>   5. Saves → ContactInteraction record persists
> **Verification:**
>   - Interaction shows in Acme's interactions list
>   - Contact-level filter works (interactions tied to specific contact)
>   - Type/date/notes captured
> **Wrong-flags:**
>   - 🟢 No interactions tab on customer detail
>   - 🟡 Free-text "which contact" instead of dropdown
> **Notes:** ContactInteraction is in the schema (per CLAUDE.md feature table). Validate it surfaces in the UI.

### Arc 23 — Credit memo + customer made whole (`23-credit-memo.md`)

> **Lead:** Olivia OfficeManager
> **Pre-conditions:** RMA inspected with disposition = Refund
> **Goal:** Credit memo CM-001 issued against INV-00001; Acme balance $0 (or credit balance if RMA bigger than open balance)
> **UI surfaces:** `/invoices` → New Credit Memo, or RMA-driven action
> **Steps (sketch):**
>   1. Olivia opens RMA-00001 → "Issue Credit Memo" action
>   2. Credit memo form: amount = 5 × $40 = $200, applied to INV-00001
>   3. Saves → CM-001 created; INV-00001 balance reduced by $200; if INV was paid full, customer credit balance now $200
>   4. Customer notification with credit memo PDF
> **Verification:**
>   - CM-001 references INV-00001
>   - Customer balance reflects the credit
>   - Activity log
> **Wrong-flags:**
>   - 🟢 No credit memo entity exists at all → flag as Missing finding (this is mentioned in CLAUDE.md as not-yet-built)
>   - 🟡 Credit memo allowed > original invoice amount
>   - 🔴 Credit memo not linked to an RMA → no audit trail of why
> **Notes:** Per CLAUDE.md, the credit memo entity may not exist yet. If the screen doesn't exist, the entire arc becomes a single 🟢 Missing finding — that's still a valid arc outcome and worth documenting.

---

## After all arcs are written

1. Update `README.md` arc index — strike-through any arcs that turned
   out to be infeasible or rolled into another arc.
2. Update `THREADS.md` — confirm every entity's thread is still
   continuous after writing all arcs.
3. Update `FIELDS.md` — flag any new fields that came up during writing
   that aren't yet in the lineage table.
4. Optional: write a short "running this end-to-end the first time"
   walkthrough as a top-level `EXECUTION_NOTES.md` for testers who
   are running the full 8-hour protocol.
