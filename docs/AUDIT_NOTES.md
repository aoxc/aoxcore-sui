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
13. Phase-3 quorum + XLayer payload compatibility + Tier-2 timelock controls integrated.

## Phase-4 Delta (Immutable Standard)

1. **Production Merkle Verification**
   - `treasury::claim_reward` now verifies full sibling/path Merkle proofs.
   - Leaf hashing is domain-separated by `(epoch, user, amount, token_type)`.
2. **Quorum Lifecycle Governance**
   - `relay::AttestorQuorum` now tracks `epoch` and disabled attestors.
   - DAO/admin governance path can add/remove/disable attestors with threshold-safety checks.
   - `neural_bridge` command execution requires active quorum epoch alignment.
3. **Versioned Brand Manifest**
   - AOXC and Reputation branding moved to shared versioned manifest objects.
   - Logo updates require module cap + DAO cap + checksum match + release hash append.
4. **Scenario Extensions**
   - `tests/scenario_tests.move` now includes Merkle domain/path preview assertions and quorum lifecycle rule checks.

## Remaining High-Priority Work

1. Expand `sui::test_scenario` to full shared-object transfer/retrieve lifecycle with multi-actor tx hops.
2. Add event index schema and off-chain reconciliation playbook.
3. Add signer-rotation and key ceremony SOPs.

## Medium Priority

1. Add payload schema enforcement for bridge commands.
2. Add explicit governance proposal payload structs and typed decoding.
3. Introduce bounded relay retention policy and archival lifecycle.

## Strategic Differentiation Backlog

- Walrus + AI odaklı yeni sözleşme önerileri ve entegrasyon planı: `docs/WALRUS_DIFFERENTIATION.md`.

## Added Audit-Readiness Artifacts

- Threat model and attack-surface reductions: `docs/THREAT_MODEL.md`.
- Release-time hardening and sign-off controls: `docs/RELEASE_CHECKLIST.md`.

## Phase-5 Sovereign Ecosystem Delta

1. `staking.move` eklendi: slash limit kontrolleri + auto-compound event sözleşmesi.
2. `treasury.move` yield hook policy ve rebalance telemetry ile genişletildi.
3. `liquidity_manager.move` ile Cetus/Hop routing yüzeyi eklendi.
4. `marketplace.move` ile Walrus + lisans hash tabanlı dataset pazarının temeli atıldı.
5. Ekonomi mimarisi `docs/ECONOMY.md` ve 2026 hedefleri `docs/ROADMAP_2026.md` ile belgelendi.
