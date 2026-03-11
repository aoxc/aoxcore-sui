# AOXC Compatibility Matrix

Bu doküman, `aoxcon-move` payload katmanının çoklu domain uyumluluk yüzeyini özetler.

## Bridge Envelope Domain IDs

`bridge_payload::BridgePayload.evm_chain_id` alanı geriye dönük uyumluluk için aynı isimde tutulur; ancak pratikte **genel domain/network kimliği** olarak değerlendirilir.

### Supported Domains

- **XLayer / EVM**
  - XLayer mainnet: `196`
  - XLayer testnet: `195`
  - Ethereum mainnet: `1`
  - Base mainnet: `8453`
  - Arbitrum One: `42161`
- **Cardano**
  - Mainnet network magic: `764824073`
  - Preprod network magic: `1`
- **Web Relay**
  - Production domain: `90001`
  - Staging domain: `90002`

## Contract-Level Guarantees

- Şema sürümü (`schema_version`) zorunlu doğrulanır.
- Domain/network id allowlist dışında ise işlem `E_CHAIN_ID_INVALID` ile abort eder.
- `target_module` + `kind` kombinasyonu whitelist dışına çıkamaz.
- `sender` 20-byte ve all-zero olamaz; proof root boş olamaz.

## Integration Notes

- EVM tarafı için chain-id tabanlı yönlendirme doğrudan uyumludur.
- Cardano ve web relay tarafında aynı envelope kullanılarak cross-stack parser sadeleştirilir.
- İmzacı/verifier katmanında domain’e özel doğrulama (örn. Cardano witness/finality) üst katmanda eklenmelidir.
