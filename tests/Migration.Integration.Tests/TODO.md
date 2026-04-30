# tests/Migration.Integration.Tests — TODO

## What this folder will contain

Integration tests that exercise the strangler API and dual-writer against real SQL Server containers.
These tests require all three database containers to be running (via Docker Compose or Testcontainers)
and the strangler API to be reachable. They cover:

- Phase A: reads and writes go to Source A and Source B; the target receives no traffic (verified by
  asserting zero rows in the target idempotency table after a write).
- Phase B: shadow-compare events are emitted for every read; a deliberate discrepancy between source
  and target produces a `shadow-compare-failure` log event.
- Phase C: a write command applied through the API appears in both the source outbox and eventually
  in the target; a duplicate write (same idempotency key) appears exactly once in the target.
- Phase D: reads go to the target; sources are read-only; a direct write attempt to a source (not
  via the API) succeeds but the API returns data from the target.
- Phase transitions: flipping the `CutoverPhase` flag at runtime produces the correct routing
  behaviour immediately, without a service restart.

## Acceptance criteria

- All phase-specific behaviours listed above are covered by at least one test each.
- Tests are isolated: each test class uses a fresh database state (Testcontainers or a database
  reset fixture between tests).
- Tests pass within 3 minutes on a standard developer machine with Docker available.
- No test depends on test execution order.

## Build order

Build after: Migration.StranglerApi, Migration.DualWriter, Migration.Reconciler (this project
tests the integrated behaviour of all three). Build before Migration.Cutover.Tests.
