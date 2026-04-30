# ADR 0003 — Reconciliation by Row Checksum

**Status:** Accepted

---

## Context

The central claim of this repository — no user-perceived downtime with zero data loss — requires a
mechanism that can confirm the claim, not merely assert it. Row counts matching between source and
target is a necessary condition for the claim to hold, but it is far from sufficient. Two databases
can have identical row counts while containing entirely different data in every row, and this is not
a hypothetical: encoding drift, precision loss, and collation-induced transformations routinely
produce exactly this situation in real legacy migrations.

The two source databases in this repository are seeded with deliberate inconsistencies:

- **Source A** stores Unicode data in `varchar` columns using a Latin1 collation, which silently
  discards non-Latin characters. It stores money as `float`, losing precision at the seventh
  significant digit. Datetime is stored at second precision in local time.
- **Source B** stores `nvarchar` data but historic records have trailing whitespace baked in from
  a long-retired import process. Datetime is stored at millisecond precision but inconsistently in
  UTC in some tables and local time in others. Decimal amounts exist at two different scales across
  different tables due to an unfinished schema migration.

A reconciliation mechanism that detects divergence only by row count, or only by spot-checking a
random sample of rows, will not reliably detect these classes of problem. The migration could
complete, the cutover could succeed, and the target could be silently wrong in a category of values
that the reconciler did not check.

---

## Decision

The reconciler computes a normalised per-row checksum for each logical entity across all three
databases and compares source checksums against target checksums in batches. Normalisation is
explicit, per-column, and version-controlled: adding a new column type requires a new normalisation
rule, which must be reviewed and approved before the reconciler is deployed against new data.

The normalisation rules are:

- **String values:** Unicode NFC normalisation, then trim leading and trailing whitespace, then
  compare. The comparison is case-sensitive unless the business rule for the column is documented
  as case-insensitive, in which case the column is lowercased before hashing.
- **Datetime values:** convert to UTC, truncate to microsecond precision, compare as ISO 8601
  strings. The source's local-time columns require a UTC offset to be supplied as a reconciler
  configuration value — this is a migration-specific parameter, not a constant.
- **Decimal and numeric values:** normalise to a fixed scale (defined per-column in reconciler
  configuration) before hashing. Scale mismatches that exceed a defined tolerance are reported as
  precision drift, not as equality.
- **Float and real values:** converted to decimal at the configured scale before comparison.
  Float columns used to store money are flagged in the reconciler configuration and reconciled
  against the decimal target column with an explicit tolerance.
- **NULL values:** NULL is distinct from empty string, from zero, and from the whitespace-only
  string. A source `varchar` column containing an empty string and a target `nvarchar` column
  containing NULL are a drift event, not a match.
- **Binary values:** compared as byte arrays after decoding from the source's documented encoding.

The eight named drift categories the reconciler reports are:

1. **Encoding drift:** a value that exists in the source but cannot round-trip through the target's
   collation or encoding without alteration. Detected when the normalised string representation of
   the source value differs from the normalised string representation of the target value after
   applying the same normalisation rule to both.

2. **Datetime precision loss:** a datetime value that exists at finer granularity in the source
   than in the target, or that has been silently shifted by a timezone conversion. Detected when
   the UTC-normalised source datetime does not match the UTC-normalised target datetime.

3. **Decimal scale truncation:** a decimal or numeric value that has been stored at a coarser
   scale in the target than in the source, producing a value that differs beyond the defined
   tolerance. Detected when the absolute difference between the normalised source and target
   values exceeds the configured tolerance for that column.

4. **NULL-versus-empty-string divergence:** a source value that is NULL and a target value that is
   an empty string (or vice versa), or a source value that is a whitespace-only string treated as
   semantically NULL by the legacy application and a target value that is NULL. Detected explicitly
   because NULL semantics are not preserved by most bulk-copy tooling.

5. **Trailing whitespace drift:** a source value with trailing whitespace that has been trimmed in
   the target, or a target value with trailing whitespace added by a normalisation step. The
   normalisation rule trims both sides before comparison; this category records cases where the
   raw values differ only in trailing whitespace, to distinguish them from substantive differences.

6. **Case-sensitivity drift across collations:** a value that matches under a case-insensitive
   collation (as in Source A's Latin1 collation) but does not match under a case-sensitive
   collation (as in the target's modern collation). Detected when the case-sensitive comparison
   fails but the case-insensitive comparison passes.

7. **Soft-delete inconsistency:** a record marked as deleted in the source via a nullable FK or a
   `deleted_at` timestamp that is not represented consistently in the target's soft-delete
   mechanism. Detected by comparing the effective active-or-deleted state of each record rather
   than the raw column value.

8. **Modelling-difference drift:** the two sources represent the same logical entity differently
   — for example, Source A stores a customer's address as a single `varchar(500)` column while
   Source B stores it across five normalised columns. The reconciler must compare against the
   target's canonical form of the entity, not against either source's raw form. This requires a
   per-entity canonicalisation function in the reconciler configuration. Detected when the
   canonicalised source value does not match the canonicalised target value.

Differences are surfaced in a structured report per reconciliation run, grouped by drift category,
with a count of affected rows and, for the first N instances of each category, the source and
target normalised values side by side.

---

## Consequences

Reconciliation is slower than `COUNT(*)`. On the seeded dataset sizes in this repository, a full
reconciliation pass takes seconds. At production scale — millions of rows per table — continuous
full reconciliation would be impractical and a windowed or incremental approach would be required.
This is noted in `LIMITATIONS.md` and on the roadmap.

The normalisation rules are migration-specific configuration, not general-purpose code. A
reconciler configured for this migration cannot be applied to a different migration without
reviewing and updating every column's normalisation rule. This is correct: a general-purpose
reconciler that makes assumptions about normalisation will produce false negatives.

Every new column type added to the seeded schema requires a normalisation rule. This maintenance
burden is the cost of correctness.

---

## Alternatives Considered

**Row count plus spot-check sampling.** Fast. Catches bulk data loss. Does not catch any of the
eight named drift categories above. Rejected: the whole point of this repository is to demonstrate
that the named categories are detected. A reconciler that relies on sampling cannot make a
categorical claim about data integrity.

**Block-level checksum on table pages.** Would allow fast comparison of large tables without
reading every row. Rejected: SQL Server's page-level checksums reflect the physical storage format,
not the logical data values, and are not comparable across a source and a target with different
schemas, collations, or index structures. This approach is also unusable when the source and target
schemas differ.

**Full row diff in application code, comparing every column for every row.** Would detect every
possible difference but is orders of magnitude slower than the checksum approach and, more
importantly, produces a diff report that is not categorised: all differences look the same, making
it impossible to distinguish deliberate canonicalisation from data loss. Rejected.
