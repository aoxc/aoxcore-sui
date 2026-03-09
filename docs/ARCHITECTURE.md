# AOXC Sui Architecture (Enterprise Overview)

## 1) Control Plane
- `bridge_payload.move`: versioned + typed payload schema, explicit decoding, EVM chain validation, target whitelist.
- `neural_bridge.move`: signature/replay verification, active-attestor filtering, quorum-epoch enforcement, command settlement.
- `sentinel_dao.move`: timelock + veto + guardrail policy enforcement, Tier-2 critical update wait windows.
- `circuit_breaker.move`: single global liveness gate.

## 2) Value Plane
- `treasury.move`: real `Coin<T>` custody + fair batch distribution + scalable Merkle claims.
- `aoxc.move`: neural asset objects, metadata/display hooks, checksum-governed branding updates.
- `staking.move`: liquid staking pool with slash and auto-compounding telemetry.
- `liquidity_manager.move`: external DEX route surface (Cetus/Hop) with pause-aware controls.
- `marketplace.move`: Walrus-linked AI dataset listing/licensing primitives.

## 3) Trust/Identity Plane
- `reputation.move`: score registry and relay-attested updates.
- `relay.move`: public report anchoring + N-of-M attestor quorum lifecycle (add/remove/disable/epoch).

## 4) Security Model (At a Glance)
- Replay lock at bridge command digest layer.
- Unified pause gate for all critical transfer/distribution paths.
- Attestor quorum threshold for bridge/report critical flows.
- DAO policy limits reduce governance abuse blast radius.
- Checksum-governed branding mutation with DAO co-authorization.

## 6) Brand Governance
- `aoxc::BrandManifest` and `reputation::ReputationManifest` are shared, versioned manifest objects.
- Any logo mutation requires DAO co-signing and appends a release hash to immutable changelog history.
- Wallet-facing display profiles are synchronized from the current manifest version.

## 5) Formal Security and Operations
- Move spec blocks in critical modules (`neural_bridge.move`, `treasury.move`) define formal safety intent.
- Event contracts: `docs/EVENT_MAP.md`
- Indexer and incident runbooks: `docs/INDEXER_RUNBOOK.md`
- Formal invariants and runbook: `docs/SPEC.md`
