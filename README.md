# AOXC Sui Protocol

Enterprise-grade, Sui-native protocol stack for AOXC with auditable cross-chain controls, real asset treasury custody, and hybrid AI/community governance.

## Phase-1 Hardening Highlights

- **Unified circuit breaker:** `sources/circuit_breaker.move` is now the single source of truth for protocol pause state.
- **Real-asset treasury:** `sources/treasury.move` now stores and distributes real `Coin<T>` value using `Balance<T>` vault custody.
- **Reputation proof link:** `sources/reputation.move` now requires relay attestations from `sources/relay.move` before updating score state.
- **Negative test suite:** `tests/phase1_negative_tests.move` introduces abort-focused invariants tests for all core modules.
- **Spec/runbook docs:** `docs/SPEC.md` captures invariants, emergency procedures, and module trust boundaries.

## Modules

- `sources/errors.move`: centralized abort code catalog.
- `sources/circuit_breaker.move`: unified protocol liveness state and pause/resume controls.
- `sources/neural_bridge.move`: bridge verifier with replay lock and signer checks; can trigger circuit-breaker actions from attested commands.
- `sources/aoxc.move`: neural asset object model with security lineage and status controls.
- `sources/reputation.move`: reputation profiles linked to relay proof attestations.
- `sources/treasury.move`: `Coin<T>`-backed autonomous treasury with score-gated distribution.
- `sources/sentinel_dao.move`: timelock + veto governance, now routed through the unified circuit breaker.
- `sources/relay.move`: Walrus report anchoring and attestation checks.

See `docs/AUDIT_NOTES.md` and `docs/SPEC.md` for audit and operations details.
