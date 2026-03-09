# AOXC Sui Protocol

Enterprise-grade, Sui-native protocol stack for AOXC with auditable cross-chain controls, real asset treasury custody, and hybrid AI/community governance.

## Phase-2A Operational Excellence Highlights

- **Typed bridge payloads:** `sources/bridge_payload.move` replaces raw command bytes with structured bridge/governance payloads.
- **Unified circuit breaker:** `sources/circuit_breaker.move` remains the single source of truth for protocol pause state.
- **Real-asset treasury:** `sources/treasury.move` stores/distributes real `Coin<T>` value via `Balance<T>` vault custody.
- **Reputation proof link:** `sources/reputation.move` requires relay attestations from `sources/relay.move` before score updates.
- **Expanded tests:** `tests/phase1_negative_tests.move` + `tests/full_flow_tests.move` add invariant and typed-flow coverage.
- **Observability pack:** `docs/EVENT_MAP.md` defines indexer-friendly event contracts.

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

See `docs/AUDIT_NOTES.md`, `docs/SPEC.md`, and `docs/EVENT_MAP.md` for audit, operations, and observability details.
