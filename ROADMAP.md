# Roadmap

This file distinguishes work that is in scope for the MVP from work that is deliberately deferred.
The distinction is a design decision, not an oversight. Items in Phase 2 are designed — there is a
documented rationale for each in the relevant ADR — but their implementation would complicate the MVP
without adding to its core claim.

---

## MVP — in scope for this repository

- **Messy seed schemas for Source A and Source B.**
  Acceptance criterion: the seeded databases contain at least one deliberate instance of each of the
  eight drift categories defined in ADR 0003, verifiable by running the reconciler against the
  unseeded target.

- **Reconciliation engine with named drift categories.**
  Acceptance criterion: given two databases seeded with the MVP schemas, the reconciler produces a
  structured report identifying every seeded drift instance by category and produces zero false
  positives when run against two identical datasets.

- **Strangler API with four-phase feature-flagged routing.**
  Acceptance criterion: a running instance of the API responds correctly to reads and writes under
  each of the four phases (A through D), with phase transitions toggled at runtime without a service
  restart, evidenced by the integration test suite.

- **Dual-writer with transactional outbox and idempotency keys.**
  Acceptance criterion: a write applied through the dual-writer appears in both the source and
  target databases; a duplicate write (same idempotency key) is applied exactly once to the target,
  evidenced by a unit test with an in-memory outbox and a database integration test.

- **Synthetic load generator.**
  Acceptance criterion: the load generator drives a configurable request rate against the strangler
  API for a configurable duration, records per-request latency and success or failure, and produces
  a summary report consumable by the cutover SLO test.

- **Cutover integration test asserting SLOs.**
  Acceptance criterion: the test drives the load generator against the strangler API throughout a
  full automated cutover sequence (Phase A through Phase D), and asserts: zero failed writes, zero
  data-loss events reported by the reconciler, and p99 latency below the defined threshold at every
  phase boundary.

---

## Phase 2 — deferred but designed

- **Bulk-and-delta cutover pattern.**
  Done when: an alternative cutover strategy is implemented that performs an initial bulk copy of
  source data to the target, followed by a delta-only synchronisation pass, with the strangler API
  switching reads only after the delta pass confirms parity. ADR 0001 documents why this is deferred.

- **Working Bicep deployment to Azure.**
  Done when: `az deployment group create` against a real Azure subscription produces a running
  instance of the full stack (SQL Managed Instance for all three databases, AKS for the strangler
  API and load generator, App Insights wired to the cutover test). ADR 0005 explains the Bicep
  choice.

- **Chaos injection beyond seed-time drift.**
  Done when: the chaos tool can introduce network latency, packet loss, and container restarts
  during a live cutover run, and the cutover SLO test continues to pass within relaxed but still
  defined SLO thresholds.

- **End-to-end observability with Application Insights.**
  Done when: the cutover test publishes structured telemetry to Application Insights, and a
  pre-built workbook in the `infra/` folder shows phase-boundary latency, reconciler diff counts,
  and outbox lag as correlated time series.

---

## Out of scope

- CDC-based migration patterns. Mentioned in ADR 0001 and ADR 0002 to explain why they were not
  chosen; not implemented and not planned.
- Multi-region topologies. Write-conflict resolution in an active-active multi-region setup is a
  different problem class.
- Schema evolution during cutover. The runbook requires a schema freeze during the cutover window.
- Real PII handling. See `LIMITATIONS.md` and `SECURITY.md`.
