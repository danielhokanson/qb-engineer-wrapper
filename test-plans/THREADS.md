# Threads and gaps

A test plan is only as strong as its weakest handoff. This document
audits the proposed 23-arc plan for two kinds of threads:

- **Character threads** — every cast member should appear, continuously
  enough that a tester gets a real feel for that role's daily
  experience. A character who shows up in one arc and disappears
  hasn't been validated.
- **Data threads** — every entity (Customer, Part, Job, PO, Shipment,
  Invoice, Return…) should be created in one arc, modified in others,
  and reach a terminal state by the end. An entity referenced in arc N
  must be created in some arc < N. A "gap" is any reference that
  doesn't trace back.

Anything flagged 🚩 is a gap that needs a fill — either as a new arc
inserted into the sequence, or as a sub-step added to an existing arc.

---

## Character threads

| Character | Appears in | Active scenes | Coverage |
|---|---|---|---|
| **Jill Admin** | 1, **16b 🚩** | 1 → 2 (after fill) | Was thin — lost after Arc 1. **Filled** with Arc 16b: Bob forgot his PIN, Jill resets it. Validates admin support flow on a real day, not just at install. |
| **Sam SalesPM** | 2, 3*, 4, 5, **11b 🚩**, **22b 🚩** | 4 → 6 (after fill) | Solid in Acts I–II. **Filled** with Arc 11b (Sam checks customer-facing progress mid-production — "where's my order?" call) and 22b (Sam follows up after the return — relationship management). |
| **Eddie Engineer** | 3, 12, 22 | 3 | OK as-is. Eddie's role is design + QC + return-inspection, all covered. |
| **Olivia OfficeManager** | 6, 17, 18, 19, 20, 21, 23 | 7 | Heaviest in Acts IV–V, intentionally. Owns the back-office cycle end to end. |
| **Mike Manager** | **5b 🚩**, 13, 15, 16 | 4 (after fill) | **Filled** with Arc 5b: Mike assigns J-1001 to Bob from the backlog. Currently the plan jumped from "J-1001 is in the backlog" (Arc 5) to "Bob picks up J-1001" (Arc 9) with no arc covering the assignment. |
| **Bob ProductionWorker** | 9, 10, 11, 13, 14, 15, **16b 🚩** | 7 (after fill) | Hero of Act III, well-covered. |
| **Carol ProductionWorker** | 14, **11c 🚩** | 1 → 2 (after fill) | Was thin — only appeared as Bob's shift-change partner. **Filled** with Arc 11c: Carol runs a parallel small job (J-1002 setup before Arc 14) so the multi-shift handoff isn't her first appearance. |
| **Dan ReceivingWorker** | 7, 8, 22 | 3 | OK as-is. Inbound receiving + return receiving. |

\* Sam appears alongside Eddie in Arc 3 only as a check-in observer (Sam wants to see what parts Eddie set up so quoting is accurate). Not a "lead character" appearance.

### Gaps closed

- 🚩 **Jill missing after Arc 1** → Arc 16b (PIN reset)
- 🚩 **Mike never assigns work** → Arc 5b (assigns J-1001 to Bob)
- 🚩 **Sam vanishes after the SO is created** → Arcs 11b + 22b (in-flight follow-up + post-return courtesy)
- 🚩 **Carol's only appearance is mid-handoff** → Arc 11c (Carol runs J-1002 standalone first)

---

## Data threads

Each entity below is traced from its first appearance to its terminal
state. A gap is highlighted when an arc *uses* an entity in a state
that no prior arc *put it in*.

### Acme Corp (Customer)

| Arc | What happens |
|---|---|
| 2 | Sam creates Customer "Acme Corp" + first Contact + ShipTo address |
| 4 | Quote Q-001 attached to Acme |
| 5 | Sales Order SO-001 attached to Acme |
| 11b 🆕 | Sam opens Acme detail to check order status (read-only check) |
| 17–19 | Shipment, Invoice, Payment all linked to Acme |
| 21–23 | Return, credit memo all against Acme |

