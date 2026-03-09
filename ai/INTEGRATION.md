# AOXCAN AI Integration Blueprint

## 1) Cross-chain AI attestation
1. XLayer tarafında inference tamamlanır.
2. Artefact Walrus'a yazılır (`walrus_blob_id`).
3. Sui tarafında `marketplace`/`relay` ile hash ve lisans kanıtı publish edilir.
4. `reputation` güncellemeleri bu kanıt setiyle ilişkilendirilir.

## 2) AI-ready modules
- `sources/marketplace.move`: dataset lisans + ödeme temel akışı.
- `sources/liquidity_manager.move`: Cetus/Hop yönlendirme event katmanı.
- `sources/staking.move`: staking/slash/autocompound ekonomik güvenlik katmanı.
- `sources/treasury.move`: yield hook policy + rebalance telemetrisi.

## 3) Compatibility notes
- XLayer sender doğrulaması `bridge_payload` üstünden zorunlu.
- Walrus blob kimliği boş olamaz; lisans hash zorunlu tutulur.
- Governance güncellemeleri release checklist ile imzalanmadan production'a taşınmamalıdır.
