# src/Migration.DualWriter — TODO

## What this folder will contain

The dual-write orchestrator, implemented as a library embedded in the strangler API and exposed
as an ASP.NET Core hosted service. This project contains:

- `IDualWriter`: the interface through which the strangler API submits canonical write commands.
- `OutboxWriter`: applies a write command to the source database and writes an outbox record
  atomically in the same local database transaction.
- `OutboxRelay`: a background service that reads unprocessed outbox records and calls the target's
  idempotent applier. Tracks progress using a high-water mark committed to the outbox table. Uses
  exponential backoff on transient failures.
- `IdempotencyKey`: a value type representing the deterministic key derived from the entity ID,
  payload hash, and outbox sequence position.

The outbox table schema is defined as a migration script in `tools/seed/` and applied to the
source databases during init. The outbox relay does not require a separate process; it runs as a
hosted service within the strangler API process.

## Acceptance criteria

- A write command applied through `IDualWriter` appears in the source database and in the outbox
  table within a single committed transaction, evidenced by an integration test that kills the relay
  before it can run and verifies the outbox record is present.
- A duplicate write command (same idempotency key) is applied exactly once to the target, evidenced
  by an integration test that submits the same command twice and asserts one row in the target.
- The relay correctly resumes from the high-water mark after a simulated restart, with no records
  skipped or duplicated, evidenced by an integration test that stops and restarts the relay mid-run.
- Outbox lag (unprocessed outbox record count) is exposed as a named metric consumable by the
  cutover test.

## Build order

Build after: Migration.Contracts, Migration.SourceA, Migration.SourceB, Migration.Target.
Build before: Migration.StranglerApi (which embeds this library).
