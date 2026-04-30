# tools/chaos — TODO

## What this folder will contain

A chaos injection tool for use in Phase 2 of the roadmap. In the MVP, chaos is seeded at database
initialisation time (drift in the source data). In Phase 2, this tool will introduce runtime chaos
during a live cutover run to test the resilience of the strangler API, dual-writer, and reconciler
under adverse conditions.

Planned chaos modes:

- **Network latency injection** between the strangler API container and the database containers,
  using `tc netem` or a proxy such as Toxiproxy.
- **Packet loss** on the source-to-target relay path, to simulate an unreliable connection between
  the dual-writer and the target database.
- **Container restart** of one database service mid-cutover, to verify that the outbox relay
  correctly recovers and replays from the high-water mark without duplicate application.
- **Slow query injection** by introducing a long-running query on a source database, to verify
  that the reconciler's batched reader handles lock contention without deadlocking.

## Acceptance criteria (Phase 2)

The cutover SLO test continues to pass — within relaxed but defined SLO thresholds — when each
chaos mode is active. The relaxed thresholds are documented in the chaos tool's configuration
and justified in terms of what a real network or hardware event would produce.

## Build order

This tool is Phase 2 and should not be started until the cutover SLO test passes reliably without
chaos. Implement after all MVP components are complete and the nominal cutover test passes on a
clean run at least five consecutive times.
