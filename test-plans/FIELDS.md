# Field-level lineage

THREADS.md tracks entities through arcs. This doc tracks the **fields**
inside those entities. Every field a downstream arc depends on must
trace back to an arc that explicitly populated it. If a field is
referenced but never set, that's a 🚩 — testers will find an empty
value at the worst moment (an invoice with no tax line, a shipment
with no carrier, a job with no estimated duration).

**Scope:** "fields that matter" — not every column in the database.
Listed are fields that drive downstream behavior or appear on PDFs /
emails / labels customers see.

**Format per entity:**

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| name | Arc N step M | Arcs X, Y, Z | what breaks |

🚩 = lineage gap to flag and fill before that arc runs.

---

## Customer (Acme Corp)

Set in **Arc 2** unless noted.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Name | Arc 2 | Every downstream arc, every PDF, every email | Quote/invoice header is blank |
| Customer code / ID | auto-assigned | Cross-references | (none if auto) |
| Primary contact name | Arc 2 | Quote PDF, invoice PDF, collection emails | Emails go nowhere |
| Primary contact email | Arc 2 | Arc 4 (quote send), Arc 17 (packing slip), Arc 18 (invoice send), Arc 20 (collections) | Send actions silently fail or queue with no recipient |
| Primary contact phone | Arc 2 | Arc 11b (Sam follow-up), Arc 22b (post-return call) | Sam can't reach customer; contact-interaction log shows no number |
| Billing address | Arc 2 | Arc 18 (invoice header) | Invoice has no "Bill to" |
| Shipping address (default ShipTo) | Arc 2 | Arc 17 (packing slip), shipping rate calc | Shipment can't compute rates; falls back to manual |
| Tax-exempt? + exemption ID | 🚩 **not in Arc 2 currently** | Arc 18 (whether to add tax line) | Test invoice will always show tax — if a customer should be tax-exempt and there's no field to mark them, that's a gap. **Decision needed:** add as Arc 2 sub-step, or make Acme a non-exempt customer and accept tax on invoice. |
| Credit terms (e.g., Net 30) | Arc 2 | Arc 18 (invoice due-date computation), Arc 20 (overdue threshold) | Invoice has no due date; collections can't compute "X days late" |
| Credit limit | 🚩 **not in Arc 2 currently** | Arc 5 (SO confirmation should warn if exceeds), Arc 20 (collections workflow) | If feature exists but isn't set, the warning never fires during testing. **Decision needed:** does qb-engineer's customer entity have a credit limit field? If yes, add to Arc 2. If no, note it as a missing feature. |
| Notes / preferences (e.g., "no Saturday delivery") | Arc 2 (optional) | Arc 17 (shipping decisions) | Default behavior; not strictly a gap |
| Customer status (Active/Inactive/Hold) | Arc 2 implicit "Active" | Arc 5 (SO creation should refuse if Hold) | Default Active is fine for happy path |

### Modifications later

| Arc | Field changed |
|---|---|
| 11b | LastContactDate updated when Sam logs his check-in |
| 19 | OutstandingBalance ↓ when payment applied |
| 20 | OutstandingBalance referenced for collections |
| 23 | OutstandingBalance ↓ further from credit memo |

---

## Contact (Acme primary contact)

Set in **Arc 2** alongside the customer.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| First name + Last name | Arc 2 | Salutations on emails, PDFs ("Dear …,") | Generic greeting |
| Email | Arc 2 | All send-to-customer actions | Sends fail |
| Phone | Arc 2 | Sam's follow-up calls (logged as ContactInteraction) | Can't log a phone call without a number on file |
| Role at customer (e.g., "Buyer") | 🚩 **needed for Arc 11b context** | Sam's follow-up "calling Acme's buyer about the order" | Tester won't know which contact to call if there are multiple |
| Receives quote emails? | Arc 2 (toggle?) | Arc 4 quote send | If no toggle, all contacts get all emails (might be fine; might be noise) |

---

## Vendor (Steel Supply Inc., V-001)

