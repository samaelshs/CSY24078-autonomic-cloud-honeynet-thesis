# Autonomic Cloud Honeynet

An autonomic, closed-loop cloud deception engine on Microsoft Azure implementing the MAPE-K architecture.

## Overview

The platform monitors ingress attacks against low- and high-interaction decoy subnets, analyzes threat telemetry in real time via Kusto Query Language (KQL), and programmatically plans and executes edge containment mutations using the Azure Python SDK to isolate malicious actors.

## Core Architecture

- **Monitor (M):** Log Analytics workspace ingesting Cowrie/Dionaea logs, syslog, and NSG flow logs.
- **Analyze (A):** Heuristics engine detecting persistent scans, brute force, and lateral movement attempts.
- **Plan (P):** Dynamic priority and rule-synthesis engine generating least-privilege ARM payloads.
- **Execute (E):** Asynchronous Python daemon invoking Azure REST APIs via `azure-mgmt-network`.
- **Knowledge (K):** Shared state tracking active attacker sessions, network topology, and state cache.

## Project Structure

```text
├── daemon/       # Python autonomic engine (Analyze/Plan/Execute runtimes)
├── docs/         # Thesis documentation, specifications, and evaluation logs
├── infra/        # Terraform blueprints (Azure VNet, subnets, NSGs, decoy nodes)
└── telemetry/    # Sentinel/Log Analytics KQL detection rules and log fixtures
```