✅ Continuous from creation through every downstream artifact.

### Customer Contact (at Acme)

| Arc | What happens |
|---|---|
| 2 | Created alongside Acme |
| 4 | Quote sent to this contact's email (verify "Send" actually emails) |
| 17 | Packing slip emailed to this contact |
| 18 | Invoice emailed to this contact |
| 20 | Collections reminder sent to this contact |
| 21 | Return request comes in from this contact |

✅ Used everywhere; explicit creation in Arc 2.

### RAW-001 (raw material — steel)

| Arc | What happens |
|---|---|
| 3 | Eddie creates Part RAW-001 (Buy, Active) |
| 3 | Listed as a BOM line on ASSY-100 |
| 6 | Olivia adds RAW-001 to PO-001 (60 lbs needed for 50 brackets + safety stock) |
| 7 | Dan receives 100 lbs of RAW-001 against PO-001 |
| 8 | Dan puts 100 lbs into bin A-3 |
| 10 | Bob issues 60 lbs from A-3 to J-1001 (40 lbs remaining) |
| 11c 🆕 | Carol issues another 20 lbs to J-1002 (20 lbs remaining) |
| 15 | Cycle count finds 18 lbs in A-3 (2-lb shrinkage flagged) |

🚩 **Gap (now closed):** Without Arc 11c, only Bob's 60-lb issue
existed; the cycle-count variance in Arc 15 needed *another*
issuance to be a meaningful test (otherwise the cycle count is just
"do you remember what was in the bin?"). Arc 11c provides the second
issuance.

### ASSY-100 (assembly — Acme bracket)

| Arc | What happens |
|---|---|
| 3 | Eddie creates ASSY-100 (Make, Active) with BOM linking to RAW-001 |
| 3 | Eddie defines routing/operations on ASSY-100 (Cut, Drill, Inspect, Pack) |
| 4 | Quoted at $40 each × 50 |
| 5 | Sold via SO-001; J-1001 = "make 50 of ASSY-100" |
| 9–14 | J-1001 produces ASSY-100 inventory in B-1 |
| 17 | 50 ASSY-100 picked from B-1 for shipment |
| 21 | 5 ASSY-100 returned by Acme |

🚩 **Gap (now closed):** Earlier draft of Arc 3 said "creates first
parts (raw + assembly)" without explicit routing/operations step.
ASSY-100 needs operations defined or there's nothing for the kanban
stages to map to. **Arc 3 now has an explicit "Eddie defines
operations" sub-step.**

### J-1001 (production job)

| Arc | What happens |
|---|---|
| 5 | Created from SO-001 line, lands in **Backlog** |
| 5b 🆕 | Mike pulls J-1001 from backlog, assigns to Bob, releases to floor (stage = Materials Ordered) |
| 7 | Materials received against the job's PO; stage auto-advances or Olivia advances it |
| 8 | Materials staged; J-1001 stage = Materials Received |
| 9 | Bob starts timer; stage advances to In Production |
| 10 | Material issue posts against J-1001 |
| 11 | Bob completes operation; stage = QC |
| 12 | Eddie passes inspection; stage = Ready to Ship |
| 13 | Bob hits a problem (during Arc 11 or 14) — Hold placed → lifted by Mike |
| 17 | Stage = Shipped |
| 18 | Stage = Invoiced |
| 19 | Stage = Payment Received (terminal) |

🚩 **Gap (now closed):** Original plan jumped from "J-1001 in Backlog
(Arc 5)" to "Bob picks up J-1001 (Arc 9)" with no arc covering
**assignment** or **release to floor**. **Arc 5b** fills this.

### J-1002 (second production job)

| Arc | What happens |
|---|---|
| 11c 🆕 | Mike releases J-1002 (smaller side run for Acme, also ASSY-100) and assigns to Carol |
| 14 | Carol works first shift, Bob works second shift, multi-shift handoff |
| 17 | Bundled into SH-001 alongside J-1001's output (or separate, if multi-shipment) |

✅ J-1002 introduced via 11c (which now also gives Carol her standalone scene), used in 14 + 17.

