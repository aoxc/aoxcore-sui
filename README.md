<div align="center">

<img src="logos/aoxc.png" alt="AOXC Logo" width="240" style="border-radius: 20%; box-shadow: 0 8px 24px rgba(0,0,0,0.2);">

# 🌐 AOXC Sui Protocol
**Enterprise-grade Sui-native Protocol Stack**

[![Sui Network](https://img.shields.io/badge/Network-Sui%20Mainnet-blue?style=flat-square&logo=sui)](https://sui.io)
[![License](https://img.shields.io/badge/License-Apache%202.0-green?style=flat-square)](LICENSE)
[![Security](https://img.shields.io/badge/Audit-In%20Progress-orange?style=flat-square)](docs/AUDIT_NOTES.md)

<p align="center">
  <i>AOXC için denetlenebilir zincirler arası kontroller, gerçek varlık hazine saklama ve hibrit AI/Topluluk yönetişimine sahip kurumsal düzeyde protokol yığını.</i>
</p>

---
</div>

## 🛡️ Hızlı Denetim & Güvenlik Navigasyonu

Protokolün güvenlik katmanlarına doğrudan erişin:

* 🔍 **Tehdit Modeli:** [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md)
* ✅ **Yayın Kontrol Listesi:** [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md)
* 📐 **Resmi Değişmezler (Formal Invariants):** [`docs/SPEC.md`](docs/SPEC.md)
* ⚙️ **Operasyonel Mutabakat:** [`docs/INDEXER_RUNBOOK.md`](docs/INDEXER_RUNBOOK.md)

---

## 🚀 Phase-3: Cross-Chain & Güvenlik Öne Çıkanlar

| Özellik | Açıklama | Dosya Yolu |
| :--- | :--- | :--- |
| **Typed Bridge** | Ham byte yerine yapılandırılmış bridge/yönetişim payload'ları. | `bridge_payload.move` |
| **XLayer Ready** | EVM chain-id ve gönderici doğrulama ile tam entegrasyon. | `neural_bridge.move` |
| **Real-Asset Treasury** | `Balance<T>` kasa koruması ile gerçek `Coin<T>` saklama. | `treasury.move` |
| **Neural Staking** | Likit staking, slash mekanizması ve auto-compound temelleri. | `staking.move` |
| **AI Marketplace** | Walrus tabanlı veri kümesi listeleme ve lisans kontrolleri. | `marketplace.move` |

### ✨ Teknik Yetkinlikler
* 🔬 **Attestor Quorum:** Kritik doğrulamalar için N-of-M güven modeli.
* 🛑 **Circuit Breaker:** Protokol duraklatma durumları için tek doğruluk kaynağı (`circuit_breaker.move`).
* 📊 **Merkle Claims:** Geniş alıcı setleri için ölçeklenebilir ödül toplama sistemi.
* 🤖 **AI Economy:** XLayer + Sui + Walrus entegrasyonu ile AI-first mimari.

---

## 📦 Modül Yapısı (Core Modules)

- 🛠️ `errors.move`: Merkezi hata kodu kataloğu.
- ⚡ `circuit_breaker.move`: Protokol canlılık durumu ve acil durdurma kontrolleri.
- 🏗️ `bridge_payload.move`: Köprü ve DAO eylemleri için tip güvenli şemalar.
- 💎 `aoxc.move`: Güvenlik geçmişine sahip neural varlık nesne modeli.
- ⚖️ `sentinel_dao.move`: Timelock ve veto yetkili yönetişim katmanı.
- 🌊 `liquidity_manager.move`: DEX rotalama (Cetus/Hop) ve swap akışları.

---

## 📂 Dokümantasyon Paketi

| Bölüm | İçerik ve Kapsam |
| :--- | :--- |
| **Mimari** | [`ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Modül topolojisi ve güven düzlemleri. |
| **Analiz** | [`GAP_ANALYSIS.md`](docs/GAP_ANALYSIS.md) — "Full mü?" sorusu için teknik boşluk analizi. |
| **Yol Haritası** | [`ROADMAP_2026.md`](docs/ROADMAP_2026.md) — 2026 hedefleri ve kilometre taşları. |
| **AI Katmanı** | [`ai/INTEGRATION.md`](ai/INTEGRATION.md) — XLayer + Walrus AI uyumluluk akışı. |
| **Gözlemlenebilirlik**| [`EVENT_MAP.md`](docs/EVENT_MAP.md) — Indexer dostu olay sözleşmeleri. |

---

<div align="center">
  <sub>© 2026 AOXC Protocol | Secure. Auditable. Intelligent.</sub>
</div>
