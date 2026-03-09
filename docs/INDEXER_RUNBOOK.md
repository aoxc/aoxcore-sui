# AOXC Indexer & Operations Runbook

## 1. Off-Chain Monitoring Scope

### Core Event Streams
1. `neural_bridge::CommandApplied`
2. `circuit_breaker::BreakerStateChanged`
3. `sentinel_dao::ProposalQueued`
4. `sentinel_dao::ProposalFinalized`
5. `reputation::ProfileUpdated`
6. `treasury::RevenueDeposited`
7. `treasury::RewardDistributed`
8. `treasury::MerkleRootPublished`
9. `treasury::MerkleRewardClaimed`
10. `relay::ReportAnchored`

## 2. Canonical Reconciliation Jobs

### Job A — Bridge Command Integrity
- Match `CommandApplied.digest` with upstream signed command digest.
- Assert no duplicate digest in the same checkpoint window.
- Alert if `pause_state_after=true` without correlated governance/bridge incident ticket.

### Job B — Treasury Solvency
- Reconstruct treasury balance as:
  - sum(`RevenueDeposited.amount`) - sum(`RewardDistributed.amount`).
- Compare reconstructed balance with on-chain `treasury::balance_of<T>` snapshot.
- Alert on mismatch above tolerance (tolerance should be 0 for integer accounting).

### Job C — Reputation Attestation Coherence
- For each `ProfileUpdated`, verify `evidence_blob_id` exists in `relay::ReportAnchored` with `report_type=REPUTATION`.
- Verify evidence hash used by scorer pipeline matches relay root hash.

## 3. Incident Drill Playbooks

### Drill 1: Unexpected Global Pause
1. Detect `BreakerStateChanged.paused=true`.
2. Freeze distribution bots and bridge relayers.
3. Pull latest `CommandApplied` + `ProposalFinalized` records.
4. Determine source (`bridge` vs `dao`) and publish incident ID.
5. Resume only after signer/governance authorization and postmortem note.

### Drill 2: Reputation Feed Divergence
1. Detect evidence mismatch between off-chain scorer and relay anchor.
2. Pause reputation upserts.
3. Re-anchor corrected report in relay.
4. Replay upserts from last healthy checkpoint.

### Drill 3: Treasury Drift Alert
1. Compare reconstructed and on-chain treasury balances.
2. Pause distribution execution if mismatch persists.
3. Audit recent reward batch IDs and recipient lists.
4. Resume after zero-drift verification.

## 4. Indexing SLA Recommendations

- Block ingestion lag: < 2 blocks.
- Incident alert dispatch: < 60 seconds.
- Reconciliation cadence:
  - Bridge integrity: every block.
  - Treasury solvency: every payout tx + hourly sweep.
  - Reputation coherence: every profile update.

## 5. Data Retention & Versioning

- Store all indexed events for minimum 180 days hot + archive cold storage.
- Version event parsers by protocol release tag.
- Treat typed payload schema changes in `bridge_payload.move` as breaking changes for indexers.


## 6. Claim-Mode Monitoring
- Track `MerkleRootPublished` epochs and ensure claims are not duplicated per leaf hash.
- Alert if claim volume exceeds treasury solvency projections for active epoch.


## 7. Quorum Monitoring
- Alert when `quorum_signers` is equal to threshold for prolonged periods (safety margin risk).
- Alert immediately if command accepted counts rise while quorum participation entropy drops.
