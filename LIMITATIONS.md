# Limitations

This file records what the repository does not prove and where reasonable people might reach different
design conclusions. It is written to be read by engineers evaluating the repository critically, not
to protect against criticism. Honest limitations are a credibility signal; a limitations section
that lists only trivial caveats is not.

---

## "Zero downtime" is bounded by the load profile

The phrase "zero downtime" as used in the repository title and README is shorthand for "no
user-perceived downtime within defined SLOs under the load generator's traffic profile". The load
generator runs at a configurable but fixed request rate against a small synthetic dataset on local
Docker infrastructure. This is sufficient to demonstrate that the strangler API's routing transitions
are invisible to callers at that scale and rate. It does not prove that the same is true under
production traffic volumes, during resource contention, or in the presence of long-running
transactions. The SLO thresholds are defined in the cutover test and are chosen to be achievable on
a modern development machine; they should not be quoted as production guarantees.

---

## The source schemas are smaller than real legacy estates

The seeded source schemas are deliberately messy — they include encoding drift, precision loss,
NULL-versus-empty-string divergence, trailing whitespace, collation inconsistencies, and modelling
differences — but they are tractable. A real legacy estate of similar age would likely have hundreds
of tables, circular foreign key relationships, undocumented stored procedures driving business logic,
and data that violates constraints that were dropped years ago. The repository models the classes of
inconsistency, not the scale. The reconciler design is intended to be extensible to a larger schema;
the seed data is not.

---

## The reconciliation engine detects named drift categories, not all possible categories

ADR 0003 defines eight named drift categories that the reconciler must detect. This is not an
exhaustive taxonomy of all possible divergence between SQL Server databases. Categories not in scope
for the MVP include: index fragmentation differences visible only through query-plan divergence,
statistics drift affecting query performance without data divergence, row-level security policies
returning different result sets for the same query, and triggers with side effects that the outbox
does not capture. The reconciler operates at the data layer, not the behaviour layer.

---

## PII handling, encryption, and HSM-backed secrets are out of scope

All seeded data is synthetic. The repository ships with hardcoded development credentials in
`docker-compose.yml`. It does not address encryption at rest beyond SQL Server defaults, does not
configure TDE or column-level encryption, does not use HSM-backed or managed-identity credential
retrieval, and does not implement data masking, pseudonymisation, or any other PII-handling technique.
In a regulated production setting — ICO compliance under UK GDPR, FCA data handling rules, PCI-DSS
cardholder data requirements — these concerns would be mandatory and would significantly increase the
complexity of the migration. They are out of scope here because addressing them would require a
specific compliance context that cannot be generalised.

---

## Multi-region, write-conflict resolution, and schema evolution are not addressed

The dual-writer uses last-writer-wins conflict resolution within the dual-write window. This is
defensible when the dual-write window is short and write conflicts are rare. It is not defensible
in a multi-region active-active topology, during a schema evolution event, or in systems where
conflicting concurrent writes on the same record are a routine occurrence. The repository does not
address any of these scenarios. Schema evolution during cutover — adding or removing columns while
the dual-writer is active — is a particular risk not modelled here; the practical mitigation is to
freeze schema changes during the cutover window, which is noted in the runbook but not enforced.

---

## Performance numbers are bounded by the local Docker environment

The p99 latency thresholds and throughput figures asserted by the cutover test are measured against
containerised SQL Server on a developer machine. Docker networking, containerised SQL Server I/O,
and the absence of connection pooling tuning for production workloads all affect the numbers. The
figures are reproducible within the Docker environment but are not comparable to numbers from a
production Azure SQL Managed Instance with a properly sized connection pool, correct indexing, and
a co-located application layer.