Set in **Arc 6**.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Name | Arc 6 | PO header, vendor-side label | Blank PO |
| Primary contact + email | Arc 6 | Arc 6 (PO send) | PO can't be sent |
| Address | Arc 6 | PO PDF | Blank "Ship from" / "Bill to" |
| Payment terms | Arc 6 | Arc 7 (when to expect supplier invoice; out of scope here) | OK to default |
| Lead time (days) | Arc 6 | Future MRP scheduling | If MRP is being tested elsewhere, populated; here OK to default |

---

## Part RAW-001 (raw material)

Set in **Arc 3** by Eddie.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Part number | Arc 3 | Everywhere — BOM, PO line, bin contents, issue scans, cycle count | Critical |
| Description | Arc 3 | PO PDF, packing slip, scan UIs | Workers see "Part #1234" with no name |
| Source type (Buy/Make/Stock) | Arc 3 = Buy | Arc 6 (only Buy parts get POs); Arc 10 (Make parts can't be issued, must be produced) | Wrong type → wrong workflow available |
| Unit of measure (lbs, each, etc.) | Arc 3 = lbs | Every quantity field downstream | If missing, qty entries are ambiguous |
| Standard cost | Arc 3 | Job cost rollup, variance reporting | Downstream cost reporting empty |
| Last purchase price | auto-set in Arc 7 (when received) | Future BOM costing | First-time fine; later runs use this |
| Default vendor | Arc 3 (optional) — Steel Supply Inc. | Arc 6 (vendor pre-fills when ordering this part) | Olivia has to pick the vendor manually each time |
| Reorder point + reorder qty | 🚩 **needed for Arc 6a inventory check** | Arc 6a (shortage detection) | Without these, the "we need to reorder" trigger has no threshold to compare against |
| Default storage location | Arc 3 (optional) — bin A-3 | Arc 8 (put-away pre-fills bin) | Dan picks the bin manually each time |
| Lot-tracked? | Arc 3 | Arc 7 (receiving might capture lot number), traceability | If you're testing lot traceability, this matters; otherwise OK to leave off |

---

## Part ASSY-100 (assembly)

Set in **Arc 3** by Eddie.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Part number, Description, UoM (each) | Arc 3 | All downstream | Critical |
| Source type | Arc 3 = **Make** | Arc 5 (creates a Job instead of a PO line); Arc 9 (kanban) | Wrong type → no production job created |
| Standard cost | Arc 3 (or auto-rolled from BOM) | Quote pricing default in Arc 4 | If blank, Sam quotes a guess |
| Quote price / list price | 🚩 **need to confirm field exists** — the Quote line in Arc 4 has a unit price entered manually (default from list price?) | Arc 4 (quote line price) | If no list price, Sam types from scratch every time |
| BOM (link to RAW-001 with qty) | Arc 3 | Arc 6a (shortage detection), Arc 10 (issue suggestion), Arc 17 (cost rollup) | Without BOM, system has no idea what materials this needs |
| BOM line: RAW-001 qty per ASSY-100 | Arc 3 = 1.2 lbs | Arc 6a (60 lbs needed for 50 brackets), Arc 10 (qty to issue) | Material requirements wrong |
| Routing / operations | Arc 3 sub-step | Arc 9 → 11 (which kanban stages this part flows through), Arc 12 (which inspections apply) | Without routing, kanban has no stages to advance through |
| Operation 1: Cut, est. 5 min | Arc 3 | Job duration estimate, Bob's expected time-on-task in Arc 9 | Without estimate, no variance reporting |
| Operation 2: Drill, est. 10 min | Arc 3 | Same | Same |
| Operation 3: Inspect, est. 3 min | Arc 3 | Eddie's QC step in Arc 12 | Same |
| Operation 4: Pack, est. 2 min | Arc 3 | Final stage before B-1 | Same |
| QC template / inspection points | Arc 3 (optional) | Arc 12 (inspection form auto-loads) | Eddie does freehand inspection — fine for v1, mention as gap |

---

## Quote Q-001

Set in **Arc 4** by Sam.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Customer link | Arc 4 = Acme | Arc 5 (SO inherits) | Can't convert to SO |
| Type | Arc 4 = "Quote" (vs Estimate) | Arc 5 (only Quotes convert to SOs) | Wrong type, can't proceed |
| Line: ASSY-100 × 50 | Arc 4 | Arc 5 (SO line), Arc 9 (job qty) | No work to do |
| Unit price ($40) | Arc 4 (manual, or default from ASSY-100 list price) | Arc 4 total, Arc 18 invoice pricing | Invoice has $0 lines |
| Sub-total / Tax / Total | Arc 4 (computed) | Arc 18 (invoice computes from same recipe) | Customer sees mismatch between quote and invoice |
| Quote validity end date | Arc 4 | Quote expiration logic (out of scope here) | OK to default (e.g., 30 days) |
| Status (Draft → Sent → Accepted) | Arc 4 (transitions) | Arc 5 (only Accepted quotes can become SOs) | Conversion blocked if not accepted |
| Customer PO number (their reference) | Arc 4 (optional) | Arc 18 invoice (their PO# appears on the invoice) | Invoice missing customer's PO# — they may reject it |

---

## Sales Order SO-001

Set in **Arc 5** by Sam.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Customer link | inherited from Q-001 | Everywhere | Critical |
| Quote link (source) | Arc 5 | Audit trail, customer-side history | Self-traceability lost |
| Line: ASSY-100 × 50, $40/ea | inherited | Arc 5b (job qty), Arc 18 (invoice line) | Job + invoice would be empty |
| Requested ship date | Arc 5 (Sam enters) | Arc 5b (Mike uses to prioritize), MRP scheduling | No urgency signal — Mike doesn't know when this needs to be done |
| Ship-to address (override?) | Arc 5 (defaults to Acme's primary) | Arc 17 (shipment uses) | Wrong address |
| Status | Arc 5 = Confirmed | Arc 5b (only Confirmed get released to floor) | Job not eligible for release |

---

## Job J-1001

Created in **Arc 5** (auto-spawned from SO line).

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Job number | auto | Cross-references everywhere | Critical |
| Linked SO line | auto in Arc 5 | Arc 18 (invoice billing), audit | Self-traceability |
| Part being made (ASSY-100) | inherited | Routing → kanban stages, BOM → material requirements | No work plan |
| Quantity (50) | inherited | Time estimates, material qty, finished count | Wrong qty everywhere |
| Track type (Production) | Arc 5 (defaults from part?) | Determines kanban board it appears on | Job lands on the wrong board |
| Initial stage | Arc 5 = "Backlog" | Arc 5b transitions to "Materials Ordered" | Stays in Backlog forever |
| Assignee | 🚩 **set in Arc 5b** = Bob | Arc 9 (Bob sees it in his "my jobs"), Arc 13 notification routing | If never assigned, no one is notified, no one sees it on their kiosk |
| Priority | Arc 5 (defaults Medium) or Arc 5b (Mike sets) | Kanban sort order, alerts | Always-Medium dilutes signal |
| Estimated start / end | computed from operations | Schedule, on-time-delivery KPI | KPI dashboard always Green |
| Estimated material cost / labor cost | computed from BOM + ops | Arc 18 cost-of-job, margin reporting | Margin always 100% |
| Hold? + Hold reason | Arc 13 (set when Bob escalates) → Arc 13 (cleared by Mike) | Kanban indicator, blocks stage advance | Hold flow can't be tested if no field exists for hold reason |

---

## Purchase Order PO-001

Set in **Arc 6** by Olivia.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Vendor link | Arc 6 = V-001 | PO PDF header, Arc 7 (Dan validates against expected PO) | Dan can't tell who shipped this |
| Linked SO/Job (the demand source) | Arc 6 (when created from shortage) | Arc 7 (auto-allocate received material to that job) | Material received but not auto-tied to J-1001 |
| Line: RAW-001 × 100 lbs @ $X/lb | Arc 6 | Arc 7 (received qty validation), supplier invoice matching | Receiving has no expected qty |
| Expected delivery date | Arc 6 | Arc 5b prioritization, MRP | OK to default |
| Status (Draft → Sent → Receiving → Closed) | Arc 6 → 7 → 8 | Vendor scorecard, late-PO alerts | Status never advances → reports broken |

---

## Receiving / Bin Movement

Set in **Arc 7** + **Arc 8** by Dan.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| PO link | Arc 7 (Dan scans PO barcode) | Reconciliation against PO line | If no link, "free-floating" inventory |
| Part received | Arc 7 = RAW-001 | Bin contents | Wrong inventory updates |
| Qty received | Arc 7 (Dan enters/scans) | PO line "received qty" updates; auto-Close at full | Manual reconciliation required |
| Lot number | Arc 7 (if part is lot-tracked, set in Part config) | Traceability | No lot-level history |
| Receiving inspection? Pass/Fail | Arc 7 (optional) | Reject path | Default Pass — fine if not testing rejection |
| Bin destination | Arc 8 = A-3 | Updates bin_contents | Material is "received" but ghost (not in any bin) |
| Receipt timestamp | auto Arc 7 | Audit, FIFO | Auto OK |
| Receiving worker | auto Arc 7 = Dan | Audit, productivity reporting | Auto OK |

---

## Bin Contents (A-3 specifically)

Updated continuously, never "created" as a record per se — bin
contents are a function of all the movements in/out.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Part | implicit from movements | Issue scans, cycle count | — |
| Qty on hand | computed from movements | Cycle count expected, MRP available-to-promise | If movement records are missing, qty is wrong |
| Lot (if tracked) | Arc 7 | Traceability | — |

---

## Time Entry (Bob's first one)

Set in **Arc 9** when Bob starts the timer.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Worker | Arc 9 = Bob | Productivity reports, payroll feed | Critical |
| Job | Arc 9 = J-1001 | Job cost rollup | Cost not assigned to job |
| Operation (Cut/Drill/Inspect/Pack) | 🚩 **does the timer ask which operation?** Need to verify in the UI. | Operation-level cost analysis | If just "time on job" with no op breakdown, less granular reporting |
| Start time | Arc 9 = clock-in moment | Duration calc | Critical |
| End time | Arc 9 = stop-timer moment, or auto-on-clock-out | Duration calc | If never set, entry is "open" forever |
| Total duration | computed | Payroll, job cost | — |
| Edit history | Arc 16 (when Mike corrects) | Audit trail | Without history, corrections can't be audited |

---

## Shipment SH-001

Set in **Arc 17** by Olivia (or a Picker).

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Sales Order link | Arc 17 = SO-001 | Arc 18 (invoice references) | Invoice has no source |
| Lines: ASSY-100 × 50 (from B-1) | Arc 17 (pick scan) | Arc 18 invoice line | Invoice line missing |
| Ship-to address | inherited from SO | Carrier label, packing slip | Label has no address |
| Carrier + tracking number | Arc 17 (Olivia enters or selects) | Customer communication, tracking link in invoice email | Customer can't track |
| Ship date | Arc 17 (mark-shipped action sets) | Invoice date, on-time KPI | Date wrong |
| Picked from bin | Arc 17 = B-1 | bin_contents decrement | Inventory not decremented |
| Packing slip PDF generated | Arc 17 | Goes in box, also emailed | Customer doesn't know what's in the box |

---

## Invoice INV-001

Set in **Arc 18** by Olivia.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Customer link | from SH-001 | Header, A/R reports | Invoice has no payer |
| Sales Order link | from SH-001 | Audit trail | Self-traceability |
| Shipment link | Arc 18 | Audit trail | — |
| Line items + prices | Arc 18 (from SH-001 + SO line prices) | Invoice total | Invoice = $0 |
| Subtotal / Tax / Total | computed | A/R balance | Wrong amount due |
| Tax line | computed from Customer.TaxExempt? + ship-to state | Customer payment | If tax-exempt field missing (per Customer 🚩 above), tax always charged |
| Invoice date | Arc 18 = today | Aging clock | Aging reports broken |
| Due date | computed from invoice date + Customer.CreditTerms | Arc 20 collections trigger | Always-overdue or never-overdue |
| Customer PO number | from SO (Sam entered in Arc 4) | Customer's matching | Customer rejects invoice ("which PO?") |
| Status (Draft → Sent → Paid / Overdue) | Arc 18 → 19 / 20 | A/R reports, dashboard | Status never moves |

---

## Payment

Set in **Arc 19** by Olivia.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Invoice link | Arc 19 | Apply to invoice, customer balance | Payment is unallocated |
| Amount | Arc 19 | Invoice balance | Balance never decreases |
| Method (check, ACH, card) | Arc 19 | Books, reconciliation | Audit gap |
| Reference (check #, transaction #) | Arc 19 | Reconciliation | Manual reconciliation required |
| Date received | Arc 19 = today | Cash flow reports, payment-velocity KPI | KPI broken |

---

## Customer Return CR-001

Set in **Arc 21** by Olivia.

| Field | Set in | Consumed by | If missing |
|---|---|---|---|
| Customer link | Arc 21 = Acme | Header | Critical |
| Original Shipment link | Arc 21 = SH-001 | Trace what was returned, validate qty | Can't verify return is legitimate |
| Original Invoice link | Arc 21 = INV-001 | Arc 23 (credit memo references) | Credit memo orphaned |
| Lines: ASSY-100 × 5 | Arc 21 | Receiving validation in Arc 22 | Receiving clerk doesn't know what to expect |
| Reason for return | Arc 21 | Quality reports, vendor scorecard if a sourcing issue | Pattern detection broken |
| RMA number | auto Arc 21 | Customer communication | Customer doesn't know what to write on the box |
| Status (Requested → Awaiting Receipt → Received → Inspected → Closed) | Arc 21–23 transitions | Workflow gating | Can't gate the right actions to the right state |

---

## Cross-cutting fields that show up everywhere

These aren't entity-specific. Every entity has them. Auditing them
once here:

| Field | Default behavior | Validation |
|---|---|---|
| `created_at` / `created_by_user_id` | auto-set on insert | Verify the user is correct in audit trail (Bob's scan = Bob created the entry) |
| `updated_at` / `updated_by_user_id` | auto-set on every save | Same |
| `deleted_at` (soft-delete) | null until deleted | Verify delete actions soft-delete (entity hidden but row still exists) |
| Notifications generated | every status change → notify next person | Per THREADS.md notification table |

---

## Open questions for the user

These are 🚩 fields where I'd guess based on common sense, but should
confirm against the actual entity definitions before writing arcs that
depend on them:

1. **Customer.TaxExempt + exemption ID** — do these fields exist on
   the Customer entity? If yes, add to Arc 2. If no, accept that all
   test invoices will charge tax.
2. **Customer.CreditLimit** — exists? If yes, set in Arc 2 to a value
   that won't trigger during testing (e.g., $1M).
3. **Part.ListPrice / Part.QuotePrice** — exists? Used to default the
   quote line price in Arc 4. If no, Sam types from scratch.
4. **Part.ReorderPoint + ReorderQty** — exists? Used in Arc 6a's
   shortage detection. If no, Olivia eyeballs the inventory.
5. **Time entry → Operation linking** — when Bob starts a timer, can
   he pick which operation (Cut, Drill, etc.) he's about to do, or is
   it just job-level? Affects Arc 9 detail.
6. **Customer PO# on SO/Invoice** — field exists? Many B2B customers
   require their PO# echoed on the invoice or they won't pay.

If any of these fields don't exist, that's a system-level gap — not
just a test plan gap — and the test plan should highlight the
absence as a finding rather than working around it.
