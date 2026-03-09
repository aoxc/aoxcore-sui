# AOXC Security Checklist (Pre-Mainnet)

## Contract Controls
- [ ] Bridge signer rotation procedure tested.
- [ ] Timelock/veto guardrails tested with `test_scenario` object flow.
- [ ] Circuit breaker pause/resume tested across bridge + DAO paths.
- [ ] Treasury solvency checks verified for batch and claim mode.
- [ ] Merkle claim replay prevention validated.

## Payload and Message Hygiene
- [ ] `schema_version` checks enforced for all decoded payloads.
- [ ] Target whitelist checks enforced (`circuit_breaker` vs `treasury`).
- [ ] Invalid decode paths covered by expected-failure tests.

## Reputation and Relay Integrity
- [ ] Reputation updates reject non-attested evidence.
- [ ] Relay report type enforcement + duplicate protection verified.

## Branding Integrity
- [ ] Logo checksum updates require module cap + DAO cap.
- [ ] Wallet-facing logo URIs immutable policy documented.

## Operations and Monitoring
- [ ] Event indexers track all critical events (bridge/dao/treasury/reputation).
- [ ] Incident drills executed (unexpected pause, drift, proof divergence).
- [ ] Release notes include parser compatibility impact.

## Quorum & Key Management
- [ ] Attestor add/remove/disable lifecycle tested in staging.
- [ ] Quorum epoch mismatch rejection validated.
- [ ] Key rotation ceremony evidence archived.

## Brand & UX Trust
- [ ] Brand manifest version increments verified for every logo change.
- [ ] Release hash appended and auditable for each brand mutation.
- [ ] Wallet metadata snapshot compared before/after release.

## Walrus / Off-Chain Evidence
- [ ] Blob ID to hash mapping reproducibility check completed.
- [ ] Critical forensic artifacts retained with immutable IDs.

## Phase-5 Economy Controls
- [ ] Staking slash upper-bound tests executed.
- [ ] Yield allocation bps sum constraint validated.
- [ ] DEX routing allowlist (Cetus/Hop) enforcement verified.
- [ ] Marketplace license hash and blob-id validation tests passed.
