# aoxcore-sui

Sui-native AOXC Neural Gateway implementation.

## Modules

- `sources/aoxc.move`: Object-centric **NeuralAsset** model where each asset carries status, risk score, repair count, and cryptographic history checkpoints.
- `sources/neural_bridge.move`: Cross-chain gateway with digest-based replay lock, secp256k1 signature verification, confirmation threshold checks, and governance signer rotation.
- `sources/walrus_relay.move`: Walrus archive index for large XLayer logs / AI traces, with root commitment metadata anchored on Sui.
- `sources/reputation.move`: Shared-object reputation registry (`ReputationBook`) for transparent, community-visible trust state.

## Design direction

This repository intentionally does **not** copy an EVM contract 1:1. It uses Sui's object model (shared + owned objects) to implement autonomous, auditable neural operations.
