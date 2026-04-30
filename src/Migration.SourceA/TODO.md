# src/Migration.SourceA — TODO

## What this folder will contain

The data access layer for Source A, the practice-management-style legacy SQL Server database. This
project will contain: the Entity Framework Core or Dapper-based DbContext (or query factory) for
Source A; repository interface implementations for each entity type exposed to the strangler API;
connection string configuration wired from the ASP.NET Core configuration system; and a read-only
mode switch that the strangler API activates during Phase D to prevent any further writes to Source
A after cutover completes.

The project's assembly references Source A's entity models, which reflect the legacy schema as-is
— float money columns, second-precision datetimes, nullable FK soft-deletes — rather than the
canonical domain model defined in Migration.Contracts. Mapping to the canonical model is the
responsibility of the strangler API's service layer, not this data access layer.

## Acceptance criteria

- All entity types present in the seeded Source A schema have a corresponding repository class
  returning typed results.
- The read-only mode switch, when activated, causes all write operations to throw a
  `SourceReadOnlyException` with a clear message indicating the phase.
- The unit tests in `Migration.Reconciler.Tests` that exercise Source A's repository layer pass
  against a real SQL Server container (via Testcontainers or a pre-started Docker service).
- No business logic is present in this project; it is a pure data access layer.

## Build order

Build after: Migration.Contracts (which defines the canonical domain model and shared interfaces).
Build before: Migration.StranglerApi, Migration.DualWriter, Migration.Reconciler (all of which
depend on data access layers).
