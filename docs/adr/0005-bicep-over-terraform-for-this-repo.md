# ADR 0005 — Bicep Over Terraform for This Repository

**Status:** Accepted

---

## Context

The repository requires infrastructure-as-code for the Azure components: SQL Managed Instance for
the three databases, AKS for the strangler API and load generator, and an observability stack. The
choice of IaC tooling is a positioning decision as well as a technical one: the target audience for
the repository includes hiring managers and engineers at Azure-heavy organisations.

---

## Decision

Infrastructure is defined in Bicep, scaffolded in `infra/bicep/` but not made functional in the
MVP. Each `.bicep` file contains a header comment explaining what it would deploy. The Bicep
modules reflect a realistic Azure deployment topology for this class of workload.

---

## Consequences

Engineers accustomed to Terraform or Pulumi will find the IaC less familiar. This is an acceptable
trade-off: the repository's positioning is explicitly Azure-heavy, and Bicep signals correctly to
the organisations most likely to engage with it. Bicep's first-class Azure Resource Manager
integration and its tighter feedback loop with Azure's type system are genuine technical advantages
for Azure-only deployments.

Bicep modules are not functional in the MVP. The scaffolded files contain accurate comments about
what each module would deploy, which is sufficient for a reviewer to understand the intended Azure
topology without executing it.

---

## Alternatives Considered

**Terraform.** The obvious alternative. Rejected for this repository not on technical grounds —
Terraform is a sound choice for multi-cloud or mixed-cloud environments — but because the
repository's positioning does not benefit from the multi-cloud signal. Terraform would be the
correct choice if the repository were targeting DevOps or SRE roles with a multi-cloud scope.

**Pulumi.** Allows infrastructure to be defined in C#, which would be consistent with the
repository's primary language. Rejected: Pulumi is a niche choice relative to Bicep and Terraform
in the Azure market, and using it would require reviewers to learn a third IaC tool to evaluate
the infrastructure code. The benefit does not outweigh the friction.

**Portal click-ops with ARM template export.** Not considered. Exported ARM templates are not
maintainable IaC; they are a snapshot of a portal state.
