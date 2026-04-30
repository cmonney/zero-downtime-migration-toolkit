# src/Migration.Reconciler — TODO

## What this folder will contain

The reconciliation engine. This is the most technically complex project in the repository and the
one whose design is most directly tied to the zero-downtime claim. It will contain:

- `IReconciler`: the public interface. Accepts a reconciliation configuration (which databases to
  compare, which entities to include, what normalisation rules apply to each column) and returns a
  `ReconciliationReport`.
- `ReconciliationReport`: a structured result containing, per entity type, a count of matching
  rows, a count of differing rows, and for each of the eight named drift categories defined in
  ADR 0003, a count of affected rows and, for the first N instances, the source and target
  normalised values side by side.
- `NormalisationRule` and its per-type implementations: `StringNormalisationRule`,
  `DatetimeNormalisationRule`, `DecimalNormalisationRule`, `NullNormalisationRule`, etc.
- `ChecksumComputer`: takes a row's normalised column values and produces a deterministic hash.
- `BatchedRowReader`: reads entities from each database in configurable batch sizes to avoid
  loading entire tables into memory.
- `DriftCategoryClassifier`: given two normalised row representations that do not match, determines
  which of the eight named drift categories applies.

The reconciler runs as a hosted service within the strangler API from Phase B onwards, at a
configurable interval. It can also be invoked on demand (e.g., for the final reconciliation pass
before Phase D).

## Acceptance criteria

Given two databases seeded with the MVP schemas (Source A, Source B, and Target), the reconciler:

1. Produces a `ReconciliationReport` that identifies every instance of each of the eight drift
   categories seeded in the source data, by category name, with an accurate count.
2. Produces zero false positives when run against two identical datasets (a control run where both
   the source and target contain identical data produces a report with zero diffs in all categories).
3. Correctly handles the eventual-consistency window during Phase C: a diff present at the start of
   a reconciliation pass that disappears before the pass completes is not reported as a drift event.
4. The report is serialisable to JSON and readable by the cutover SLO test.
5. The reconciler can be configured per-column: changing a normalisation rule does not require
   recompiling the reconciler, only updating its configuration.

## Build order

This is the second project to implement after Migration.Contracts. Its interface and report types
inform the design of the cutover test and the strangler API's shadow-compare logic. Build the
interface and report model first, then the normalisation rules, then the checksum computer, then
the full reconciler. Wire it into the strangler API last.
