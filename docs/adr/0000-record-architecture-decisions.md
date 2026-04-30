# ADR 0000 — Record Architecture Decisions

**Status:** Accepted

---

## Context

Architectural decisions made during a migration project have a way of being forgotten or
misremembered. The reasoning behind a choice matters as much as the choice itself: a decision that
looks wrong in isolation often has a sound rationale that would be lost if only the outcome were
recorded. New contributors, reviewers, and the author returning after a period away need to
understand not just what was decided but why, and what alternatives were considered and rejected.

---

## Decision

Architecture decisions are recorded as short text files in `docs/adr/`, numbered sequentially from
0000. Each ADR uses the format introduced by Michael Nygard: Title, Status, Context, Decision,
Consequences, Alternatives Considered.

ADRs are immutable once accepted. If a decision is superseded, the original ADR's status is updated
to "Superseded by ADR NNNN" and a new ADR is written explaining the change in direction. ADRs are
never deleted.

---

## Consequences

The ADR archive grows over time. This is desirable: a long-lived project with many ADRs has a richer
design history than one with few. The cost is minor maintenance overhead when opening a PR that
introduces a new architectural decision. The CONTRIBUTING.md describes when an ADR is warranted.

---

## Alternatives Considered

**Inline comments in code.** Rejected: comments decay faster than decisions, are not indexed for
review, and are invisible to reviewers reading only the documentation.

**A wiki or Notion page.** Rejected: external documentation is not co-located with the code,
is not version-controlled alongside changes, and is inaccessible to offline reviewers.

**No formal record.** Rejected: this is a public reference repository. The design decisions must
be legible to a reviewer who has no access to the author.
