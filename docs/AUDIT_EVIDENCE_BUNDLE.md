# AOXC Audit Evidence Bundle (Mainnet-Candidate)

Bu dosya, release anında denetçiye ve iç güvenlik ekibine teslim edilecek **zorunlu artefact setini** standartlaştırır.

## 1) Kimlik ve İzlenebilirlik

- Release tag (`vX.Y.Z`) ve commit SHA
- Derleme zamanı (UTC), derleyen pipeline run ID
- İlgili PR numarası ve changelog özeti

## 2) Build/Test Kanıtı

- `sui move build` çıktısı (tam log)
- `sui move test` çıktısı (tam log)
- Test rapor hash'i (SHA256)
- Test ortamı versiyonları (`sui`, `rustc`, `cargo`)

## 3) Güvenlik Kanıtı

- `docs/THREAT_MODEL.md` diff veya güncellik beyanı
- Kritik invariant etkisi (modül bazlı):
  - bridge
  - relay/quorum
  - treasury/claims
  - governance/timelock/veto
- Yeni risk kabulü varsa onaylayan kişi/rol

## 4) Operasyonel Kanıt

- Signer ceremony kaydı (katılımcılar + zaman damgası)
- Anahtar rotasyon kaydı (varsa)
- Incident drill kaydı (kill-switch/pause-resume tatbikatı)
- Geri alma (rollback) planı ve sorumlu kişi

## 5) Uyum ve Dokümantasyon Kanıtı

- `docs/SPEC.md` güncel mi? (evet/hayır + gerekçe)
- `docs/EVENT_MAP.md` ve `docs/INDEXER_RUNBOOK.md` etkisi
- Parser/API sürüm etkisi ve backward-compatibility notu

## 6) Onaylar (4-eyes minimum)

- Teknik onaylayan #1 (isim/rol/imza)
- Teknik onaylayan #2 (isim/rol/imza)
- Gerekirse güvenlik temsilcisi ek imza

---

## Örnek Teslim Dizini

```
audit-bundle/
  metadata.json
  build.log
  test.log
  hashes.txt
  threat-model-note.md
  invariant-impact.md
  signer-ceremony.md
  drill-record.md
  approvals.md
```
