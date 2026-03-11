module aoxc::bridge_payload {
    use std::bcs;
    use std::string::{Self, String};
    use std::vector;
    use aoxc::errors;

    const SCHEMA_V1: u16 = 1;

    /// EVM family chain ids.
    const XLAYER_MAINNET_CHAIN_ID: u64 = 196;
    const XLAYER_TESTNET_CHAIN_ID: u64 = 195;
    const ETHEREUM_MAINNET_CHAIN_ID: u64 = 1;
    const BASE_MAINNET_CHAIN_ID: u64 = 8453;
    const ARBITRUM_ONE_CHAIN_ID: u64 = 42161;

    /// Cardano network-magics represented in the same u64 field.
    const CARDANO_MAINNET_NETWORK_MAGIC: u64 = 764824073;
    const CARDANO_PREPROD_NETWORK_MAGIC: u64 = 1;

    /// Off-chain web relay lanes (domain ids in chain-id field for envelope compatibility).
    const WEB_RELAY_PROD_DOMAIN_ID: u64 = 90_001;
    const WEB_RELAY_STAGE_DOMAIN_ID: u64 = 90_002;

    const KIND_SYSTEM_HALT: u8 = 1;
    const KIND_SYSTEM_RESUME: u8 = 2;
    const KIND_FUND_UPDATE: u8 = 3;
    const KIND_X_MINT: u8 = 4;
    const KIND_X_BURN: u8 = 5;

    const TARGET_BREAKER: vector<u8> = b"circuit_breaker";
    const TARGET_TREASURY: vector<u8> = b"treasury";
    const TARGET_AOXC: vector<u8> = b"aoxc";
    const MAX_NOTE_BYTES: u64 = 256;

    public struct BridgePayload has copy, drop, store {
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        kind: u8,
        target_module: String,
        ref_id: u64,
        note: String,
        proof_root: vector<u8>,
    }

    public struct GovernanceAction has copy, drop, store {
        schema_version: u16,
        action_type: u8,
        target_module: String,
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    }

    public struct PausePayload has copy, drop, store {
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    }

    public struct ResumePayload has copy, drop, store {
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    }

    public struct FundUpdatePayload has copy, drop, store {
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        policy_name: String,
        proof_root: vector<u8>,
    }

    public struct AssetRoutePayload has copy, drop, store {
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        amount: u64,
        recipient: address,
        proof_root: vector<u8>,
    }

    public struct IntentPayload has copy, drop, store {
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        desired_outcome: String,
        min_success_bps: u16,
        expiry_epoch: u64,
        proof_root: vector<u8>,
    }

    public fun validate_schema_version(version: u16) {
        assert!(version == SCHEMA_V1, errors::E_SCHEMA_VERSION);
    }

    public fun is_supported_chain_id(chain_id: u64): bool {
        chain_id == XLAYER_MAINNET_CHAIN_ID
            || chain_id == XLAYER_TESTNET_CHAIN_ID
            || chain_id == ETHEREUM_MAINNET_CHAIN_ID
            || chain_id == BASE_MAINNET_CHAIN_ID
            || chain_id == ARBITRUM_ONE_CHAIN_ID
            || chain_id == CARDANO_MAINNET_NETWORK_MAGIC
            || chain_id == CARDANO_PREPROD_NETWORK_MAGIC
            || chain_id == WEB_RELAY_PROD_DOMAIN_ID
            || chain_id == WEB_RELAY_STAGE_DOMAIN_ID
    }

    public fun validate_chain_id(chain_id: u64) {
        assert!(is_supported_chain_id(chain_id), errors::E_CHAIN_ID_INVALID);
    }

    fun assert_sender_not_zero(sender: &vector<u8>) {
        let mut i = 0;
        let len = vector::length(sender);
        let mut all_zero = true;
        while (i < len) {
            if (*vector::borrow(sender, i) != 0) {
                all_zero = false;
                break
            };
            i = i + 1;
        };
        assert!(!all_zero, errors::E_INVALID_ARGUMENT);
    }

    fun assert_message_not_empty(message: &String) {
        assert!(vector::length(string::bytes(message)) > 0, errors::E_INVALID_ARGUMENT);
    }

    fun assert_message_len(message: &String) {
        assert!(vector::length(string::bytes(message)) <= MAX_NOTE_BYTES, errors::E_POLICY_LIMIT);
    }

    fun validate_asset_route_payload(decoded: &AssetRoutePayload, kind: u8) {
        assert!(decoded.amount > 0, errors::E_AMOUNT_ZERO);
        assert!(decoded.recipient != @0x0, errors::E_INVALID_ARGUMENT);
        new_bridge_payload(
            decoded.schema_version,
            decoded.evm_chain_id,
            copy decoded.xlayer_sender,
            kind,
            copy decoded.target_module,
            decoded.ref_id,
            string::utf8(b"asset-route"),
            copy decoded.proof_root,
        );
    }

    public fun validate_intent(desired_outcome: &String, min_success_bps: u16, expiry_epoch: u64) {
        assert_message_not_empty(desired_outcome);
        assert_message_len(desired_outcome);
        assert!((min_success_bps as u64) <= 10_000, errors::E_POLICY_LIMIT);
        assert!(expiry_epoch > 0, errors::E_INVALID_ARGUMENT);
    }

    public fun validate_target_module(target_module: &String, kind: u8) {
        if (kind == KIND_FUND_UPDATE) {
            assert!(string::bytes(target_module) == TARGET_TREASURY, errors::E_TARGET_NOT_ALLOWED);
            return
        };
        if (kind == KIND_X_MINT || kind == KIND_X_BURN) {
            assert!(string::bytes(target_module) == TARGET_AOXC, errors::E_TARGET_NOT_ALLOWED);
            return
        };
        assert!(string::bytes(target_module) == TARGET_BREAKER, errors::E_TARGET_NOT_ALLOWED);
    }

    public fun new_bridge_payload(
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        kind: u8,
        target_module: String,
        ref_id: u64,
        note: String,
        proof_root: vector<u8>,
    ): BridgePayload {
        validate_schema_version(schema_version);
        validate_chain_id(evm_chain_id);
        validate_payload_kind(kind);
        validate_target_module(&target_module, kind);
        assert!(vector::length(&xlayer_sender) == 20, errors::E_INVALID_ARGUMENT);
        assert_sender_not_zero(&xlayer_sender);
        assert_message_not_empty(&note);
        assert_message_len(&note);
        assert!(vector::length(&proof_root) > 0, errors::E_EMPTY_HASH);
        BridgePayload { schema_version, evm_chain_id, xlayer_sender, kind, target_module, ref_id, note, proof_root }
    }

    public fun new_governance_action(
        schema_version: u16,
        action_type: u8,
        target_module: String,
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    ): GovernanceAction {
        validate_schema_version(schema_version);
        validate_governance_action(action_type);
        validate_target_module(&target_module, action_type);
        assert_message_not_empty(&reason);
        assert_message_len(&reason);
        assert!(vector::length(&proof_root) > 0, errors::E_EMPTY_HASH);
        GovernanceAction { schema_version, action_type, target_module, ref_id, reason, proof_root }
    }

    public fun encode_pause_payload(
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    ): vector<u8> {
        let payload = PausePayload { schema_version, evm_chain_id, xlayer_sender, target_module, ref_id, reason, proof_root };
        bcs::to_bytes(&payload)
    }

    public fun encode_resume_payload(
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    ): vector<u8> {
        let payload = ResumePayload { schema_version, evm_chain_id, xlayer_sender, target_module, ref_id, reason, proof_root };
        bcs::to_bytes(&payload)
    }

    public fun encode_fund_update_payload(
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        policy_name: String,
        proof_root: vector<u8>,
    ): vector<u8> {
        let payload = FundUpdatePayload { schema_version, evm_chain_id, xlayer_sender, target_module, ref_id, policy_name, proof_root };
        bcs::to_bytes(&payload)
    }

    public fun decode_pause_payload(raw: vector<u8>): BridgePayload {
        let decoded = bcs::from_bytes<PausePayload>(&raw);
        new_bridge_payload(decoded.schema_version, decoded.evm_chain_id, decoded.xlayer_sender, KIND_SYSTEM_HALT, decoded.target_module, decoded.ref_id, decoded.reason, decoded.proof_root)
    }

    public fun decode_resume_payload(raw: vector<u8>): BridgePayload {
        let decoded = bcs::from_bytes<ResumePayload>(&raw);
        new_bridge_payload(decoded.schema_version, decoded.evm_chain_id, decoded.xlayer_sender, KIND_SYSTEM_RESUME, decoded.target_module, decoded.ref_id, decoded.reason, decoded.proof_root)
    }

    public fun decode_fund_update_payload(raw: vector<u8>): BridgePayload {
        let decoded = bcs::from_bytes<FundUpdatePayload>(&raw);
        new_bridge_payload(decoded.schema_version, decoded.evm_chain_id, decoded.xlayer_sender, KIND_FUND_UPDATE, decoded.target_module, decoded.ref_id, decoded.policy_name, decoded.proof_root)
    }

    public fun encode_asset_mint_payload(
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        amount: u64,
        recipient: address,
        proof_root: vector<u8>,
    ): vector<u8> {
        let payload = AssetRoutePayload { schema_version, evm_chain_id, xlayer_sender, target_module, ref_id, amount, recipient, proof_root };
        bcs::to_bytes(&payload)
    }

    public fun encode_asset_burn_payload(
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        amount: u64,
        recipient: address,
        proof_root: vector<u8>,
    ): vector<u8> {
        let payload = AssetRoutePayload { schema_version, evm_chain_id, xlayer_sender, target_module, ref_id, amount, recipient, proof_root };
        bcs::to_bytes(&payload)
    }

    public fun decode_asset_mint_payload(raw: vector<u8>): BridgePayload {
        let decoded = bcs::from_bytes<AssetRoutePayload>(&raw);
        validate_asset_route_payload(&decoded, KIND_X_MINT);
        new_bridge_payload(decoded.schema_version, decoded.evm_chain_id, decoded.xlayer_sender, KIND_X_MINT, decoded.target_module, decoded.ref_id, string::utf8(b"xlayer-asset-mint"), decoded.proof_root)
    }

    public fun decode_asset_burn_payload(raw: vector<u8>): BridgePayload {
        let decoded = bcs::from_bytes<AssetRoutePayload>(&raw);
        validate_asset_route_payload(&decoded, KIND_X_BURN);
        new_bridge_payload(decoded.schema_version, decoded.evm_chain_id, decoded.xlayer_sender, KIND_X_BURN, decoded.target_module, decoded.ref_id, string::utf8(b"xlayer-asset-burn"), decoded.proof_root)
    }

    public fun encode_intent_payload(
        schema_version: u16,
        evm_chain_id: u64,
        xlayer_sender: vector<u8>,
        target_module: String,
        ref_id: u64,
        desired_outcome: String,
        min_success_bps: u16,
        expiry_epoch: u64,
        proof_root: vector<u8>,
    ): vector<u8> {
        validate_schema_version(schema_version);
        validate_chain_id(evm_chain_id);
        validate_intent(&desired_outcome, min_success_bps, expiry_epoch);
        let payload = IntentPayload {
            schema_version,
            evm_chain_id,
            xlayer_sender,
            target_module,
            ref_id,
            desired_outcome,
            min_success_bps,
            expiry_epoch,
            proof_root,
        };
        bcs::to_bytes(&payload)
    }

    public fun decode_intent_payload(raw: vector<u8>, kind: u8): BridgePayload {
        let decoded = bcs::from_bytes<IntentPayload>(&raw);
        validate_payload_kind(kind);
        validate_intent(&decoded.desired_outcome, decoded.min_success_bps, decoded.expiry_epoch);
        new_bridge_payload(
            decoded.schema_version,
            decoded.evm_chain_id,
            decoded.xlayer_sender,
            kind,
            decoded.target_module,
            decoded.ref_id,
            decoded.desired_outcome,
            decoded.proof_root,
        )
    }

    public fun decode_governance_action(raw: vector<u8>): GovernanceAction {
        let decoded = bcs::from_bytes<GovernanceAction>(&raw);
        validate_schema_version(decoded.schema_version);
        validate_governance_action(decoded.action_type);
        validate_target_module(&decoded.target_module, decoded.action_type);
        assert_message_not_empty(&decoded.reason);
        assert_message_len(&decoded.reason);
        assert!(vector::length(&decoded.proof_root) > 0, errors::E_EMPTY_HASH);
        decoded
    }

    public fun validate_payload_kind(kind: u8) {
        let valid = kind == KIND_SYSTEM_HALT || kind == KIND_SYSTEM_RESUME || kind == KIND_FUND_UPDATE || kind == KIND_X_MINT || kind == KIND_X_BURN;
        assert!(valid, errors::E_INVALID_ARGUMENT);
    }

    public fun validate_governance_action(action_type: u8) {
        let valid = action_type == KIND_SYSTEM_HALT || action_type == KIND_SYSTEM_RESUME || action_type == KIND_FUND_UPDATE;
        assert!(valid, errors::E_INVALID_ARGUMENT);
    }

    public fun kind(payload: &BridgePayload): u8 { payload.kind }
    public fun proof_root(payload: &BridgePayload): vector<u8> { copy payload.proof_root }
    public fun target_module_bytes(payload: &BridgePayload): vector<u8> { *string::bytes(&payload.target_module) }
    public fun action_type(action: &GovernanceAction): u8 { action.action_type }
    public fun action_proof_root(action: &GovernanceAction): vector<u8> { copy action.proof_root }

    public fun kind_system_halt(): u8 { KIND_SYSTEM_HALT }
    public fun kind_system_resume(): u8 { KIND_SYSTEM_RESUME }
    public fun kind_fund_update(): u8 { KIND_FUND_UPDATE }
    public fun kind_x_mint(): u8 { KIND_X_MINT }
    public fun kind_x_burn(): u8 { KIND_X_BURN }
    public fun schema_v1(): u16 { SCHEMA_V1 }
    public fun xlayer_chain_id(): u64 { XLAYER_MAINNET_CHAIN_ID }
    public fun xlayer_testnet_chain_id(): u64 { XLAYER_TESTNET_CHAIN_ID }
    public fun ethereum_chain_id(): u64 { ETHEREUM_MAINNET_CHAIN_ID }
    public fun base_chain_id(): u64 { BASE_MAINNET_CHAIN_ID }
    public fun arbitrum_chain_id(): u64 { ARBITRUM_ONE_CHAIN_ID }
    public fun cardano_mainnet_network_magic(): u64 { CARDANO_MAINNET_NETWORK_MAGIC }
    public fun cardano_preprod_network_magic(): u64 { CARDANO_PREPROD_NETWORK_MAGIC }
    public fun web_relay_prod_domain_id(): u64 { WEB_RELAY_PROD_DOMAIN_ID }
    public fun web_relay_stage_domain_id(): u64 { WEB_RELAY_STAGE_DOMAIN_ID }
    public fun target_breaker(): String { string::utf8(TARGET_BREAKER) }
    public fun target_treasury(): String { string::utf8(TARGET_TREASURY) }
    public fun target_aoxc(): String { string::utf8(TARGET_AOXC) }
}
