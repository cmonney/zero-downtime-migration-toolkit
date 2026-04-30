# ADR 0002 — Dual-Write Coordination Strategy

**Status:** Accepted

---

## Context

During Phase C, writes must reach both the source database and the target database. A write that
succeeds at the source but silently fails at the target produces divergence that the reconciler
will detect — but the divergence is real data loss from the target's perspective, and the reconciler
running behind may not catch it before Phase D begins.

Two failure modes must be prevented: first, a write that appears to succeed to the caller but does
not reach the target; second, a write that is applied twice to the target due to a retry, producing
duplicate records or incorrect aggregate values.

The target is eventually consistent with the source by design — the synchronisation is asynchronous.
The question is how to make the eventual consistency bounded, detectable, and recoverable.

---

## Decision

The dual-writer implements the transactional outbox pattern on the source side. A write command is
applied to the source database and an outbox record is written atomically in the same local
transaction. A background relay process reads the outbox and applies each record to the target using
an idempotent applier keyed on a deterministic message ID derived from the command's content and
sequence position.

The message ID is deterministic: replaying the same source event always produces the same ID, so
the target can detect and discard duplicates using an idempotency table. The relay may apply a
given outbox record more than once (at-least-once delivery); the target will apply it exactly once.

Conflict resolution within the dual-write window uses last-writer-wins, keyed on the source
transaction timestamp. This is defensible because the dual-write window is short and concurrent
conflicting writes on the same record are expected to be rare during a controlled cutover. The
reconciler will detect any case where this assumption is violated.

---

## Consequences

The target is eventually consistent with the source within seconds, not milliseconds. The
reconciler must account for this lag when reporting diffs during Phase C — a diff that disappears
within the expected synchronisation window is not a data-loss event. The cutover test holds at the
Phase C/D boundary for a configurable stabilisation period before running a final reconciliation
pass.

Outbox table growth must be monitored. The relay must commit progress to avoid replaying the
entire outbox after a restart. Both are addressed in the runbook.

The transactional outbox is a well-understood pattern with mature implementations; the dual-writer
does not implement anything novel. Its value in this repository is the integration with the
reconciler and the cutover test, not the outbox mechanism itself.

---

## Alternatives Considered

**Two-phase commit (distributed transaction).** Would make the write to both databases atomic.
Rejected: SQL Server's distributed transaction coordinator is operationally fragile, introduces
latency on every write, and couples the health of the target database to every source write
operation. A single target unavailability event during Phase C would cause writes to fail at the
source — exactly the behaviour the strangler-fig approach is designed to prevent.

**Best-effort dual-write without outbox.** Write to source, then write to target in the same
application transaction scope, catch exceptions on the target write, and log them. Rejected:
produces undetectable divergence. If the target write silently fails — not just an exception but a
connection timeout that succeeds server-side — there is no record of the gap and the reconciler
cannot distinguish intentional divergence from a lost write.

**CDC-based replication.** As noted in ADR 0001, this is deferred rather than rejected. CDC would
eliminate the dual-write path entirely and give the target a replay of every source change. The
complexity of operating a CDC pipeline during a cutover window, combined with the care required
around source schema changes, makes it unsuitable for the MVP. The roadmap records it as a Phase 2
option for higher-volume scenarios.
