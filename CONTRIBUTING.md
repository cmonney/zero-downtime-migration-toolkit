# Contributing

Contributions are welcome, subject to the constraints below.

---

## Running the tests

```bash
# Start the database containers
docker compose up -d

# Unit tests (no containers required)
dotnet test tests/Migration.Reconciler.Tests

# Integration tests (containers must be running)
dotnet test tests/Migration.Integration.Tests

# Cutover SLO test (containers must be running, runs the full cutover sequence)
dotnet test tests/Migration.Cutover.Tests
```

The MVP implementation is not yet complete. See `ROADMAP.md` for the current state.

---

## Commit message convention

This repository uses [Conventional Commits](https://www.conventionalcommits.org/). The format is:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Common types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`.

Scopes map to the project names: `reconciler`, `dual-writer`, `strangler-api`, `contracts`,
`source-a`, `source-b`, `target`, `infra`, `docs`.

Example: `feat(reconciler): add normalisation rule for decimal scale drift`

---

## Branch model

Trunk-based development with short-lived feature branches. Branches should be merged or discarded
within two working days. Rebase onto `main` before opening a pull request; do not merge `main` into
a feature branch. Long-lived branches indicate a design problem that should be resolved in a
discussion first.

---

## Code style

Style is enforced by `.editorconfig` and `dotnet format`. Run `dotnet format` before committing.
The CI pipeline treats formatting violations as build failures. Do not suppress warnings without
adding a comment explaining why the suppression is justified.

---

## Architecture Decision Records

Add an ADR when:

- You are making a decision that will be difficult or costly to reverse.
- You are choosing between two or more technically reasonable alternatives.
- You are deferring something that might look like an oversight to a reviewer.

Do not add an ADR for implementation details or for decisions with an obvious single answer.

ADRs are numbered sequentially from 0000. Copy the format from an existing ADR. Never delete an
ADR; if a decision is superseded, update the existing ADR's status to "Superseded by ADR NNNN" and
create a new one.

---

## Pull request checklist

See `.github/PULL_REQUEST_TEMPLATE.md`. All items must be addressed before a PR is merged.
