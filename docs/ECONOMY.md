# AOXC Neural Economy (Phase-5)

## 1. Economic Pillars

1. **Neural Staking** (`sources/staking.move`)
   - AOXC sahipleri stake ederek governance-weight + protokol gelirinden pay kazanır.
   - Slashing ve auto-compounding mekanikleri dahil.
2. **Treasury Yield Engine** (`sources/treasury.move`)
   - Lending/LP adapter hook politikalarıyla hazine varlığının verim rotasyonu.
3. **Swap & Liquidity Hub** (`sources/liquidity_manager.move`)
   - Cetus/Hop gibi dış DEX yönlendirme katmanı ve izlenebilir event sözleşmesi.
4. **AI Data Marketplace Foundations** (`sources/marketplace.move`)
   - Walrus blob ID + lisans hash zorunlu veri listeme/satın alma temel akışı.

## 2. Neural Staking
- Pool principal `Balance<T>` olarak tutulur.
- `slash_bps` ile güvenlik ihlalinde ceza uygulanır.
- Treasury referanslı auto-compound metriği ile sürdürülebilir büyüme hedeflenir.

## 3. Yield Engine
- `YieldHookConfig`:
  - lending/liquidity enabled flagleri,
  - allocation bps,
  - adapter identifier alanları,
  - rebalance nonce.
- Rebalance akışı event-first tasarlanmıştır (on-chain telemetri, off-chain execution botları).

## 4. Liquidity Routing
- `LiquidityHub` iki entegrasyon sınıfını takip eder: Cetus, Hop.
- Swap ve LP operasyonları pausable güvenlik modeline bağlıdır.

## 5. AI Data Marketplace
- Dataset listeleme için:
  - `walrus_blob_id` zorunlu,
  - `license_hash` zorunlu,
  - pozitif fiyat zorunlu.
- Satın alma sonrası listing finalleşir; ikinci satış ayrı listing açarak yapılır.

## 6. Governance Integration
- DAO; slash parametreleri, yield allocation ve DEX enablement politikalarını dolaylı olarak yönetir.
- Release checklist olmadan ekonomi parametreleri production'a alınmamalıdır.

## 7. Audit Focus
- Slashing üst limit güvenliği.
- Hook allocation toplamı ≤ 10000 bps.
- Marketplace lisans zorunluluğu.
- DEX route doğrulaması ve pause-gate davranışı.
