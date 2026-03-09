# QB Engineer — Cursor Rules

This file provides AI coding assistants with project context. All detailed rules live in `CLAUDE.md` at the project root.

## Documentation Reference

| File | Purpose |
|------|---------|
| `CLAUDE.md` | **Primary rules file.** Project structure, coding standards, naming conventions, shared component usage guides, SCSS design system, .NET patterns, Angular patterns, security rules, testing conventions. Read this first. |
| `docs/proposal.md` | Original project proposal. Feature specs (§4.1–4.27), phased delivery plan (§8), role definitions, reporting requirements. |
| `docs/architecture.md` | Tech stack decisions, Docker Compose setup, auth flow (JWT + refresh), custom fields design, full-text search plan, mobile strategy, backup architecture, AI module design. |
| `docs/coding-standards.md` | Detailed coding conventions for Angular 21 (signals, standalone, OnPush, control flow) and .NET 9 (MediatR CQRS, FluentValidation, repository pattern, EF Core). |
| `docs/functional-decisions.md` | Business logic decisions: kanban board rules, planning cycles, lead pipeline, expense capture, invoice workflow, time tracking, production traceability, notification system, reporting specs, shop floor display. |
| `docs/qb-integration.md` | QuickBooks Online REST API integration: OAuth 2.0 flow, sync queue design, caching strategy, orphan detection, stage-to-document mapping, provider abstraction. |
| `docs/roles-auth.md` | ASP.NET Identity configuration, 6 additive roles (Engineer, PM, Production Worker, Manager, Office Manager, Admin), permission matrix, worker simplified views, shop floor kiosk mode. |
| `docs/ui-components.md` | UI component specifications, wireframe descriptions, layout rules, interaction patterns, responsive breakpoints. |
| `docs/libraries.md` | Frontend and backend library selections with justification: Angular Material, date-fns, ng2-charts, Three.js, driver.js, QuestPDF, Hangfire, Mapperly, etc. |
| `docs/kickoff-prompt.md` | The original kickoff prompt that generated the project design. Historical context. |
| `docs/implementation-status.md` | Living tracker of implementation progress. Updated after each work session. Shows Done/Partial/Not Started for every spec item. |

## Quick Start

1. Read `CLAUDE.md` — it has all the rules, patterns, and shared component usage guides
2. Check `docs/implementation-status.md` — understand what's built vs remaining
3. Reference `docs/coding-standards.md` for detailed conventions
4. Reference `docs/functional-decisions.md` for business logic context
