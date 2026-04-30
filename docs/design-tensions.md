# Design Tensions

Each section below describes a deliberate trade-off in the design of this repository. For each, the
tension is stated, the choice made is explained, and the conditions under which the opposite choice
would be correct are described. These are not post-hoc rationalisations; they are the actual
reasoning that drove each decision.

---

## Dual-write versus CDC

Change-data-capture is the architecturally cleaner approach to keeping a migration target in sync
with a live source. If SQL Server's CDC is enabled on the source, every committed change to a
tracked table produces a row in a change table, which a relay process can consume and apply to the
target. The dual-writer path disappears from the application entirely, and the strangler API becomes
a pure routing layer with no write-coordination responsibility.

The cost is operational: CDC requires a SQL Server Agent job and the CDC capture process to be
running and monitored; it requires care around source schema changes, because adding or dropping a
captured column requires reconfiguring the capture; and it introduces a separate operational surface
(the change tables) that must be sized and purged. For a migration that runs over days or weeks, the
CDC approach is almost certainly the right choice at scale. For a migration with a short, controlled
dual-write window — as this repository models — the transactional outbox is simpler to reason about,
requires no additional SQL Server configuration, and is fully testable in-process without a running
CDC capture process.

The opposite choice would be correct when: the source table volumes are high enough that the
dual-write path introduces unacceptable write latency; the cutover window is long enough that the
operational overhead of CDC is amortised; or when the source is not under the migration team's
control and the application code cannot be modified to embed the dual-writer.

---

## Per-row checksum versus row count plus sampling

Counting rows and sampling a percentage of them is fast and cheap, and it catches the most common
failure mode: bulk data loss. The argument for it is that in practice, systematic encoding drift or
precision loss is unlikely to affect more than a small fraction of rows, so a sampling approach will
catch it eventually with a sufficiently large sample.

The argument against it is that "eventually" and "with a sufficiently large sample" are imprecise
claims, and imprecise claims are not SLOs. The reconciler in this repository is designed to make a
categorical claim: given these eight drift categories, if the reconciler reports zero diffs, there
is no instance of any of these categories in the data. A sampling reconciler cannot make that
claim.

The cost is reconciliation time. On the seeded dataset in this repository, a full pass takes
seconds. On millions of rows it would require batching and incremental checkpointing, which is
more complex than the MVP implements. The limitations file acknowledges this. The design choice is
the right one for the correctness claim this repository makes; a different choice might be correct
for a higher-volume migration where continuous full reconciliation is impractical.

---

## Feature-flagged routing in-process versus a separate proxy

A routing proxy — NGINX, Envoy, a custom sidecar — can switch traffic between source and target
without touching the application, which is attractive for migrations wrapping a service whose code
cannot be modified. The proxy approach also separates routing concerns from application concerns,
which can make testing easier.

The strangler API here is written from scratch, so the constraint that drives the proxy choice does
not apply. Embedding the routing logic in the application gives access to the full application
context (connection strings, transaction scope, idempotency key generation) without requiring an
out-of-process coordination mechanism. It also makes the routing logic fully testable in-process:
the cutover integration test can flip phase flags and assert routing behaviour without spawning a
proxy process.

The proxy approach would be the correct choice when the application being strangled cannot be
modified — when it is a packaged commercial application, a legacy service with no accessible source
code, or a service owned by a different team. In those cases, the proxy is the strangler, and the
in-process approach is unavailable.

---

## Two source databases versus one

The harder question is why two sources rather than one, given that two sources doubles the seeding
work and the reconciler complexity. The answer is that consolidating two databases is the problem
the author has solved in production, not a variation on consolidating one. The two sources model a
real class of decision: when two systems have been managing overlapping domains independently for
years, they diverge in ways that a single migration cannot capture. The customer record in Source A
and the account record in Source B both represent the same legal entity, but they use different IDs,
different name fields with different Unicode behaviour, and different representations of the same
address. Reconciling them into a single target row requires a canonicalisation step, not just a
copy. That canonicalisation step — represented in the reconciler as the modelling-difference drift
category — is absent in a single-source migration and present in a realistic consolidation.

---

## UK English in code comments versus accommodating mixed contributors

All documentation, commit messages, and code comments in this repository use UK English. This is a
deliberate signal: the author is based in the UK and targeting UK roles. It has a practical cost:
contributors from outside the UK may write "behavior" or "color" in a comment without noticing, and
the `.editorconfig` does not enforce prose spelling (no Roslyn analyser does). The cost is tolerated
because the repository is not a community project seeking broad contribution; it is a reference
implementation whose primary audience is hiring managers and senior engineers evaluating the author's
work. Consistency of register is more important than accommodation of contributors in this context.
The CONTRIBUTING.md notes the UK English requirement and explains why.
