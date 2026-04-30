# ADR 0001 — Strangler-Fig Over Big-Bang

**Status:** Accepted

---

## Context

Two production source databases serve live traffic. The target is a new consolidated schema designed
from first principles. The available downtime budget is effectively zero: any maintenance window
visible to end users would need to be scheduled, communicated, and approved through a change-advisory
process, and even then a multi-hour outage is not acceptable for the class of systems this migration
models.

The migration must therefore be executed in a way that allows the source systems to remain live
throughout, allows the cutover to be aborted and rolled back at any intermediate point, and allows
the transition to be verified against real traffic before completing.

---

## Decision

The migration uses the strangler-fig pattern with a feature-flagged façade API (the strangler API).
The cutover sequence proceeds through four explicit phases:

- **Phase A:** reads and writes go to the source databases. The target receives no traffic.
- **Phase B:** reads go to the source; the strangler API issues shadow reads against the target and
  records discrepancies. No caller-visible change.
- **Phase C:** writes are applied to the source and synchronised to the target via the dual-writer.
  Reads still go to the source. The reconciler runs continuously.
- **Phase D:** sources become read-only. All traffic goes to the target.

Each phase transition is a feature-flag flip, observable and reversible without a deployment.

---

## Consequences

The cutover window is longer than a big-bang approach: the dual-write phase must run long enough
for reconciliation to confirm parity with high confidence before Phase D is entered. This is a
deliberate trade-off. The phase transitions are boring on the day of cutover, which is the goal.

During Phases C and D, two code paths must be maintained: the source-side path and the target-side
path. This is the fundamental cost of the strangler-fig pattern — additional complexity during the
transition period that is discarded once cutover is complete. The runbooks document the
decommissioning step.

Rollback from any phase prior to D is cheap: flip the flag back. Rollback from Phase D has
data-loss implications if writes have reached the target. This is documented in
`docs/runbook-rollback.md`.

---

## Alternatives Considered

**Big-bang weekend cutover.** Run a final reconciliation against a quiesced source, apply any
remaining delta, flip DNS, restart services. Rejected: requires a maintenance window measured in
hours, carries unacceptable risk, and is not testable under production load without executing it.
The failure mode is a public outage requiring emergency rollback.

**CDC-based replay.** Use SQL Server Change Data Capture to replicate changes from source to target
continuously, with the strangler switching reads once the replica reaches parity. Deferred rather
than rejected: CDC increases operational complexity (requires a running capture process, schema
change care, and additional infrastructure), and is not necessary at the scale this repository
targets. It is documented in the roadmap as a Phase 2 pattern.
