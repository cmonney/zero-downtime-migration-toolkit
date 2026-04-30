# infra/bicep — TODO

## What this folder will contain

Bicep modules defining the Azure infrastructure required to run the toolkit in a cloud environment.
The modules are scaffolded with comments and TODO markers but are not functional in the MVP. Each
module describes what it would deploy and what parameters it expects.

The intended topology is:

- `main.bicep`: top-level deployment, orchestrates the module calls and passes parameters.
- `modules/sql-managed-instance.bicep`: deploys three SQL Managed Instance databases (Source A,
  Source B, Target) in the same managed instance, with appropriate collation settings per database.
- `modules/aks.bicep`: deploys an AKS cluster to host the strangler API and the load generator as
  Kubernetes workloads.
- `modules/observability.bicep`: deploys an Application Insights workspace and wires it into the
  AKS workloads for structured telemetry from the cutover test.

## Acceptance criteria (Phase 2)

`az deployment group create --template-file infra/bicep/main.bicep --parameters @infra/bicep/main.parameters.json`
executed against a real Azure subscription produces a running instance of the full stack within 45
minutes, with all three databases accessible from the AKS-hosted strangler API and the cutover SLO
test passing against the cloud environment.

## Build order

Phase 2. Do not start Bicep implementation until the MVP runs cleanly under Docker Compose. The
Azure topology should mirror the Docker Compose topology exactly, making the Bicep modules a
straightforward translation of the local environment.
