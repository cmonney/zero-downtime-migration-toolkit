# samples/messy-data — TODO

## What this folder will contain

Standalone example data files illustrating the kinds of data anomaly the reconciler must handle,
provided as self-contained CSV or SQL snippet files with explanatory commentary. These samples
are not used by any automated process; they exist so that a reviewer reading the repository can
understand the drift categories from ADR 0003 without running the full Docker Compose environment.

Planned files:

- `encoding-drift.md`: an annotated example of a `varchar(100)` column in Latin1 collation storing
  a string containing characters outside the Latin1 range, and what the stored bytes look like
  versus what the application intended to store.
- `datetime-precision-loss.md`: an example showing a `datetime` value at second precision in local
  time (Source A) versus the same event represented as `datetime2(6)` in UTC (target), including
  the arithmetic required to compare them correctly.
- `decimal-scale-mismatch.md`: an example of a financial amount stored as `float` (Source A),
  `decimal(10,2)` (Source B), and `decimal(19,4)` (target), with the values that appear equal but
  are not once precision is examined.
- `null-vs-empty-string.md`: an example of a record where the source stores NULL and the target
  stores an empty string, or vice versa, and why bulk-copy tooling commonly introduces this drift.

## Acceptance criteria

Each sample file is self-contained: a reviewer with no access to the running Docker environment
can read the file and understand the drift category it illustrates, including the SQL that would
produce it and the normalisation rule the reconciler applies.

## Build order

Write these after the seed scripts are designed but before the reconciler is implemented. They
serve as a design aid for the normalisation rules and as documentation for reviewers.
