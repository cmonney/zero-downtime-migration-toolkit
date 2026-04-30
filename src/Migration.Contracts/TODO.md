# src/Migration.Contracts — TODO

## What this folder will contain

The shared contracts assembly referenced by all other projects. This project contains no
implementation code; it is a pure definition assembly. It will contain:

- **Canonical domain model DTOs**: the types that represent entities in their canonicalised form,
  independent of any source or target database schema. These are the types the strangler API
  exposes to callers and the types the dual-writer accepts as commands.
- **Command types**: `WriteEntityCommand<T>`, carrying the entity payload and an idempotency key.
- **`CutoverPhase` enumeration**: `A`, `B`, `C`, `D` — used by the strangler API, the dual-writer,
  and the cutover test.
- **`ReconciliationReport` and related types**: the structured output of the reconciler, shared
  between the reconciler and the cutover test.
- **`DriftCategory` enumeration**: the eight named categories from ADR 0003.
- **`IdempotencyKey` value type**: a strongly-typed wrapper around the deterministic key string.
- **Interface definitions**: `IReconciler`, `IDualWriter`, `ISourceARepository`,
  `ISourceBRepository`, `ITargetRepository` — defined here to avoid circular project references.

## Acceptance criteria

- All types in this project have XML documentation comments sufficient for IDE hover tooltips to
  convey their purpose without reading the source.
- No project other than this one defines types that cross project boundaries.
- The project compiles with zero warnings (enforced by `TreatWarningsAsErrors` in
  `Directory.Build.props`).
- No implementation code, no dependencies on third-party packages (only the .NET BCL).

## Build order

Build first. All other projects depend on this one. Define the interfaces and report types before
implementing any concrete class in any other project; this forces the contracts to be driven by
what callers need, not by what implementations are convenient.
