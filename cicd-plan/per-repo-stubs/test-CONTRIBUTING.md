# Contributing to qb-engineer-test

For project-wide guidelines (branch model, PR conventions), see the
umbrella repo:
**https://github.com/<OWNER>/qb-engineer/blob/main/CONTRIBUTING.md**

This repo holds **manual** test plans for human testers — story-driven
scripts that walk a tester through real user flows. It is **not** an
automated test suite.

## What's here

- `README.md` — orientation for testers (start here)
- `00-cast-and-setup.md` — characters and environment setup
- `01-23` — numbered arcs telling the platform's full lifecycle story
- `THREADS.md` — thread/handoff audit (why arcs are sequenced this way)
- `FIELDS.md` — field-level lineage (which arc populates which field)

## Adding a new arc

1. Pick the next free number (or insert with a `b`/`c` suffix if it
   slots between existing arcs).
2. Use the format from `09-bob-first-day.md` as a template:
   - Cast + scenario header (who you're playing, what's true before
     you start, who you hand off to next)
   - "Why you're doing this" — one paragraph
   - Numbered walkthrough steps
   - "What you should see by the end" checklist
   - "What might be wrong" with 🔴/🟡/🟢 severity hints
   - Hand-off line
3. Update the arc index in `README.md`.
4. Update threads in `THREADS.md` and field lineage in `FIELDS.md` if
   the arc creates or consumes new entities/fields.

## Modifying an existing arc

If a UI change made the test steps stale, update them. PR description
should link the qb-engineer-ui or qb-engineer-server PR that caused
the change.

## CI

Markdown linting + dead-link checking only. Keep the output clean.

## Where to file what

- **Test plan needs updating** → here
- **App bug a test plan exposed** → qb-engineer-ui or qb-engineer-server
