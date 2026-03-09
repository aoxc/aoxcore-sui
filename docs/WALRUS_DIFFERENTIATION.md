# AOXC x Walrus: Klasiklerin Ötesi Farklılaşma Planı

Bu doküman, AOXC'yi sıradan bridge/DAO/treasury yapılarının ötesine taşıyacak sözleşme fikirlerini ve Walrus entegrasyon desenlerini listeler.

## 1) Neden Walrus?
- Büyük boyutlu AI artefact'larını (model kartı, inference kanıtı, dataset manifesti, risk raporu) zincir dışında ama **doğrulanabilir referansla** saklamak için.
- Sui üzerinde küçük ve hızlı kalan state + Walrus üzerinde zengin veri katmanı yaklaşımıyla gas/verimlilik dengesi sağlamak için.

## 2) Fark yaratacak sözleşme aileleri

### A. `ai_attestation_registry.move` (P0)
Amaç: AI ajan/servis çıktılarının doğrulanabilir kayıt katmanı.
- `Attestation` objesi:
  - `subject_id`
  - `model_id`
  - `input_hash`
  - `output_hash`
  - `proof_hash`
  - `walrus_blob_id`
  - `risk_score_bps`
  - `created_at_ms`
- Akış:
  1. Off-chain inference tamamlanır.
  2. Artefact Walrus'a yazılır (`walrus_blob_id`).
  3. On-chain yalnızca hash + blob referansı publish edilir.
- Fark: "AI sonucu" değil, "AI sonucu + kanıt izi" ürünleştirilir.

### B. `model_lineage.move` (P0)
Amaç: Model sürüm zinciri ve rollback güvenliği.
- `ModelManifest`:
  - `model_id`, `version`, `parent_version`
  - `weights_commitment`
  - `eval_report_blob_id`
  - `safety_policy_hash`
- DAO onaysız model yükseltmesini engeller.
- Fark: DeFi projelerinde nadir görülen **model governance lifecycle**.

### C. `dataset_rights_ledger.move` (P1)
Amaç: Dataset kullanım hakkı + gelir paylaşımı.
- Dataset contributor payları on-chain tutulur.
- Lisans dokümanı Walrus blob olarak referanslanır.
- Treasury gelir dağıtımı dataset katkı score'u ile bağlanır.
- Fark: AI veri ekonomisini native hale getirir.

### D. `zk_scoring_oracle.move` (P1)
Amaç: Gizli veriden üretilen skorların ifşasız kanıtı.
- Sadece skor ve kanıt özeti zincire gelir.
- Kanıt artefact'ları Walrus'ta tutulur.
- Reputation güncellemesi relay attestation + zk kanıt referansı ile yapılır.

### E. `agent_sla_market.move` (P2)
Amaç: AI servis sağlayıcıları için performans-teminat pazarı.
- Agent operatörü stake kilitler.
- SLA ihlali (gecikme/hatalı cevap) durumunda slash.
- Uyuşmazlık delilleri Walrus blob referanslarıyla çözülür.

## 3) AOXC ile doğrudan entegrasyon

### Mevcut modüllerle mapping
- `relay.move`:
  - Yeni report type: `REPORT_AI_ATTESTATION`
  - Walrus blob referanslı rapor köklerini anchor et.
- `reputation.move`:
  - Profil güncellemesinde `evidence_hash` yanında `walrus_blob_id` standardı ekle.
- `treasury.move`:
  - Performans/kanıt kalitesine göre dinamik dağıtım katsayısı.
- `sentinel_dao.move`:
  - Model güncellemesini "kritik proposal" sınıfında değerlendir.

## 4) Klasiklerden öte ürünleşebilecek use-case paketleri
- **Proof-of-Inference Badge:** Doğrulanabilir inference geçmişi olan cüzdanlara özel reputation tier.
- **Forensic Recovery Pack:** Bridge/treasury olaylarında post-mortem raporlarının Walrus üzerinden kanıtlı yayını.
- **AI Risk Circuit:** Belirli risk skorunun üstünde otomatik pause tetikleyen policy modülü.
- **Cross-chain AI Passport:** X Layer + Sui arasında taşınabilir AI güven puanı özeti.

## 5) 90 günlük uygulanabilir plan
1. Hafta 1-2: `ai_attestation_registry` spesifikasyonu + event şeması.
2. Hafta 3-4: Relay report type genişletme + reputation entegrasyonu.
3. Hafta 5-6: Model lineage governance + DAO kritik timelock bağlantısı.
4. Hafta 7-8: Walrus runbook + indexer reconciliation.
5. Hafta 9-12: Pilot dApp (Proof-of-Inference Badge) ve güvenlik testleri.

## 6) Başarı metrikleri
- On-chain referanslanan Walrus artefact doğrulama oranı.
- Attested AI event / total AI event oranı.
- DAO onaysız model değişikliği sayısı (hedef: 0).
- Incident başına forensic kapanış süresi.