### Vendor "Steel Supply Inc." (V-001)

| Arc | What happens |
|---|---|
| 6 | Olivia creates the vendor + adds RAW-001 to their catalog |
| 6 | PO-001 issued to this vendor |
| 7 | Receiving against vendor |
| (later) | No further arcs touch the vendor in this plan |

✅ Self-contained in Acts I–II. (A vendor scorecard / vendor
performance arc would extend this thread but is out of scope for
this plan.)

### PO-001 (purchase order)

| Arc | What happens |
|---|---|
| 6a 🆕 | Olivia runs a stock-vs-BOM check; identifies that RAW-001 is short by 60 lbs for J-1001 |
| 6 | Olivia creates PO-001 with that line item, sends to vendor |
| 7 | Dan receives the PO; PO transitions to Receiving |
| 8 | All lines fully received; PO transitions to Closed (terminal) |

🚩 **Gap (now closed):** Original plan jumped to "Olivia creates a
PO" with no motivation. Real life: someone or something says "we
need to buy this." **Arc 6a** is the explicit shortage-check step
that triggers the PO. Could be a manual inventory check or an MRP
suggestion. Validates whichever exists.

### Bin A-3 (raw materials shelf 3)

| Arc | What happens |
|---|---|
| 1 | Jill creates the bin (empty) |
| 8 | Dan puts 100 lbs of RAW-001 here |
| 10 | Bob issues 60 lbs out → 40 lbs remaining |
| 11c 🆕 | Carol issues 20 lbs out → 20 lbs remaining |
| 15 | Cycle count: actual = 18 lbs, expected = 20 lbs, 2-lb shrinkage |
| 16 | Mike approves the variance; bin now correctly shows 18 lbs |

✅ Continuous lineage; cycle-count variance has real arithmetic to
validate against, not handwaving.

### Bin B-1 (finished goods)

