# AOXC Event Map (Phase-2A Observability Pack)

This document is intended for indexers, analytics pipelines, exchange risk engines, and dashboard teams.

## Module: `circuit_breaker`
- `BreakerStateChanged { paused, reason_hash }`
  - Trigger: global pause/resume changes.
  - Index keys: `paused`, `reason_hash`.

## Module: `neural_bridge`
- `CommandApplied { command_id, digest, payload_kind, pause_state_after, executed_at_ms }`
  - Trigger: accepted bridge command.
  - Index keys: `command_id`, `digest`, `payload_kind`.

## Module: `aoxc`
- `AssetCheckpointed { owner, amount, neural_status, risk_score_bps }`
  - Trigger: security status updates on `NeuralAsset`.
  - Index keys: `owner`, `neural_status`.

## Module: `treasury`
- `RevenueDeposited { amount, new_balance }`
  - Trigger: treasury receives `Coin<T>`.
- `RewardDistributed { user, amount }`
  - Trigger: score-gated payout.
  - Index keys: `user`.

## Module: `reputation`
- `ProfileUpdated { user, score, trust_tier, evidence_blob_id }`
  - Trigger: attested reputation update.
  - Index keys: `user`, `evidence_blob_id`.

## Module: `relay`
- `ReportAnchored { blob_id, report_type, source_epoch }`
  - Trigger: Walrus report anchor.
  - Index keys: `blob_id`, `report_type`.

## Module: `sentinel_dao`
- `ProposalQueued { id, action_type, eta_ms }`
- `ProposalFinalized { id, status }`
  - Trigger: governance lifecycle transitions.
  - Index keys: `id`, `status`.

## Suggested Derived Metrics
1. **Safety Latency:** `ProposalFinalized.eta_ms - ProposalQueued.eta_ms`.
2. **Bridge Trust Health:** replay rejection ratio vs `CommandApplied` count.
3. **Treasury Fairness:** share of `RewardDistributed` volume by trust tier.
4. **Recovery Velocity:** time from pause event to resume event.


## Operational References
- Reconciliation and incident response procedures: `docs/INDEXER_RUNBOOK.md`.
- Typed decoding source of truth: `sources/bridge_payload.move`.
