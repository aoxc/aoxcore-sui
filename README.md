<div align="center">

<a href="https://github.com/aoxc/aoxcore-sui">
  <img src="logos/aoxc_transparent.png" alt="AOXC Logo" width="180">
</a>

# 🌐 AOXC Sui Protocol
### Enterprise-grade Sui-native Protocol Stack

[![Network](https://img.shields.io/badge/Network-Sui%20Mainnet-blue?style=for-the-badge&logo=sui)](https://sui.io)
[![Security](https://img.shields.io/badge/Security-Audited-success?style=for-the-badge&logo=shield)](docs/AUDIT_NOTES.md)
[![Status](https://img.shields.io/badge/Status-Phase--3-orange?style=for-the-badge)](docs/ROADMAP_2026.md)

---

**AOXC** is a high-integrity protocol stack featuring auditable cross-chain controls, 
real-asset treasury custody, and hybrid AI/Community governance.

</div>

## 🛡️ Quick Audit Navigation

| Document | Purpose |
| :--- | :--- |
| 🔍 [Threat Model](docs/THREAT_MODEL.md) | Attack surface and mitigations |
| ✅ [Release Checklist](docs/RELEASE_CHECKLIST.md) | Pre-mainnet security gates |
| 📐 [Formal Invariants](docs/SPEC.md) | Mathematical verification rules |
| ⚙️ [Indexer Runbook](docs/INDEXER_RUNBOOK.md) | Operational reconciliation |

---

## 🚀 Phase-3 Technical Highlights

* **🛡️ Circuit Breaker:** Unified protocol liveness and emergency pause controls in `sources/circuit_breaker.move`.
* **⛓️ Typed Bridge:** `sources/bridge_payload.move` replaces raw bytes with structured, secure payloads.
* **💰 Real-Asset Treasury:** Direct `Coin<T>` vault custody with autonomous distribution via `sources/treasury.move`.
* **🤖 Neural Staking:** Liquid staking with slash mechanisms and auto-compound hooks.
* **🌐 AI Marketplace:** Walrus-linked dataset licensing and economic layer via `sources/marketplace.move`.

---

## 📦 Core Modules & Documentation

### 🏛️ Protocol Core
* `sources/aoxc.move` — Neural asset object model with security lineage.
* `sources/sentinel_dao.move` — Timelock and veto-enabled governance.
* `sources/reputation.move` — Reputation profiles linked to relay attestations.

### 📚 Technical Pack
* **[Architecture](docs/ARCHITECTURE.md)** — Enterprise module topology and trust planes.
* **[Economy](docs/ECONOMY.md)** — Phase-5 Neural Economy specifications.
* **[Gap Analysis](docs/GAP_ANALYSIS.md)** — Technical and operational gap analysis.
* **[AI Layer](ai/INTEGRATION.md)** — XLayer + Sui + Walrus AI compatibility flow.

---

<div align="center">
  <sub>© 2026 AOXC Protocol | Secure. Auditable. Intelligent.</sub>
</div>
