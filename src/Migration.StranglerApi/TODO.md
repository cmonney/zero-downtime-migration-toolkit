# src/Migration.StranglerApi — TODO

## What this folder will contain

The ASP.NET Core 10 minimal API that is the sole entry point for all callers throughout the
cutover. This project implements the four-phase routing logic, the feature-flag read/write
mechanism (initially backed by an in-memory store; switchable to an external store without a
restart), the shadow-compare logic that records discrepancies during Phase B, and the hosted
service that runs the dual-writer relay during Phase C.

The API surface mirrors the canonical domain model in Migration.Contracts. It does not expose
source-specific or target-specific types. Mapping between canonical types and source-specific
entity models is done in this layer's service classes, not in the data access layers.

The strangler API must be deployable as a Docker container. A `Dockerfile` will sit in this
directory alongside the application code.

## Acceptance criteria

- `GET /health` returns 200 with a body indicating the current cutover phase and the status of
  each database connection.
- `GET /phase` returns the current `CutoverPhase` value.
- `POST /phase` accepts a new `CutoverPhase` value and transitions the routing logic at runtime
  without a service restart.
- All CRUD endpoints for the canonical entity types work correctly under each of the four phases,
  evidenced by the integration test suite.
- During Phase B, shadow-compare discrepancies are emitted as structured log events with a
  `shadow-compare-failure` category, consumable by the cutover test.
- The API starts cleanly from `docker compose up` once the init scripts and healthchecks are wired.

## Build order

Build after: Migration.Contracts, Migration.SourceA, Migration.SourceB, Migration.Target,
Migration.DualWriter.
Build before: tests (all test projects depend on this service either directly or via the
running Docker container).
