# src/Migration.SourceB — TODO

## What this folder will contain

The data access layer for Source B, the billing-style legacy SQL Server database. This project will
contain: repository interface implementations for each entity type exposed to the strangler API;
connection string configuration; and a read-only mode switch for Phase D. The Source B schema uses
nvarchar throughout but contains trailing whitespace in historic records, mixed UTC/local datetime
columns, and decimal amounts at inconsistent scales across tables. These characteristics are
represented in the entity models as-is; normalisation happens in the reconciler, not here.

Like Migration.SourceA, this project is a pure data access layer. Mapping from Source B's model to
the canonical domain model in Migration.Contracts is the responsibility of the strangler API's
service layer.

## Acceptance criteria

- All entity types present in the seeded Source B schema have a corresponding repository class.
- The trailing whitespace, mixed-UTC datetime, and inconsistent decimal scale characteristics of
  the schema are visible in the entity models (i.e., the data access layer does not silently
  normalise them).
- The read-only mode switch works identically to the one in Migration.SourceA.
- No business logic is present in this project.

## Build order

Build after: Migration.Contracts.
Build before: Migration.StranglerApi, Migration.DualWriter, Migration.Reconciler.
Build at the same time as Migration.SourceA — the two are independent of each other.
