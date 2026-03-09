# AOXC Sui Protocol - Audit Notes

## Phase-1/2A Implemented

1. Unified circuit breaker module as single pause-state authority.
2. Real treasury custody with `Coin<T>` deposits and `Balance<T>` vault accounting.
3. Reputation updates linked to relay proof attestations.
4. Negative test suite for core abort/invariant checks.
5. Specification and emergency runbook documentation (`docs/SPEC.md`).
6. Typed payload schemas for bridge/DAO (`sources/bridge_payload.move`).
7. Observability event map for indexers (`docs/EVENT_MAP.md`).
8. Scenario-level war-game tests (`tests/scenario_tests.move`) with `sui::test_scenario`.
9. Operational runbook for indexer and incident drills (`docs/INDEXER_RUNBOOK.md`).
10. Governance policy guardrails (timelock bounds, cooldown, max fund delta).
11. Merkle claim mode for scalable treasury payouts.
12. Architecture and security checklist docs (`docs/ARCHITECTURE.md`, `docs/SECURITY_CHECKLIST.md`).

## Remaining High-Priority Work

1. Add scenario-level integration tests using `sui::test_scenario` for:
   - bridge halt -> asset transfer blocked,
   - DAO pause/resume with timelock,
   - reputation proof mismatch rejection in live object flow.
2. Add event index schema and off-chain reconciliation playbook.
3. Add signer-rotation and key ceremony SOPs.

## Medium Priority

1. Add payload schema enforcement for bridge commands.
2. Add explicit governance proposal payload structs and typed decoding.
3. Introduce bounded relay retention policy and archival lifecycle.
