# AOXC Sui Architecture (Enterprise Overview)

## 1) Control Plane
- `bridge_payload.move`: versioned + typed payload schema, explicit decoding, target whitelist.
- `neural_bridge.move`: signature/replay verification and command settlement.
- `sentinel_dao.move`: timelock + veto + guardrail policy enforcement.
- `circuit_breaker.move`: single global liveness gate.

## 2) Value Plane
- `treasury.move`: real `Coin<T>` custody + fair batch distribution + scalable Merkle claims.
- `aoxc.move`: neural asset objects, metadata/display hooks, security checkpoints.

## 3) Trust/Identity Plane
- `reputation.move`: score registry and relay-attested updates.
- `relay.move`: public report anchoring and attestation reference layer.

## 4) Security Model (At a Glance)
- Replay lock at bridge command digest layer.
- Unified pause gate for all critical transfer/distribution paths.
- DAO policy limits to reduce governance abuse blast radius.
- Checksum-governed branding mutation with DAO co-authorization.

## 5) Operational Surfaces
- Event contracts: `docs/EVENT_MAP.md`
- Indexer and incident runbooks: `docs/INDEXER_RUNBOOK.md`
- Formal invariants and runbook: `docs/SPEC.md`
