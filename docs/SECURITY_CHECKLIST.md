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
