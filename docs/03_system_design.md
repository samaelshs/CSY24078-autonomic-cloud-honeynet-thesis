# System Design & Core Architectural Pillars

## 1. Autonomic MAPE-K Control Loop

The platform implements an autonomic closed feedback loop based on the classic MAPE-K model (Monitor, Analyze, Plan, Execute over Shared Knowledge). The goal is to detect attacks against decoy endpoints and autonomously mutate cloud boundary policies in real time without human intervention.

┌─────────────────────────────────────────────────────────────┐
│ SHARED KNOWLEDGE (K) │
│ • Quarantined IP State Table & Threat Intelligence IOCs │
│ • Active Decoy Topology & Allocated Subnet Allocations │
│ • Azure Resource Model / Terraform State Metadata │
└───────▲─────────────────▲─────────────────▲─────────────────┘
│ Reads/Writes │ Reads/Writes │ Reads/Writes
┌───────┴────────┐ ┌──────┴────────┐ ┌──────┴────────┐
│ 1. MONITOR │ │ 2. ANALYZE │ │ 3. PLAN │
│ (Data Capture) │─┼► (Evaluation) │─┼► (Resolution) │
└────────────────┘ │ └─────────────┘ │ └─────────────┘
▲ │ │ │
Sensors / │ └─────────────────┘ │ Action Payload
Telemetry │ ▼
┌──────────────┴──────────────────────────────┐ ┌────────────┴────────┐
│ Managed Cloud Environment │ │ 4. EXECUTE │
│ (Decoy VMs, NSG Flow Logs, Ingress Traps) │◄┼─ (API Mutation) │
└─────────────────────────────────────────────┘ └─────────────────────┘

-### Stage Breakdown

| Stage             | Function                                                           | Technical Implementation                                                                                                                                                                                                                                                                                                   |
| :---------------- | :----------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Monitor (M)**   | Continuous telemetry ingestion across all network traps and hosts. | Telemetry flows into an Azure Log Analytics Workspace via Data Collection Rules (DCRs). Ingestion feeds include Cowrie/Dionaea honeypot auth events, Linux syslogs, and Network Security Group (NSG) Flow Logs. The daemon extracts records programmatically using the Python `LogsQueryClient` with targeted KQL queries. |
| **Analyze (A)**   | Pattern recognition and anomaly classification.                    | Scans incoming telemetry streams for attacker signatures: brute-force spikes, repetitive port sweeps, or suspicious attempts to reach private RFC 1918 addresses. Telemetry hits are cross-referenced with internal decoy event logs to confirm malicious intent.                                                          |
| **Plan (P)**      | Dynamic mitigation synthesis.                                      | Translates detected threats into explicit infrastructure actions. The engine inspects current NSG state in the Knowledge Base, locates the next available high-priority slot (typically Priority 100–120), and generates the required REST JSON payload for an immediate `Deny` rule.                                      |
| **Execute (E)**   | Effector dispatch and boundary enforcement.                        | Transmits the generated rule payload to the Azure Resource Manager (ARM) API via the Python SDK (`NetworkManagementClient.security_rules.begin_create_or_update`). Runs as an asynchronous Long-Running Operation (LRO) to apply perimeter containment immediately.                                                        |
| **Knowledge (K)** | Central operational state store.                                   | Maintains runtime system context: active honeynet subnets, mapped decoy endpoints, known attacker session states, historical indicators of compromise (IOCs), and local copies of the active Terraform state.                                                                                                              |

---

## 2. Network Topology & Micro-Segmentation

The deception network is deployed within a dedicated virtual network (`10.0.0.0/16`) engineered to attract and isolate adversarial traffic while preventing lateral movement or outbound weaponization.

> **Azure Subnet Addressing Note:** Azure reserves five IP addresses across every subnet: Network (`.0`), Default Gateway (`.1`), DNS mapping (`.2`, `.3`), and Broadcast (`.255`). For standard `/24` subnets, 251 usable host IPs remain (`.4` through `.254`).

### Subnet Allocations

- **`snet-inspection` (`10.0.100.0/24`):** Dedicated segment for network virtual appliances (NVAs) and centralized traffic inspection before packets reach or leave backend decoys.
- **`snet-decoys-linux` (`10.0.1.0/24`):** Hosts Linux-based deception systems, including containerized Cowrie honeypots exposing SSH and Telnet services directly to inbound scanners.
- **`snet-decoys-win` (`10.0.2.0/24`):** Hosts Windows Server decoy instances emulating common enterprise attack surfaces (RDP, SMB). Functions primarily as an internal tripwire to catch pivot attempts originating from the Linux subnet.

