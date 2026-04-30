## What changed

<!-- Describe the change. One paragraph is usually sufficient. -->

## Why

<!-- Explain the motivation. Link to an issue if one exists. -->

## How it was tested

<!-- Describe how you verified the change: unit test, integration test,
     manual steps against a running Docker environment, etc. -->

## ADR impact

<!-- Does this change introduce or supersede an architectural decision?
     If yes, link to the new or updated ADR. If no, say so explicitly. -->

## Checklist

- [ ] All tests pass locally (`dotnet test`)
- [ ] `dotnet format --verify-no-changes` produces no output
- [ ] No new warnings have been introduced (build with `TreatWarningsAsErrors`)
- [ ] An ADR has been created or updated if an architectural decision was made
- [ ] The runbook has been reviewed and updated if the cutover sequence or rollback procedure changed
- [ ] `ROADMAP.md` has been updated if an MVP item has been completed or a Phase 2 item has changed scope
- [ ] UK English is used throughout (documentation, comments, identifiers where practical)
