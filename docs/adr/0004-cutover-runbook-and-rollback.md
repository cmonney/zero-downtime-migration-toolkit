# ADR 0004 — Cutover Runbook and Rollback

**Status:** Accepted

---

## Context

A cutover that depends on senior-engineer judgement on the day is not repeatable and not testable.
If the sequence of actions, the signals that indicate it is safe to advance, and the procedure to
abort and roll back are not written down before the cutover begins, then they will be improvised
under pressure, which is how data loss and extended outages happen.

The strangler-fig pattern with four-phase routing gives a natural structure for a phased runbook:
each phase has observable entry and exit conditions, and the rollback procedure for each phase is
cheaper and more reversible than the rollback for any later phase. Writing the rollback procedure
first for each phase is a forcing function: if the rollback cannot be described clearly, the
forward path is not safe to execute.

---

## Decision

The cutover sequence is documented as an executable checklist in `docs/runbook-cutover.md`. Each
phase has explicit entry criteria, a single concrete action (the feature-flag flip), the observable
signals that confirm the action succeeded, the abort criteria that trigger an immediate rollback,
and a pointer to the rollback procedure. The rollback procedure for each phase is written before the
forward path in the document.

The integration test in `tests/Migration.Cutover.Tests` exercises the same sequence of phase
transitions under continuous synthetic load. The test is the automated analogue of the runbook: if
the test passes, the runbook's forward path has been validated under load. If the test fails, the
runbook must not be executed until the failure is understood.

Phase transitions are implemented as runtime feature-flag changes, not deployments. This means the
strangler API does not need to be restarted to advance or roll back a phase, which removes a source
of uncertainty during a time-pressured cutover.

---

## Consequences

The runbook must be kept in sync with the implementation. A runbook that describes a feature flag
that no longer exists, or an observability signal that is not emitted, is worse than no runbook
because it creates false confidence. The PR checklist in `CONTRIBUTING.md` includes a runbook
review step.

The cutover test provides regression coverage against runbook drift: if the test passes, the phase
transitions work as described. The test does not cover every possible failure mode — network
partitions, SQL Server restarts, disk exhaustion — but it covers the nominal path and the basic
abort path.

---

## Alternatives Considered

**Ad-hoc cutover with senior-engineer judgement on the day.** Requires experienced engineers to be
available, rested, and in agreement about the procedure at the time of cutover. Rejected: not
repeatable, not testable, does not scale beyond the individuals who were present, and concentrates
risk in a small number of people rather than distributing it across documented, tested procedure.

**Fully automated cutover without human checkpoints.** Would advance through all four phases
automatically based on reconciler output, without requiring a human to approve each transition.
Deferred rather than rejected: the automated cutover test already exercises this path, but exposing
it as a production cutover mechanism without human checkpoints would be inappropriate for the first
use of this runbook. A fully automated cutover could be introduced once the runbook has been
executed manually at least once and the team has confidence in the entry criteria.
