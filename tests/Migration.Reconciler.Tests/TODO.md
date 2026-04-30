# tests/Migration.Reconciler.Tests — TODO

## What this folder will contain

Unit and component tests for the reconciliation engine. Tests in this project do not require a
running Docker environment; they use in-memory fakes or Testcontainers to spin up isolated SQL
Server instances per test class. The test coverage must exercise:

- Each of the eight named drift categories from ADR 0003, verified by seeding a source and target
  pair with a deliberate instance of each category and asserting the reconciler report correctly
  identifies it by name.
- The normalisation rules for each column type: strings, datetimes, decimals, floats, NULLs,
  and binary values.
- The false-positive control: identical source and target produce zero diffs in all categories.
- The checksum computation: the same normalised values always produce the same checksum; different
  normalised values always produce different checksums (with high probability — document any
  known collision risk for the chosen hash algorithm).
- Batched reading: a table with more rows than the configured batch size is reconciled correctly
  with no rows skipped or double-counted.

## Acceptance criteria

Given two databases seeded with the MVP schemas, the reconciler unit tests:

1. Pass with zero failures on a standard developer machine with Docker available.
2. Cover all eight drift categories with at least one positive test case (drift present, correctly
   detected) and one negative test case (drift absent, no false positive) per category.
3. Complete within 60 seconds on a machine with a local Docker daemon.
4. Produce a coverage report showing at least 80% line coverage of the
   `Migration.Reconciler` project's non-infrastructure code.

## Build order

Build after: Migration.Reconciler (and therefore after Migration.Contracts and all three data
access layers). This is the first test project to implement; its tests define the reconciler's
acceptance criteria and should be written before the reconciler implementation is complete
(test-first or test-concurrent, not test-after).
