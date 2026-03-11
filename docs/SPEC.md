# AOXC Sui Protocol Specification (Phase-1)

## 1. Core Invariants

### 1.1 Circuit Breaker Invariants
- Protocol liveness is represented only by `circuit_breaker::CircuitBreaker.paused`.
- When `paused == true`, transfers/distributions guarded by `assert_live` must abort with `E_PROTOCOL_PAUSED`.

### 1.2 Bridge Invariants
- Every accepted command digest is unique (`used_digests`) and replay attempts abort with `E_REPLAY`.
- Commands must satisfy:
  - valid source chain,
  - valid signature,
  - unexpired deadline,
  - confirmations >= configured threshold.

### 1.3 AOXC Asset Invariants
- `amount > 0` for mint.
- `minted_supply <= max_supply` at all times.
- Status transitions must use the defined status set.
- Security checkpoints must carry non-empty hash evidence.

### 1.4 Treasury Invariants
- Vault stores real `Balance<T>` from deposited `Coin<T>`.
- Distribution vectors must have equal length.
- Every payout amount must be non-zero.
- Total payout must not exceed vault balance.
- Every recipient must meet `min_reputation_score`.

### 1.5 Reputation Invariants
- Evidence hash must be non-empty.
- Evidence must be relay-attested as `REPORT_REPUTATION` before profile update.

### 1.6 Typed Payload Invariants
- Bridge commands use `bridge_payload::BridgePayload` instead of raw `vector<u8>`.
- DAO proposals use `bridge_payload::GovernanceAction` with validated action types.
- Pause/resume actions must carry non-empty proof roots.

### 1.7 Explicit Decoding Invariants
- Raw `vector<u8>` command inputs must pass explicit BCS decode helpers before execution.
- Decoders exist per action class: `Pause`, `Resume`, `FundUpdate`, and governance action decode.
- Any invalid kind/proof payload must abort with strict argument/hash errors.

### 1.8 Governance Guardrail Invariants
- DAO timelock must stay within bounded policy range (<= 1 week).
- Proposal execution is cooldown-gated to prevent action spam.
- Fund delta requests above configured maximum (20%) are rejected.

### 1.9 Merkle Claim Treasury Invariants
- Published root hash must be non-empty.
- Claim path must provide sibling + index-direction vectors with equal length.
- Leaf domain is separated by `(epoch, user, amount, token_type)`.
- Recomputed Merkle root from leaf/path must match active epoch root.
- Leaf hash can be claimed at most once per epoch.

### 1.10 Cross-Chain Quorum Invariants
- Bridge/report critical operations require quorum threshold satisfaction.
- Single-attestor approvals are insufficient when threshold > 1.
- Quorum threshold must satisfy `0 < threshold <= attestor_count`.
- Attestor lifecycle changes (add/remove/disable) bump quorum epoch.
- Report anchor signer_count cannot exceed currently active attestor count.
- Bridge commands must target the active quorum epoch.
- Bridge command envelope `target` must match typed payload target module.

### 1.11 Multi-Domain Compatibility Invariants
- Payload `schema_version` must be supported.
- Envelope `evm_chain_id` field is treated as a generic domain/network id and must be in the allowlist.
- Supported families: XLayer/EVM ids, Cardano network magics, and web relay domain ids.
- `target_module` must be whitelisted per action kind.

### 1.12 Phase-5 Economy Invariants
- Staking slash basis points must remain within bounded policy limit.
- Staking auto-compound reward bps must remain within bounded policy limit.
- Treasury yield allocation (lending + liquidity) must not exceed 10,000 bps.
- Treasury yield policy must have at least one enabled route (lending or liquidity).
- Liquidity routing accepts only approved DEX identifiers.
- Liquidity swap requests must stay within configured slippage policy.
- Marketplace listings require non-empty Walrus blob id and license hash.
- The same Walrus blob id cannot remain simultaneously active across listings.

## 2. Emergency Runbook

### 2.1 Incident: Bridge Compromise Suspected
1. Queue/execute DAO pause proposal or issue bridge halt command.
2. Verify `CircuitBreaker.paused == true` on-chain.
3. Rotate bridge signer via `neural_bridge::rotate_signer`.
4. Re-enable only after new signer and forensic verification.

### 2.2 Incident: Malicious Distribution Attempt
1. Pause protocol through DAO/circuit-breaker.
2. Audit recent `RewardDistributed` and `ProfileUpdated` events.
3. Raise `min_reputation_score` if necessary.
4. Resume after governance sign-off.

### 2.3 Incident: Reputation Feed Integrity Failure
1. Pause treasury distributions.
2. Re-anchor valid proof report blobs in relay.
3. Re-run reputation updates with corrected attestations.
4. Resume distributions.

## 3. Trust Boundaries

- **Bridge signer:** trusted for command authenticity only.
- **DAO admin cap:** trusted to queue/finalize governance operations.
- **Relay admin cap:** trusted to anchor valid report metadata.
- **Reputation admin cap:** trusted to call updates, but updates are constrained by relay attestation checks.

## 4. Test Coverage Goals

- Replay rejection.
- Timelock pending rejection.
- Invalid action/status/type rejections.
- Empty hash and length mismatch rejections.
- Circuit-breaker paused state rejection.


## 5. Observability
- Canonical event contracts are documented in `docs/EVENT_MAP.md`.
- Indexers should treat event payloads as versioned API surfaces.


## 6. Branding & Display Compatibility
- AOXC token and reputation layers keep logo-linked display profile objects for wallet rendering.
- Logos are referenced from `logos/` paths and should be published to stable CDN/IPFS URIs in production.


## 7. Phase-2B Operations
- Scenario war-games should model complete object-flow sequences for bridge, DAO, treasury, and reputation modules.
- Branding update operations require module cap + DAO cap + checksum agreement.


## 8. Phase-4 Immutable Standard
- Relay governance now includes attestor lifecycle operations (add/remove/disable) and epoch-versioned quorum state.
- Neural bridge verification accepts signatures only from active (non-disabled) attestors and enforces quorum epoch matching.
- Treasury claim mode upgraded to production Merkle path verification using sibling/index vectors.
- AOXC and reputation branding are tracked through DAO-gated versioned manifest objects with immutable release-hash history.


## 9. Formal Verification Notes
- `neural_bridge.move` includes spec hooks for authorization and replay-safe execution intent.
- `treasury.move` includes spec hooks for non-negative balance safety intent and claim semantics.


## 10. Audit Artifacts
- Threat model: `docs/THREAT_MODEL.md`
- Release hardening checklist: `docs/RELEASE_CHECKLIST.md`
- Security controls checklist: `docs/SECURITY_CHECKLIST.md`
- Economy spec: `docs/ECONOMY.md`
