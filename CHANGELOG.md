---

### File 2: `CHANGELOG.md`
Uses the standard [Keep a Changelog](https://keepachangelog.com/) format aligned with Conventional Commits[cite: 2, 9].

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Core VNet (`10.0.0.0/16`) and subnet architecture definitions (`infra/main.tf`).
- Reusable Terraform compute module for decoy instances (`infra/modules/decoy_node`).
- Python Azure SDK daemon skeleton for automated NSG rule injection (`daemon/`).

---

## [0.1.0] - 2026-09-14

### Added

- Initial project layout and directory scaffolding (`infra/`, `daemon/`, `telemetry/`, `docs/`).
- Remote Terraform state backend in Azure Storage Account (`rg-terraform-state` / `tfstate`) with blob lease locking.
- Baseline documentation skeletons (`docs/01_introduction.md` through `docs/06_conclusion.md`).
- Thesis system architecture design and MAPE-K diagram specification (`docs/03_system_design.md`).
- Local Python virtual environment with base Azure SDK management libraries (`azure-identity`, `azure-mgmt-network`).
- Root `.gitignore` enforcing secret isolation and state file exclusions.
