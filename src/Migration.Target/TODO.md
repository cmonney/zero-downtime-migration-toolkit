# src/Migration.Target — TODO

## What this folder will contain

The data access layer for the consolidated target SQL Server database. This project will contain:
repository interface implementations for each entity type in the canonical unified schema; the
idempotency table management (creating records keyed on the dual-writer's idempotency keys,
detecting duplicates, and discarding them); and connection string configuration. Unlike the source
data access layers, this project's entity models reflect the canonical schema designed from first
principles: money as decimal at a fixed scale, all datetimes in UTC at microsecond precision,
no float money, no nullable FK soft-deletes.

## Acceptance criteria

- All entity types in the target schema have a corresponding repository class.
- The idempotent applier correctly detects and discards a duplicate write (same idempotency key)
  with no error and no side effect, evidenced by a unit test with an in-memory idempotency store.
- The idempotent applier correctly applies a new write (new idempotency key) and records the key,
  evidenced by an integration test against a real SQL Server container.
- No business logic is present in this project.

## Build order

Build after: Migration.Contracts.
Build before: Migration.DualWriter, Migration.Reconciler.
Build at the same time as Migration.SourceA and Migration.SourceB.
