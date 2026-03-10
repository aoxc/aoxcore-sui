<div align="center">

<a href="https://github.com/aoxc/aoxcore-sui">
  <img src="logos/aoxc_transparent.png" alt="AOXC Logo" width="180" />
</a>

# 🌐 AOXC Sui Protocol
### Enterprise Infrastructure for Sui-Native Assets and Governance

[![Network](https://img.shields.io/badge/Network-Sui%20Mainnet-blue?style=for-the-badge&logo=sui)](https://sui.io)
[![Security](https://img.shields.io/badge/Security-Audit_In_Progress-gold?style=for-the-badge&logo=shield)](docs/AUDIT_NOTES.md)
[![Status](https://img.shields.io/badge/Status-Phase--3_Active-orange?style=for-the-badge)](docs/ROADMAP_2026.md)

**AOXC Sui Protocol** is a modular infrastructure stack designed for secure asset management, verifiable governance, and deterministic cross-chain coordination within the Sui ecosystem.

> **Institutional Notice**  
> This repository is currently undergoing active development and security hardening.  
> Core modules are functional, while architecture stabilization, internal audits, and operational safeguards continue to evolve toward production readiness.

</div>

---

# Overview

AOXC Sui Protocol provides a high-integrity framework for managing Sui-native digital assets under deterministic governance and security guarantees.

The system integrates:

- object-centric asset custody
- governance primitives with multi-layer safeguards
- structured bridge payload validation
- autonomous treasury distribution logic
- AI-assisted operational intelligence

The architecture is designed to preserve protocol integrity while supporting long-term extensibility.

---

# Key Capabilities

### Object-Centric Asset Model

Assets are implemented as strongly typed Sui objects ensuring deterministic ownership, traceability, and composability.

### Governance Infrastructure

DAO governance with timelock enforcement, multi-signature controls, and veto authority for protocol safety.

### Treasury Automation

Rule-based treasury operations managing `Coin<T>` vault distribution and policy-constrained allocations.

### Cross-Chain Coordination

Typed bridge payload structures designed to reduce ambiguity in cross-chain asset operations.

### AI-Augmented Operations

Operational intelligence modules designed to support governance analysis while remaining policy-constrained.

---

# Repository Architecture

The repository is organized around modular Move packages.

## Protocol Modules (`/sources`)

Core protocol logic implemented using the Move programming language.

Primary modules include:

- asset object model
- governance infrastructure
- treasury vault systems
- reputation scoring mechanisms
- protocol circuit breakers
- bridge payload validation

Each module is designed with strict type safety and explicit ownership semantics.

---

## Documentation (`/docs`)

Technical documentation and operational specifications, including the project whitepaper.

Key documents include:

- threat modeling and attack surface evaluation
- formal protocol invariants
- release verification procedures
- indexer operational runbooks
- architecture specifications
- whitepaper (vision, security posture, roadmap to production)
- future readiness plan (audit closure + crypto agility roadmap)
- code audit report (module-by-module findings and action plan)

---

## AI Integration (`/ai`)

Supporting documentation and technical specifications for AI-assisted operational systems interacting with protocol governance.

---

# Repository Structure

```
aoxcore-sui/
│
├─ sources/              # Move protocol modules
│
├─ docs/                 # Technical specifications
│
├─ ai/                   # AI integration documentation
│
├─ Move.toml
└─ README.md
```

---

# Phase-3 Implementation Focus

Current development emphasizes protocol resilience and operational correctness.

## Circuit Breaker

Emergency protocol safety mechanism capable of halting critical operations when invariant violations are detected.

Implementation:

```
sources/circuit_breaker.move
```

---

## Typed Bridge Payloads

Structured payload types replace raw byte-level transfer logic, enabling safer cross-chain message verification.

Implementation:

```
sources/bridge_payload.move
```

---

## Real-Asset Treasury

Vault infrastructure managing `Coin<T>` assets under rule-based distribution policies.

Implementation:

```
sources/treasury.move
```

---

## Neural Staking

Advanced staking model enabling:

- automated compounding
- slashing logic
- reputation-linked reward flows

---

## AI Marketplace

Decentralized dataset and model licensing infrastructure enabling AI data routing through Walrus storage protocols.

---

# Protocol Modules

## AOXC Core Object Model

```
sources/aoxc.move
```

Defines the neural asset object model with cryptographic lineage guarantees.

Features include:

- asset provenance
- deterministic ownership transfer
- composable protocol extensions

---

## Sentinel DAO Governance

```
sources/sentinel_dao.move
```

Institutional governance module implementing:

- timelocked governance execution
- multi-signature emergency veto
- policy-constrained administrative actions

---

## Reputation Engine

```
sources/reputation.move
```

On-chain scoring system aggregating:

- governance participation
- cross-protocol attestations
- trust signals for protocol operators

---

# Security & Audit Framework

Protocol security is enforced through layered validation strategies.

Security components include:

- formal invariant verification
- threat modeling
- release gate validation
- deterministic state transitions
- circuit breaker enforcement

---

## Audit Documentation

| Document | Focus | Status |
|--------|--------|--------|
| Threat Model | Attack surface analysis | Active |
| Release Checklist | Deployment verification | Mandatory |
| Formal Invariants | Protocol logic constraints | In Review |
| Indexer Runbook | Operational reconciliation | Draft |

Documentation is located within:

```
docs/
```

---

# Development Environment

To work with the protocol locally, install the Sui toolchain.

Requirements:

- Sui CLI
- Rust toolchain
- Git

Install Sui:

```
cargo install --locked --git https://github.com/MystenLabs/sui.git sui
```

Verify installation:

```
sui --version
```

---

# Building the Protocol

Compile Move modules:

```
sui move build
```

Run tests:

```
sui move test
```

---

# Deployment

Deployment instructions and environment preparation guidelines are documented in:

```
docs/DEPLOYMENT.md
```

Deployment includes:

- package compilation
- object publishing
- capability assignment
- governance initialization

---

# Development Workflow

Typical development cycle:

1. implement protocol changes
2. update Move module tests
3. verify invariants
4. run local simulation
5. open pull request
6. security review and merge

All protocol changes must maintain invariant integrity.

---

# Documentation

Strategic documentation is available in the `/docs` directory.

Key documents include:

- Architecture Overview
- Protocol Economy Model
- Gap Analysis
- AI Integration Framework

---

# License

This project is licensed under the MIT License.

See the `LICENSE` file for details.

---

<div align="center">
  <sub>© 2026 AOXC Protocol | Secure. Auditable. Intelligent.</sub>
</div>
