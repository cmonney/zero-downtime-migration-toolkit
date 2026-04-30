# Architecture

This document describes the system's structure at the container level. It is a prose complement to
the ADRs, which record the decisions, and the runbooks, which record the operational procedures.

---

## System Context

The system consolidates two legacy SQL Server databases — Source A and Source B — into a single
modernised target database. During the migration, all callers communicate exclusively with the
strangler API; they are unaware of which underlying database is serving their request at any given
phase of the cutover. The strangler API is the boundary of the system from the caller's perspective.

<!-- TODO: C4 context diagram as SVG — show: caller → Strangler API → [Source A, Source B, Target] -->

---

## Container View

<!-- TODO: C4 container diagram as SVG — show all six containers with labelled interaction arrows -->

**Source A** is a containerised SQL Server 2022 instance configured with Latin1 collation. It
hosts the practice-management-style legacy schema: patient or client records, appointment history,
practitioner assignments, and associated reference data. The schema has accumulated real-world
drift: float money columns, second-precision datetimes in local time, varchar columns storing
Unicode by accident, and nullable FKs used as soft-delete markers. It is not modified during the
migration except for the addition of an outbox table in Phase C.

**Source B** is a containerised SQL Server 2022 instance with a UTF-8-leaning collation. It hosts
the billing-style legacy schema: invoices, line items, payment records, and account balances. It
uses nvarchar throughout but historic import records have trailing whitespace, and datetime columns
are inconsistently in UTC or local time depending on which team wrote the table. Decimal amounts
exist at inconsistent scales. It is not modified during the migration except for the addition of
an outbox table in Phase C.

**The target** is a containerised SQL Server 2022 instance with modern settings: a case-sensitive
UTF-8 collation, money stored as decimal at a fixed scale, all datetimes in UTC at microsecond
precision, and a unified schema that does not inherit the modelling choices of either source.

**The strangler API** is an ASP.NET Core service that is the sole entry point for callers. It
implements four routing phases controlled by a feature flag. In Phases A and B, it issues reads and
writes against the sources. In Phase C, it continues to issue reads against the sources while
routing writes through the dual-writer, which applies them to both source and target. In Phase D,
it issues all reads and writes against the target and the sources are read-only.

**The dual-writer** is a library embedded in the strangler API, running as a hosted service. It
implements the transactional outbox pattern: a write command is applied to the source and an outbox
record is written atomically; a relay process reads the outbox and applies each record to the
target idempotently. See ADR 0002.

**The reconciler** is a background service that runs from Phase B onwards. It computes normalised
per-row checksums for each logical entity across all three databases and reports differences by
named drift category. See ADR 0003 for the full specification.

**The load generator** is a tool in `tools/load-generator/` that drives HTTP traffic against the
strangler API at a configurable rate. It is used by the cutover integration test to simulate
continuous caller traffic throughout the full cutover sequence.

---

## Data Flow: a single write in Phase C

A caller issues a `POST /entities/{id}` request to the strangler API with a write payload.

1. The strangler API reads the current phase flag. Phase C is active.
2. The API calls the dual-writer with the canonical write command, which carries a deterministic
   idempotency key derived from the entity ID, the payload hash, and the current sequence counter.
3. The dual-writer opens a transaction against the source database, applies the write, and writes
   an outbox record containing the idempotency key and the serialised command. The transaction
   commits. The API returns 200 to the caller.
4. Asynchronously, the outbox relay reads the outbox record. It calls the target's idempotent
   applier with the command and idempotency key. If the key is already present in the target's
   idempotency table, the applier discards the command. If not, it applies the write and records
   the key.
5. The reconciler's next pass reads the row from both the source and the target, normalises both,
   and computes their checksums. If the outbox relay has not yet applied the write, the checksums
   will differ; this is expected within the synchronisation window. If the checksums still differ
   after the window has elapsed, the reconciler raises a drift event.
