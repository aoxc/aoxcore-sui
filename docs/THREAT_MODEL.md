# AOXC Threat Model (Audit-Oriented)

## 1. Scope
Bu model AOXC'nin kritik güvenlik yüzeylerini kapsar:
- Bridge command acceptance (`neural_bridge`)
- Attestor governance (`relay`)
- Treasury custody/distribution (`treasury`)
- Governance execution (`sentinel_dao`)
- Reputation attestation (`reputation`)
- Branding manifest integrity (`aoxc`, `reputation`)

## 2. Assets to Protect
1. Treasury `Balance<T>` varlığı.
2. Pause-state kontrol yetkisi.
3. Quorum ve signer güvenilirliği.
4. Reputation doğruluk seviyesi.
5. Wallet-facing brand integrity (logo/checksum/manifest history).

## 3. Trust Assumptions
- Sui chain finality ve object ownership semantiği güvenilir.
- Off-chain signer HSM/keystore yönetimi operasyonel olarak doğru yapılır.
- Indexer pipeline eventleri eksiksiz ingest eder.
- Walrus blob içerikleri hash/ID referanslarıyla doğrulanır.

## 4. Threats and Mitigations

### T1: Replay of bridge commands
- Risk: Aynı komutun tekrar uygulanması.
- Mitigation: `used_digests` replay lock + digest uniqueness kontrolleri.
- Detection: Duplicate digest alert (indexer job).

### T2: Quorum degradation / signer collusion
- Risk: Az sayıda signer ile kritik işlemlerin geçmesi.
- Mitigation: threshold safety (`0 < threshold <= attestor_count`), disable/add/remove lifecycle, quorum epoch pinning.
- Detection: quorum entropy düşüş alarmı.

### T3: Governance abuse (fast-track harmful action)
- Risk: Timelock bypass benzeri davranışlar.
- Mitigation: bounded timelock, cooldown, veto threshold, critical action delay.
- Detection: queued->finalized süre denetimi.

### T4: Treasury misdistribution / claim abuse
- Risk: Hatalı payout veya double-claim.
- Mitigation: vector length checks, balance checks, Merkle proof verification, claimed leaf lock.
- Detection: solvency reconciliation + claim anomaly jobs.

### T5: Evidence forgery in reputation updates
- Risk: Relay-attested olmayan score update.
- Mitigation: `relay::assert_attested` zorunluluğu.
- Detection: evidence blob ↔ report anchor cross-check.

### T6: Brand hijack / malicious logo swap
- Risk: Wallet kullanıcılarının phishing içerikle manipülasyonu.
- Mitigation: DAO + module cap + checksum gate + versioned manifest changelog.
- Detection: manifest version drift and checksum mismatch alarms.

## 5. Residual Risks
- Off-chain key compromise (HSM dışı cihazlar).
- Indexer downtime nedeniyle gecikmiş alarm.
- Yanlış governance operasyonu (insan hatası) — on-chain policy limitlerle kısmi azaltım.

## 6. Audit Evidence Expectations
- Replay, quorum, timelock, claim, checksum için test kanıtı.
- Runbook drill kayıtları.
- Release checklist imzaları.
