# Security

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting feature:
[https://github.com/cmonney/zero-downtime-migration-toolkit/security/advisories/new](https://github.com/cmonney/zero-downtime-migration-toolkit/security/advisories/new)

Do not open a public issue for a security vulnerability.

Expected response: acknowledgement within five working days, an initial assessment within ten.

---

## Scope

**In scope:**

- Vulnerabilities in the reconciliation engine, dual-writer, or strangler API that could cause data
  loss or silent divergence in a deployment derived from this repository.
- Dependency vulnerabilities with a plausible exploitation path in the context of this codebase.
- Credential exposure in code or configuration files committed to the repository (other than the
  intentional development credentials described below).

**Out of scope:**

- Vulnerabilities in SQL Server itself — report those to Microsoft.
- Vulnerabilities requiring physical or network access to the Docker host.
- Findings from automated scanners applied to the repository without contextual analysis.
- Reports that describe a risk already explicitly documented in `LIMITATIONS.md` or `SECURITY.md`.

---

## Development credentials

`docker-compose.yml` contains hardcoded SQL Server SA passwords and connection strings for local
development use. These are not secrets. They are intentionally visible, they use weak passwords
suitable only for a loopback development environment, and they are documented here so that automated
credential-scanning tools do not generate false-positive vulnerability reports. They must never be
used in any environment accessible over a network.

---

## PCI-DSS and regulatory scope

This repository is not in PCI-DSS scope. It contains no real cardholder data, no real personally
identifiable information, and no real payment instruments. All data is synthetic and seeded for
demonstration purposes only. The repository is therefore not subject to PCI-DSS controls, nor does
it purport to implement controls suitable for a regulated production environment. See `LIMITATIONS.md`
for a fuller discussion.

---

## CodeQL scanning

The repository runs CodeQL static analysis for C# on every pull request and on a weekly schedule.
Results are visible in the repository's Security tab. Known false positives are documented inline
with suppression justifications.
