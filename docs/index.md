# Autonomic Cloud Deception: Developing an AI-Driven Honeynet for Proactive Threat Mitigation on Microsoft Azure

## Thesis Overview

- **Academic Level:** B.Sc. Computer Science Thesis
- **Target Launch:** October 2026
- **Primary Objective:** Design, deploy, and evaluate an autonomic, self-defending cloud deception platform on Microsoft Azure that dynamically detects, analyzes, and mitigates active cyber threats using a closed-loop control system.

## Architectural Summary

This project bridges cloud infrastructure-as-code, autonomous control loops, and cloud perimeter defense:

- **Autonomic Engine:** Implements the classic **MAPE-K** (Monitor, Analyze, Plan, Execute over Shared Knowledge) control loop to achieve automated threat detection and dynamic perimeter mutation.
- **Infrastructure-as-Code (IaC):** Declarative orchestration of Azure virtual networks, subnets, route tables, and decoy VMs using Terraform.
- **Telemetry & Analytics:** Ingestion of Layer 3/4 NSG flow logs, VM syslog, and honeypot interaction records into an Azure Log Analytics Workspace, processed via Kusto Query Language (KQL).
- **Automated Mitigation:** Headless Python daemons leveraging the Azure SDK (`azure-mgmt-network`) to execute real-time containment actions (NSG quarantine injection, route blackholing) without human intervention.
- **Zero Trust Governance:** Full platform-level identity decoupling using secretless Managed Identities and fine-grained Azure Role-Based Access Control (RBAC).

## Repository Organization

- `docs/`: Architectural specifications, formal related work, implementation ledgers, and evaluation methodology.
- `infra/`: Terraform modules and environment definitions for cloud infrastructure provisioning.
- `daemon/`: Python runtimes executing the MAPE-K Analyze, Plan, and Execute stages via Azure SDKs.
- `telemetry/`: Scheduled KQL queries, data collection rules (DCRs), and sample attacker telemetry logs.
