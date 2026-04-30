# Rollback Runbook

This document covers how to roll back from each cutover phase to the previous one, what data the
rollback may affect, and how to detect divergence after a rollback. It is a companion to
`docs/runbook-cutover.md`. Read this document before starting the cutover.

The key principle: rollback cost increases with each phase. Rollback from Phase B to Phase A is
free and side-effect-free. Rollback from Phase D to Phase C is lossy and requires a reconciliation
procedure to recover.

---

## Rolling back from Phase B to Phase A

**Risk:** None. Shadow reads are side-effect-free.

**Procedure:**

1. Set `CutoverPhase = A`.
2. Confirm the strangler API logs no further shadow-compare activity.
3. Record the reason for rollback and the time.
4. Investigate the shadow-compare failures before re-attempting Phase B.

**Data implications:** None. No data was written to the target during Phase B.

**Detection:** The reconciler was not running during Phase B. No divergence to detect.

---

## Rolling back from Phase C to Phase B

**Risk:** Low. Writes that entered the outbox during Phase C but were not yet applied to the
target will remain in the outbox. The outbox is a durable queue; the records are not lost.

**Procedure:**

1. Set `CutoverPhase = B`.
2. The dual-writer will stop processing new write commands.
3. Allow the outbox relay to drain any in-flight records to the target before stopping it. Check
   outbox lag; wait until it reaches zero or until a timeout of 5 minutes, whichever comes first.
4. Stop the outbox relay.
5. Record the last successfully applied outbox sequence number.
6. Investigate the failure. When ready to re-enter Phase C, restart the relay and set
   `CutoverPhase = C` once the relay has confirmed it will pick up from the recorded sequence
   number.

**Data implications:** None if the relay drains fully before being stopped. If the relay is stopped
while the outbox is non-empty, the un-applied records will be replayed when the relay restarts.
Idempotency keys prevent duplicate application.

**Divergence detection:** Run a reconciler pass after rolling back. Any diffs reported are
expected to be explained by un-applied outbox records. A diff that cannot be traced to an outbox
record is a data integrity concern and must be investigated before re-entering Phase C.

---

## Rolling back from Phase D to Phase C

**Risk:** High. This is the only rollback with a realistic risk of data loss.

Writes that reached the target during Phase D (while the sources were read-only) are not
automatically reflected in the sources. If Phase D ran for any period before rollback, the target
may contain writes that the source does not. Rolling back to Phase C without addressing these writes
means the dual-writer's source-to-target synchronisation will overwrite them with the (older) source
values.

**Procedure:**

1. Set `CutoverPhase = C`. The strangler API immediately routes reads back to the source.
   **Note:** callers who were reading from the target during Phase D may observe a discontinuity
   if the source is behind the target. This is expected and is the cost of the rollback.
2. Set the target to read-write (if it was set to read-only at the application layer).
3. Run an emergency reconciliation pass comparing the target against the source. The reconciler
   report will identify rows that are present in the target but not in the source, or that differ
   between target and source in a direction that indicates a Phase D write was the later event.
4. For each such row, decide whether to preserve the Phase D write by applying it to the source,
   or to accept that the Phase D write will be overwritten by the source value when the dual-writer
   resumes. This decision requires understanding of the specific row's business context.
5. Apply any Phase D writes that must be preserved to the source, using the canonical write path
   (not a direct SQL update), so that they enter the outbox and are synchronised back to the target.
6. Once the reconciler confirms zero diffs, the dual-writer can be restarted and Phase C is stable.

**Data implications:** Any writes applied to the target during Phase D that are not manually
applied to the source will be overwritten when the dual-writer synchronises the source state to
the target. The window during which this can happen is bounded by the duration of Phase D before
rollback. A Phase D that ran for seconds before rollback has a narrow window; a Phase D that ran
for minutes has a wider one.

**Divergence detection:** The emergency reconciliation pass is the detection mechanism. Run it
immediately after setting `CutoverPhase = C` and before restarting the dual-writer. Do not
restart the dual-writer until the reconciliation report has been reviewed and any Phase D writes
that must be preserved have been applied to the source.

---

## General notes on rollback

A rollback is not a failure. A rollback that happens early in the cutover sequence, before Phase D,
is a normal part of the process. Document every rollback with: the phase from which the rollback
was initiated, the time, the observable signal that triggered it, and the investigation outcome.
This documentation is more valuable than the code; it is what makes the next cutover safer.