| Arc | What happens |
|---|---|
| 1 | Jill creates the bin (empty) |
| 11 | Bob completes operation, 50 brackets land in B-1 |
| 11c/14 🆕 | Additional brackets from J-1002 land in B-1 (whatever the second job's qty is) |
| 17 | Olivia/picker scans B-1 → removes 50 (or 50+N) brackets for SH-001 |

✅ Two-source feed (J-1001 + J-1002), one-pull drain.

### SH-001 (shipment)

| Arc | What happens |
|---|---|
| 17 | Olivia creates Shipment from completed jobs; pick → pack → mark shipped |
| 18 | Invoice references this shipment |
| 21 | Customer Return references this shipment |

✅ Created in 17, downstream referenced in 18 and 21.

### INV-001 (invoice)

| Arc | What happens |
|---|---|
| 18 | Olivia generates from SH-001; sends to customer |
| 19 | Payment applied; status → Paid |
| 20 | (alternative thread) If payment is delayed, status → Overdue, reminder sent |
| 23 | Credit memo CM-001 references this invoice |

🚩 **Was a gap, now noted:** Arc 19 (payment) and Arc 20 (collections)
are *alternative branches* of the same invoice, not sequential. The
test plan walks both: pay first (19), then circle back and run
collections on a *second* invoice (or contrived overdue state). The
README index should make this branching explicit so testers don't
think Arc 20 happens to INV-001 itself.

### CR-001 (Customer Return)

| Arc | What happens |
|---|---|
| 21 | Olivia receives customer's return request, creates CR-001 referencing SH-001 + 5 of the 50 brackets |
| 22 | Dan receives the returned goods at the dock; Eddie inspects and dispositions (e.g., "scrap" or "rework") |
| 22b 🆕 | Sam follows up with the customer to close the loop on the relationship |
| 23 | Olivia issues credit memo CM-001 against INV-001 |

✅ Full thread; closed.

### Notifications (cross-cutting)

Notifications aren't a single entity but every handoff should
produce one. Each arc's verification list should include "the next
person got a notification." Specific checks:

| Producer arc | Recipient | Notification expected |
|---|---|---|
| 4 (Quote sent) | Acme contact (out-of-system) | Email or PDF link |
| 5 (SO confirmed) | Mike (release coordinator) | "New work in backlog" |
| 5b (job assigned) | Bob | "You have a new job: J-1001" |
| 6 (PO sent) | Vendor (out-of-system) | Email |
| 7 (receiving complete) | Olivia | "PO-001 fully received, ready to close" |
| 11 (operation complete) | Eddie (next QC) | "J-1001 ready for inspection" |
| 12 (QC passed) | Olivia (shipping) | "J-1001 ready to ship" |
| 13 (problem) | Mike | "Hold placed on J-1001" |
| 17 (shipped) | Acme contact + Olivia | Tracking + invoice trigger |
| 18 (invoice sent) | Acme contact + accounting (out-of-system) | Invoice |
| 20 (overdue) | Acme contact | Reminder |
| 21 (return requested) | Olivia + Dan + Eddie | "Return inbound" |

🚩 **Gap (proposed verification, not a new arc):** Each of these
notifications is a separate validation point. The arcs as written
should always include a "did the next person get pinged?" checkbox.
This is reflected in updated arc templates.

### Time entries (cross-cutting)

| Arc | What happens |
|---|---|
| 9 | Bob's first entry against J-1001 (~30 min) |
| 10 | Bob's entry continues during issue+work |
| 11 | Bob's entry stops on op complete |
| 14 | Bob + Carol both have entries against J-1002 (multi-shift) |
| 16 | Mike corrects one of Bob's entries (e.g., forgot to clock out) |

✅ Multiple workers, multiple jobs, includes correction flow.

---

## Summary of new arcs / sub-steps added by this audit

| New | Lead | Inserted before / replaces | Purpose |
|---|---|---|---|
| **Arc 5b** | Mike Manager | Between 5 and 6 | Mike assigns J-1001 from backlog to Bob, releases to floor. Closes the J-1001 thread gap. Gives Mike a Manager-y appearance besides "fix problems." |
| **Arc 6a** | Olivia OfficeManager | Inside Arc 6, as opening sub-step | Olivia spots the shortage that motivates PO-001. No more "we just decide to order steel" handwaving. |
| **Arc 11b** | Sam SalesPM | Between 11 and 12 | Sam (the customer-facing PM) checks Acme's order status mid-production — pure read-only validation that the customer-relationship view actually reflects reality. Tests the "self-serve update for the salesperson" surface. |
| **Arc 11c** | Carol ProductionWorker | Between 11b and 12 | Carol releases J-1002 (smaller second run) and runs Cut + Drill operations. Gives Carol a standalone scene before the multi-shift Arc 14 and gives the cycle count in Arc 15 a *second* issuance to detect variance against. |
| **Arc 16b** | Jill Admin (with Bob) | Between 16 and 17 | Bob can't remember his PIN. Jill resets it remotely. Validates the admin support flow under realistic friction (worker locked out, can't kiosk, needs Mike or Jill to bail him out). |
| **Arc 22b** | Sam SalesPM | Between 22 and 23 | After the return, Sam reaches out to Acme to close the relationship loop. Tests the contact-interaction logging (call/email/note). Gives Sam a meaningful Act-V appearance. |

These are inserted into the README's arc index so the numbering stays
linear and the threads stay continuous.

---

## What this audit does NOT cover (and why)

- **Recurring orders / subscriptions** — RecurringOrder feature exists;
  validating it would need Arcs 24+ for "second-order auto-spawned
  from template, runs through its own production cycle." Skipping
  for v1 of this plan.
- **Multi-location inventory transfer** — there's only one
  CompanyLocation in this plan ("Main Plant"). Adding a second to
  test transfers is its own thread.
- **Training mode + new hire onboarding** — separate "Arc 25: Carol's
  first day" type plan focused on the Training scan-context flow.
- **MRP nightly run + auto-PO** — could replace the manual
  shortage-spotting in Arc 6a with the MRP-driven version. Worth
  having both, but skipping for v1.

These are noted in the README's "what's not in here yet" section.
