# AOXC Future Readiness Plan

## Objective
This document defines what should be added for AOXC to evolve from "strong audit-ready foundation" to long-term, future-compatible infrastructure.

It is intentionally practical and modest: priorities, concrete outcomes, and measurable checkpoints.

---

## Readiness Levels

### Level 1 — Production Discipline (Now -> Next)
- Required CI gates for `sui move build`, `sui move test`, and lint/static checks.
- Branch protection with mandatory green checks.
- Deterministic release procedure with signed artifacts.

### Level 2 — Verification Depth
- Property-by-property formal verification closure reports.
- Invariant traceability matrix (code path -> invariant -> evidence).
- Regression harness for payload/parser compatibility.

### Level 3 — Long-Horizon Cryptographic Agility
- Pluggable signature verification design path.
- PQC transition plan (hybrid period, compatibility windows, migration triggers).
- Domain-separated digest versioning with explicit deprecation policy.

---

## “Quantum/Future Compatible” in Real Terms
AOXC cannot claim post-quantum security today without implementing and validating post-quantum signatures end-to-end.

A credible path is:
1. Add **crypto agility interfaces** now.
2. Introduce **hybrid signatures** later (current + PQC).
3. Migrate to PQC-primary only after operational and ecosystem readiness.

This avoids overpromising while remaining future-ready.

---

## Priority Backlog (Suggested)

## P0 — Must Have
1. CI enforcement as merge gate.
2. Release evidence bundle standard:
   - build/test hash,
   - signer log,
   - compatibility report,
   - incident drill reference.
3. Differential payload fixture tests across parsers.

## P1 — High Value
1. Formal proofs for replay safety + quorum safety + supply conservation.
2. State reconciliation snapshots for multi-actor scenarios.
3. Signed release notes with schema compatibility table.

## P2 — Strategic
1. Signature verifier abstraction for crypto agility.
2. Hybrid-signature command format version.
3. Post-quantum migration playbook and runbook drills.

---

## Architecture Recommendation: Crypto Agility Layer

```text
[Bridge Command]
      |
      v
[Digest + Domain Version]
      |
      v
[Verifier Adapter Interface]
   |                |
   v                v
[ECDSA Today]   [PQC/Hybrid Tomorrow]
```

Design implication:
- keep command semantics stable,
- version only the verifier/digest policy,
- preserve auditability across migrations.

---

## Measurable Exit Criteria
AOXC can be considered "full-production grade" only when all are true:
1. CI/build/test/prover gates are mandatory and green.
2. Replay/quorum/supply properties have evidence-backed proof reports.
3. Release evidence bundle is signed and archived for each release.
4. Parser compatibility suite passes for supported payload versions.
5. Crypto agility path exists with tested migration procedures.

---

## Suggested Next 2 Sprints

### Sprint A
- Add CI hard gates and branch protection policy docs.
- Add compatibility fixture suite for bridge payloads.
- Add release evidence template and checklist wiring.

### Sprint B
- Add formal verification report artifacts.
- Add state reconciliation scenario tests.
- Draft verifier adapter interface for future hybrid/PQC path.

---

## Final Note
Future compatibility is a process, not a single feature.

The strongest posture is:
- strict honesty about current guarantees,
- strong audit discipline now,
- deliberate cryptographic agility for tomorrow.
