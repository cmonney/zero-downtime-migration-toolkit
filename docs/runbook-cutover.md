# Cutover Runbook

This document is an executable checklist for the full cutover sequence. It is written to be
followed by an engineer who has read it before the cutover begins, not sight-read under pressure.
Read the rollback procedure for each phase before executing the forward path.

The cutover integration test in `tests/Migration.Cutover.Tests` exercises this sequence under
synthetic load. If the test does not pass cleanly, this runbook must not be executed.

---

## Preparation

**Read before starting:**

- `docs/runbook-rollback.md` in full.
- The reconciler drift category definitions in `docs/adr/0003-reconciliation-by-row-checksum.md`.
- The feature flag names and their effects, as documented in `src/Migration.StranglerApi/TODO.md`.

**Prerequisites for starting:**

- The cutover integration test has passed within the last 24 hours against the current codebase.
- Observability dashboards are accessible and showing a steady baseline.
- At least two engineers are present and have read this runbook.
- A communication channel is open with whoever is responsible for approving the Phase D transition.
- A rollback decision authority has been nominated and is available for the full duration.

---

## Phase A (baseline): read from source

This is the starting state. All reads and writes go to the source databases. The target receives no
traffic. No action is required to enter Phase A; document that the cutover has started and record
the start time.

**Entry criteria:** N/A — this is the starting state.

**Observable state:** strangler API metrics show zero traffic to target. Reconciler is not running.

---

## Phase A to Phase B: enable shadow compare

**Rollback procedure (read this first):**

If shadow-compare reveals unexpected errors or the strangler API log shows a high compare-failure
rate, flip `CutoverPhase` back to `A`. No data is affected; shadow reads are side-effect-free.
Record the failure reason. Do not advance to Phase B again until the failure is understood.

**Forward path:**

1. Confirm the load generator has been running steadily for at least 15 minutes and p99 latency is
   within the defined SLO threshold.
2. Set the feature flag `CutoverPhase = B` on the running strangler API instance.
3. Observe the strangler API logs for `shadow-compare-failure` events. An initial burst of
   failures indicates the target has not been seeded or the reconciler has not run; a sustained
   elevated failure rate indicates a data problem that must be investigated before advancing.
4. Hold Phase B for at least 30 minutes of steady traffic with zero shadow-compare failures.

**Entry criteria:** load generator running; p99 latency within SLO; zero shadow-compare failures
sustained for 30 minutes.

**Abort criteria:** shadow-compare failure rate above zero sustained for more than 5 minutes after
the initial startup period.

---

## Phase B to Phase C: enable dual-write

**Rollback procedure (read this first):**

Set `CutoverPhase = B`. The dual-writer will stop accepting new write commands. Any writes in the
outbox that have not yet been applied to the target will remain in the outbox and can be replayed
once the issue is diagnosed. No data written to the source during Phase C is lost; the source
remains the system of record. See `docs/runbook-rollback.md` for the outbox drain procedure.

**Forward path:**

1. Confirm the reconciler is running and reporting zero diffs in shadow-read mode.
2. Set `CutoverPhase = C`.
3. Observe outbox lag (the number of outbox records not yet applied to the target). This will
   spike immediately as the outbox begins filling; it should trend to zero within the configured
   relay window.
4. Observe the reconciler diff count. A non-zero diff count that decreases to zero within the
   expected synchronisation window is normal. A diff count that does not decrease or increases
   indicates a relay failure.
5. Hold Phase C until the reconciler reports zero diffs and the outbox lag is consistently zero
   for at least 30 minutes.

**Entry criteria:** reconciler reporting zero diffs in Phase B; load generator running; p99
latency within SLO.

**Abort criteria:** outbox lag grows continuously and does not stabilise; reconciler diff count
does not reach zero within the expected window; p99 latency exceeds SLO threshold.

---

## Phase C to Phase D: read from target only

This is the point of no inexpensive return. Rollback from Phase D is lossy if any writes have
reached the target after the phase transition. Do not advance without explicit approval from the
nominated rollback decision authority.

**Rollback procedure (read this first):**

See `docs/runbook-rollback.md`, section "Rolling back from Phase D". The procedure involves setting
`CutoverPhase = C`, running the reconciler to identify any writes applied to the target during
Phase D that are not present in the source, and applying those writes to the source before
re-entering Phase C. This is the most complex rollback in the sequence and has a non-zero data risk.

**Forward path:**

1. Confirm the reconciler reports zero diffs with outbox lag consistently zero for at least 30
   minutes.
2. Obtain explicit approval from the rollback decision authority.
3. Set `CutoverPhase = D`. Sources are now read-only from the strangler API's perspective.
4. Observe the strangler API metrics: all reads should go to the target; zero reads should go to
   the source.
5. Observe p99 latency: the target schema may have different query performance characteristics
   from the sources. Watch for latency increases above the SLO threshold.
6. Hold Phase D for at least 60 minutes of steady traffic before proceeding to post-cutover.

**Entry criteria:** reconciler zero diffs for 30 minutes; outbox lag zero for 30 minutes; rollback
authority approval obtained.

**Abort criteria:** p99 latency exceeds SLO threshold; strangler API error rate rises above zero;
reconciler reports new diffs during Phase D (indicating a relay issue not caught before transition).

---

## Post-cutover

1. Run a final full reconciliation pass against both sources and the target. Record the report.
2. Archive the outbox table from each source.
3. Set the sources to read-only at the database level (revoke write permissions from the
   application account).
4. Update the deployment configuration to remove the source connection strings from the strangler
   API's environment.
5. Schedule the decommission of the source database instances in accordance with the organisation's
   data retention policy.
6. Record the cutover end time and publish a brief post-cutover summary to the communication
   channel.
