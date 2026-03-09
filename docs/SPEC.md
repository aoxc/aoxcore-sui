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
