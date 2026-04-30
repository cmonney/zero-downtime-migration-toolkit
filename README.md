# zero-downtime-migration-toolkit

A reference implementation of consolidating two messy legacy SQL Server databases into a single
modernised target, using the strangler-fig pattern with dual-writes and a normalised reconciliation
engine. A synthetic load generator drives continuous traffic throughout an automated cutover sequence
and asserts that no user-perceived downtime occurred within defined service-level objectives.

---

## What this repository proves

**Central claim:** demonstrates user-perceived zero-downtime consolidation of two SQL Server databases
into a single target, evidenced by an automated cutover test that maintains p99 latency below a defined
threshold and reports zero failed writes under continuous synthetic load.

"Zero downtime" is shorthand for "no user-perceived downtime within defined SLOs during a controlled
cutover sequence, bounded by a specific traffic profile". The distinction matters: every phase
transition incurs a brief coordination cost; the claim is that this cost is not visible to callers
against their SLO thresholds, not that it does not exist. The SLOs are defined by the cutover test
and are reproducible under Docker on a laptop, not derived from a production agreement. See
`LIMITATIONS.md` for a full accounting of what is and is not proven.

---

## Why two sources

Consolidating one database into another is a migration. Consolidating two databases with genuinely
different schemas, different collations, different modelling decisions, and years of independent legacy
fixes is the actual hard problem. Source A models a practice-management-style system: Latin1 collation,
`varchar` columns storing Unicode by accident, datetime precision at the second, nullable FKs used as
soft-delete markers, and money stored as `float`. Source B models a billing-style system: a UTF-8-leaning
collation, `nvarchar` throughout but with trailing whitespace baked into historic records, datetime
stored as UTC in some tables and local time in others, and decimal amounts at inconsistent scales.
These inconsistencies are seeded deliberately — the reconciler must detect all of them by named category,
not by accident.

---

## Architecture at a glance

See [`docs/architecture.md`](docs/architecture.md) for the full treatment.

<!-- TODO: C4 container diagram as SVG -->

The system has six moving parts:

**Source A and Source B** are the legacy databases. During the migration, both continue to serve live
traffic. They are not modified beyond the addition of an outbox table during Phase C.

**The target** is the modernised consolidated database. Its schema is designed from first principles;
it does not inherit the modelling decisions of either source.

**The strangler API** is the single HTTP façade that all callers use throughout the cutover. It
implements four routing phases, toggled by feature flags without a service restart:

- **Phase A — read from source:** reads and writes go to Source A (or B, depending on the entity).
  The target receives no traffic.
- **Phase B — shadow compare:** reads still go to source; the API also issues the same read against
  the target and records any discrepancy. No caller-visible change.
- **Phase C — dual-write:** writes are applied to the source and enqueued to the target via the
  dual-writer. Reads still go to source. The reconciler runs continuously.
- **Phase D — read from target:** sources become read-only. All reads and writes go to the target.

**The dual-writer** implements the transactional outbox pattern at the source side and an idempotent
applier at the target side. It is not a queue broker; it is a library embedded in the strangler API
and run as a hosted service.

**The reconciler** runs continuously from Phase B onwards, computing normalised per-row checksums and
surfacing differences by named drift category. It is the instrument of truth: the cutover test passes
or fails based on its output.

**The load generator** drives HTTP traffic against the strangler API at a configurable request rate
throughout the full cutover sequence, including across every phase transition.

---

## Run it locally in ninety seconds

```bash
git clone https://github.com/cmonney/zero-downtime-migration-toolkit.git
cd zero-downtime-migration-toolkit
docker compose up -d
dotnet test tests/Migration.Cutover.Tests --logger "console;verbosity=detailed"
```

**Honest caveat:** these commands describe the intended local experience once the MVP is implemented.
At the current scaffold stage, `docker compose up` will start the database containers but the
application services are not yet wired. See [`ROADMAP.md`](ROADMAP.md) for the implementation
sequence and the current state of each component.

---

## What this is not

- Not a tool validated for use with FCA-regulated or other regulated production data.
- Not a reference for handling real personally identifiable information; all seeded data is synthetic.
- Not a replacement for Microsoft's SQL Server Migration Assistant or Data Migration Assistant, which
  address assessment and schema-translation concerns that are out of scope here.
- Not a tested, deployable production tool. It is a reference implementation.
- Not a full toolkit: CDC-based migration patterns, multi-region topologies, and cross-provider
  migration are explicitly out of scope.
- Not a demonstration that "zero downtime" is achievable under all traffic patterns or at all scales.
  The SLOs are defined by this repository's load generator profile.

---

## Design tensions

**Dual-write versus CDC.** Change-data-capture would decouple the write path from the migration
infrastructure entirely: writes hit the source, the CDC pipeline replicates them asynchronously to
the target, and the strangler API switches reads when reconciliation confirms parity. The trade-off
is operational complexity: CDC requires a running capture process, a replication topic or log, and
careful handling of schema changes on the source during the migration window. For the scale this
repository targets, the transactional outbox is simpler to reason about, simpler to test, and does
not require additional infrastructure. CDC is documented in the roadmap as a Phase 2 pattern for
higher-volume scenarios. See [ADR 0002](docs/adr/0002-dual-write-coordination-strategy.md).

**Per-row checksum versus row count plus sampling.** Counting rows and spot-checking a sample is
fast and adequate for catching bulk data loss. It is inadequate for catching encoding drift, precision
loss, NULL-versus-empty-string divergence, or collation-induced case sensitivity differences — all of
which are present in the seeded source schemas. The reconciler computes a normalised checksum per
logical entity, where normalisation is explicit and per-column. This is slower but it catches the
failures that matter in a real consolidation. The trade-off is acknowledged: at very high row counts,
continuous reconciliation would require a batching and pagination strategy not present in the MVP.
See [ADR 0003](docs/adr/0003-reconciliation-by-row-checksum.md).

**Feature-flagged routing in-process versus a separate proxy.** A dedicated proxy (NGINX, Envoy, a
custom sidecar) can switch routing without modifying application code, which is attractive if the
strangler must wrap an unmodifiable legacy service. Here, the strangler API is written from scratch,
so embedding the routing logic in the application is simpler, fully testable in-process, and avoids
the operational overhead of a separately deployed proxy. The proxy approach would be the correct
choice if the strangler were wrapping an existing service without access to its source. See
[`docs/design-tensions.md`](docs/design-tensions.md) for the extended version of each of these
discussions.

---

## Reading order for engineers

If you have fifteen minutes:

1. This README (you are here).
2. [ADR 0003 — Reconciliation by row checksum](docs/adr/0003-reconciliation-by-row-checksum.md) —
   the most technically substantive document in the repository.
3. `src/Migration.Reconciler/TODO.md` — what the reconciler interface looks like and what its
   acceptance criteria are.
4. [docs/runbook-cutover.md](docs/runbook-cutover.md) — the cutover sequence as an executable checklist.
5. `tests/Migration.Cutover.Tests/TODO.md` — what the cutover SLO test asserts and how.

---

## Roadmap

The MVP covers the strangler API, dual-writer, reconciliation engine, and the cutover SLO test.
Bulk-and-delta cutover, working Bicep deployment, chaos injection, and CDC variants are explicitly
deferred. See [`ROADMAP.md`](ROADMAP.md) for the full breakdown with acceptance criteria.

---

## Licence

Apache-2.0. See [`LICENCE`](LICENCE) and [`NOTICE`](NOTICE).

Author: Christopher Monney — [github.com/cmonney](https://github.com/cmonney)
