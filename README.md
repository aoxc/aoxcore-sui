# aoxcore-sui

AOXC'nin Sui-native, kurumsal seviyede modüler protokol mimarisi.

## Modüller

- `sources/errors.move` — Protokol genelinde tekil ve standart hata kodları.
- `sources/aoxc.move` — Neural asset katmanı: her varlık audit geçmişi, risk skoru ve statü ile taşınır; metadata + display profili içerir.
- `sources/neural_bridge.move` — XLayer -> Sui doğrulama geçidi: imza doğrulama, replay koruması, confirmation threshold ve atomic circuit breaker.
- `sources/reputation.move` — Shared object itibar defteri; topluluk odaklı skor ve kanıt yönetimi.
- `sources/treasury.move` — Autonomous Treasury: protokol gelirlerini itibar eşiği bazlı adil dağıtım.
- `sources/sentinel_dao.move` — 24 saat timelock + topluluk veto mekanizmalı hibrit yönetişim.
- `sources/relay.move` — Walrus Public Report relay: governance/reputation/bridge rapor hashlerini zincir üstüne sabitleme.

## Mimari İlkeler

1. **Sui-first object design**: EVM birebir kopya değil, shared/owned object desenleri.
2. **Defense-in-depth**: Bridge replay lock + signature verify + circuit breaker + DAO timelock.
3. **Auditability by default**: Asset lineage, reputation evidence ve Walrus report anchoring.
4. **Fair automation**: Treasury dağıtımı itibar eşiği ve zincir üstü kurallarla.
Sui-native AOXC Neural Gateway implementation.

## Modules

- `sources/aoxc.move`: Object-centric **NeuralAsset** model where each asset carries status, risk score, repair count, and cryptographic history checkpoints.
- `sources/neural_bridge.move`: Cross-chain gateway with digest-based replay lock, secp256k1 signature verification, confirmation threshold checks, and governance signer rotation.
- `sources/walrus_relay.move`: Walrus archive index for large XLayer logs / AI traces, with root commitment metadata anchored on Sui.
- `sources/reputation.move`: Shared-object reputation registry (`ReputationBook`) for transparent, community-visible trust state.

## Design direction

This repository intentionally does **not** copy an EVM contract 1:1. It uses Sui's object model (shared + owned objects) to implement autonomous, auditable neural operations.
