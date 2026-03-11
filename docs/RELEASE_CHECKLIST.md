# AOXC Release Checklist (Audit Gate)

## A. Build & Test Gate
- [ ] `sui move build` clean.
- [ ] `sui move test` clean.
- [ ] Negative tests abort-code expectations match.
- [ ] Scenario tests deterministic and passing.

## B. Security Gate
- [ ] Replay protection re-verified.
- [ ] Quorum threshold/epoch invariants verified.
- [ ] Merkle claim path verification sampled with known vectors.
- [ ] DAO timelock/veto/cooldown checks completed.
- [ ] Brand manifest mutation flow (DAO + checksum + release hash) tested.

## C. Docs & Observability Gate
- [ ] `docs/SPEC.md` updated for behavior changes.
- [ ] `docs/EVENT_MAP.md` updated for new/changed events.
- [ ] `docs/INDEXER_RUNBOOK.md` updated for reconciliation changes.
- [ ] `docs/THREAT_MODEL.md` reviewed and current.
- [ ] Parser version impact documented.

## D. Operations Gate
- [ ] Incident drill rehearsal completed.
- [ ] Signer ceremony and key rotation record attached.
- [ ] Rollback/kill-switch decision owner assigned.
- [ ] Release approvers listed and signed.


## E. Evidence Bundle Gate
- [ ] `docs/AUDIT_EVIDENCE_BUNDLE.md` template completed.
- [ ] Build/test logs archived with hashes.
- [ ] 4-eyes release approval attached.
- [ ] Cross-domain integration notes attached (EVM/Cardano/Web).
