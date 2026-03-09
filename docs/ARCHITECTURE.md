# AOXC Sui Architecture (Enterprise Overview)

## 1) Control Plane
- `bridge_payload.move`: versioned + typed payload schema, explicit decoding, EVM chain validation, target whitelist.
- `neural_bridge.move`: signature/replay verification, attestor quorum enforcement, command settlement.
- `sentinel_dao.move`: timelock + veto + guardrail policy enforcement, Tier-2 critical update wait windows.
- `circuit_breaker.move`: single global liveness gate.

## 2) Value Plane
- `treasury.move`: real `Coin<T>` custody + fair batch distribution + scalable Merkle claims.
- `aoxc.move`: neural asset objects, metadata/display hooks, checksum-governed branding updates.

## 3) Trust/Identity Plane
- `reputation.move`: score registry and relay-attested updates.
- `relay.move`: public report anchoring + N-of-M attestor quorum policy.

## 4) Security Model (At a Glance)
- Replay lock at bridge command digest layer.
- Unified pause gate for all critical transfer/distribution paths.
- Attestor quorum threshold for bridge/report critical flows.
- DAO policy limits reduce governance abuse blast radius.
- Checksum-governed branding mutation with DAO co-authorization.

## 5) Formal Security and Operations
- Move spec blocks in critical modules (`neural_bridge.move`, `treasury.move`) define formal safety intent.
- Event contracts: `docs/EVENT_MAP.md`
- Indexer and incident runbooks: `docs/INDEXER_RUNBOOK.md`
- Formal invariants and runbook: `docs/SPEC.md`