### Traffic Control & Boundary Enforcement

#### Forced Tunneling via User-Defined Routes (UDR)

Decoy subnets have a custom Route Table associated with them that overrides the Azure default `0.0.0.0/0 -> Internet` route. Instead, all outbound traffic is routed to `VirtualAppliance` at the inspection interface (`10.0.100.4`) or blackholed entirely. This prevents compromised honeypot nodes from participating in external DDoS attacks, scanning third-party infrastructure, or establishing unauthorized Command and Control (C2) callbacks.

#### Dual-Tier Network Security Group (NSG) Policies

- **Inbound Access:** Common deception ports (22, 80, 445, 3389) are open by default. Dynamically injected quarantine rules created by the MAPE-K daemon occupy high-priority slots (Priority 100+), allowing them to instantly preempt lower-priority allow rules.
- **Outbound Isolation:** Explicit egress deny rules block all outbound traffic targeting private IP spaces (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`), eliminating lateral movement if a node is breached.
- **IMDS Protection:** An explicit egress drop rule blocks all traffic to `169.254.169.254/32` on port 80 from decoy nodes, stopping attackers from querying host metadata.

---

## 3. Identity Architecture & Zero Trust Model

The design strictly decouples the **Identity Plane** (Microsoft Entra ID), the **Control Plane** (Azure Resource Manager), and the **Data Plane** (VM workloads and honeynet network traffic).

┌─────────────────────────────────────────────────────────────┐
│ 1. LOCAL VM RUNTIME (Decoy Host / Autonomic Daemon) │
│ • Python SDK invokes DefaultAzureCredential() │
│ • Dispatches GET request to link-local IP: │
│ http://169.254.169.254/metadata/identity/oauth2/token │
│ Header: Metadata: true │
└─────────────────────────────┬───────────────────────────────┘
│ Intercepted locally in memory (vSwitch)
▼
┌─────────────────────────────────────────────────────────────┐
│ 2. AZURE HOST HYPERVISOR & ENTRA ID (Identity Plane) │
│ • Hypervisor validates platform PKI identity │
│ • Entra ID issues signed Bearer JWT (oid claim) │
│ • Token delivered back to VM socket │
└─────────────────────────────┬───────────────────────────────┘
│ Authorization: Bearer
▼
┌─────────────────────────────────────────────────────────────┐
│ 3. AZURE RESOURCE MANAGER (Control Plane Gateway) │
│ • AuthN: Validates JWT signature against Entra JWKS │
│ • AuthZ: Evaluates Azure RBAC table for oid on scope │
└─────────────────────────────────────────────────────────────┘

### Core Identity Mechanics

#### Secretless Authentication via User-Assigned Managed Identity

All autonomic scripts and daemons authenticate without using hardcoded passwords, static client secrets, or disk-bound service principal credentials. We use User-Assigned Managed Identities so the identity's lifecycle remains decoupled from individual host VMs, allowing decoy infrastructure to be rebuilt via Terraform without breaking role bindings.

#### IMDS Interaction & SSRF Protection

1. Runtimes call `DefaultAzureCredential()`, which dispatches a link-local HTTP request to `http://169.254.169.254/metadata/identity/oauth2/token`.
2. The packet is intercepted directly in hypervisor memory by the host virtual switch (vSwitch) and never traverses an external wire.
3. The request requires the HTTP header `Metadata: true`. This prevents exploitation through standard Server-Side Request Forgery (SSRF), as generic proxy requests and URL-injection attacks typically omit custom headers.
4. Entra ID verifies the underlying VM instance platform PKI and returns a short-lived JSON Web Token (Bearer JWT) containing the identity's Object ID (`oid`).

#### Scoped Azure RBAC Assignments

The identity assigned to the MAPE-K daemon adheres strictly to least privilege, scoped exclusively to the project's resource group (`rg-honeynet-core`):

- **`Network Contributor`:** Grants permission to write, update, and remove dynamic firewall rules on the decoy NSGs.
- **`Log Analytics Reader`:** Grants read-only access to query security telemetry and flow logs without providing any administrative control over the workspace or surrounding resources.
