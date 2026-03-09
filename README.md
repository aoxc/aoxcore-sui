# AOXC Sui Protocol

![AOXC Logo](logos/aoxc-token.png)

Enterprise-grade, Sui-native protocol stack for AOXC with auditable cross-chain controls, real asset treasury custody, and hybrid AI/community governance.

## Quick Audit Navigation

- Threat model: `docs/THREAT_MODEL.md`
- Release gate checklist: `docs/RELEASE_CHECKLIST.md`
- Formal invariants: `docs/SPEC.md`
- Operational reconciliation: `docs/INDEXER_RUNBOOK.md`

## Phase-3 Cross-Chain & Formal Security Highlights

- **Typed bridge payloads:** `sources/bridge_payload.move` replaces raw command bytes with structured bridge/governance payloads.
- **XLayer readiness:** EVM chain-id + xlayer sender validation for cross-chain payload integrity.
- **Attestor quorum:** N-of-M trust model for relay/bridge critical validations.
- **Command-target binding:** bridge command `target` field must match typed payload target module.
- **Explicit decoding:** strict `vector<u8>` decoding helpers for Pause/Resume/FundUpdate and governance actions.
- **Unified circuit breaker:** `sources/circuit_breaker.move` remains the single source of truth for protocol pause state.
- **Real-asset treasury:** `sources/treasury.move` stores/distributes real `Coin<T>` value via `Balance<T>` vault custody.
- **Reputation proof link:** `sources/reputation.move` requires relay attestations from `sources/relay.move` before score updates.
- **Expanded tests:** `tests/phase1_negative_tests.move` + `tests/full_flow_tests.move` add invariant and typed-flow coverage.
- **Scenario war-game tests:** `tests/scenario_tests.move` adds `sui::test_scenario`-based E2E rejection simulations.
- **Governance guardrails:** DAO now enforces policy limits (timelock bounds, cooldown, max fund delta).
- **Scalable treasury claims:** Merkle-claim mode (`publish_merkle_root` / `claim_reward`) for large recipient sets.
- **Neural staking:** liquid staking + slash + auto-compound foundations in `sources/staking.move`.
- **Yield hooks:** treasury lending/liquidity allocation policy and rebalance telemetry.
- **Liquidity hub:** Cetus/Hop route layer in `sources/liquidity_manager.move`.
- **AI marketplace base:** Walrus-linked dataset listing and license checks via `sources/marketplace.move`.
- **Observability pack:** `docs/EVENT_MAP.md` defines indexer-friendly event contracts.
- **Visual branding hooks:** `aoxc.move` and `reputation.move` include logo-backed display profiles tied to `logos/`.
- **Branding integrity:** logo updates require DAO-admin authorization and checksum match.
- **Formal security hooks:** Move spec blocks added for critical modules to support prover-based verification workflows.

## Modules

- `sources/errors.move`: centralized abort code catalog.
- `sources/circuit_breaker.move`: unified protocol liveness state and pause/resume controls.
- `sources/bridge_payload.move`: typed payload schemas for bridge and DAO actions.
- `sources/neural_bridge.move`: bridge verifier with replay lock and signer checks; executes typed payload actions through circuit breaker.
- `sources/aoxc.move`: neural asset object model with security lineage and status controls.
- `sources/reputation.move`: reputation profiles linked to relay proof attestations.
- `sources/treasury.move`: `Coin<T>`-backed autonomous treasury with score-gated distribution.
- `sources/sentinel_dao.move`: timelock + veto governance, now routed through the unified circuit breaker.
- `sources/relay.move`: Walrus report anchoring and attestation checks.
- `sources/staking.move`: neural staking pool with slash and auto-compound hooks.
- `sources/liquidity_manager.move`: DEX routing manager for swaps and LP flows.
- `sources/marketplace.move`: AI dataset marketplace foundation (Walrus + license).

See `docs/AUDIT_NOTES.md`, `docs/SPEC.md`, `docs/EVENT_MAP.md`, and `docs/INDEXER_RUNBOOK.md` for audit, operations, and observability details.


### Documentation Pack
- `docs/ARCHITECTURE.md` — enterprise module topology and trust planes.
- `docs/SPEC.md` — invariants and runbooks.
- `docs/AUDIT_NOTES.md` — phase progress and open gaps.
- `docs/EVENT_MAP.md` — indexer event contracts.
- `docs/INDEXER_RUNBOOK.md` — operations and reconciliation workflows.
- `docs/SECURITY_CHECKLIST.md` — pre-mainnet security gate.
- `docs/WALRUS_DIFFERENTIATION.md` — Walrus tabanlı farklılaşma sözleşmeleri ve AI-first entegrasyon önerileri.
- `docs/THREAT_MODEL.md` — tehdit modeli, saldırı yüzeyi ve azaltımlar.
- `docs/RELEASE_CHECKLIST.md` — release öncesi audit kapıları ve imza checklisti.
- `docs/ECONOMY.md` — Phase-5 Neural Economy katmanı.
- `docs/ROADMAP_2026.md` — 2026 hedef ve kilometre taşları.

### AI Compatibility Layer
- `ai/README.md` — AOXCAN AI klasörünün kapsamı.
- `ai/INTEGRATION.md` — XLayer + Sui + Walrus AI uyumluluk akışı.
