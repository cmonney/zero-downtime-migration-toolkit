# tests/Migration.Cutover.Tests — TODO

## What this folder will contain

The cutover SLO test: the primary automated evidence for the zero-downtime claim. This test drives
the load generator against the strangler API throughout a full automated cutover sequence
(Phase A through Phase D) and asserts at every phase boundary that the SLOs have been met.

The test sequence is:

1. Start all three database containers (via Testcontainers or a pre-started Docker Compose
   environment). Seed the databases.
2. Start the load generator at the configured request rate (e.g., 50 writes per second, 50 reads
   per second, mixed entity types).
3. Assert Phase A baseline: load generator reports zero failures, p99 latency within SLO.
4. Transition to Phase B. Hold for the configured stabilisation period. Assert: zero
   shadow-compare failures, zero load generator failures, p99 within SLO.
5. Transition to Phase C. Hold for the configured stabilisation period. Assert: outbox lag
   reaches zero, reconciler reports zero diffs, zero load generator failures, p99 within SLO.
6. Transition to Phase D. Hold. Assert: all reads from target, sources read-only, zero load
   generator failures, p99 within SLO, reconciler final pass reports zero diffs.
7. Stop the load generator. Publish the summary report.

## Acceptance criteria

The test passes when, for a continuous run of at least 10 minutes spanning all four phases:

- Zero write failures are reported by the load generator (HTTP 5xx or connection timeout).
- The reconciler reports zero diffs in the final pass after Phase D is entered.
- p99 request latency, as measured by the load generator, does not exceed the configured SLO
  threshold (default: 200 ms at the Docker-local scale; this value is documented and justified
  in the test configuration, not hardcoded).
- The test produces a structured summary report (JSON) recording: total requests, failure count,
  p50/p95/p99 latency per phase, reconciler diff count per phase boundary.

## Build order

Build last among test projects. Depends on: Migration.Cutover.Tests' own test infrastructure,
the load generator (tools/load-generator/), and a fully wired Docker Compose environment.
This is the final integration point; it cannot be written until all other components are
implemented and the integration tests pass.
