# tools/load-generator — TODO

## What this folder will contain

A synthetic load generator that drives HTTP traffic against the strangler API at a configurable
request rate, recording per-request latency and success or failure. The load generator is used by
the cutover SLO test to simulate continuous caller traffic throughout the full cutover sequence.

The load generator will be implemented as a .NET console application or as a class library
callable from the cutover test. It will support:

- Configurable request rate (requests per second, split between reads and writes).
- Configurable duration or run-until-cancelled mode.
- A randomised but deterministic entity payload generator seeded from a fixed value for
  reproducibility.
- Per-request latency recording (wall-clock time from request dispatch to response receipt).
- A structured summary report: total requests, failure count, p50/p95/p99 latency, requests per
  phase (if phase transition events are injected into the generator during a run).
- Graceful shutdown on cancellation, with a final report written to stdout and optionally to a
  JSON file.

## Acceptance criteria

- The load generator can drive at least 100 requests per second against a local Docker network
  without becoming the bottleneck in the cutover test (i.e., the latency it measures reflects
  the strangler API's latency, not the generator's own overhead).
- The structured summary report is consumable by the cutover SLO test's assertion logic.
- The generator can be started and stopped programmatically from within the cutover test.
- A standalone mode exists (`dotnet run -- --rps 50 --duration 60`) for manual use during
  development and runbook rehearsal.

## Build order

Build after: Migration.Contracts (to share entity types for payload generation).
Build before: Migration.Cutover.Tests (which uses the generator as a dependency).
This is one of the last tools to implement; build it after the strangler API is running locally.
