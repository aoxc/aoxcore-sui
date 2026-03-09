module aoxc::bridge_payload {
    use std::bcs;
    use std::string::{Self, String};
    use std::vector;
    use aoxc::errors;

    const SCHEMA_V1: u16 = 1;
    const XLAYER_EVM_CHAIN_ID: u64 = 196;

    const KIND_SYSTEM_HALT: u8 = 1;
    const KIND_SYSTEM_RESUME: u8 = 2;
    const KIND_FUND_UPDATE: u8 = 3;
    const KIND_X_MINT: u8 = 4;
    const KIND_X_BURN: u8 = 5;

    const TARGET_BREAKER: vector<u8> = b"circuit_breaker";
    const TARGET_TREASURY: vector<u8> = b"treasury";
    const TARGET_AOXC: vector<u8> = b"aoxc";

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

    public fun validate_schema_version(version: u16) {
        assert!(version == SCHEMA_V1, errors::E_SCHEMA_VERSION);
    }

    public fun validate_chain_id(chain_id: u64) {
        assert!(chain_id == XLAYER_EVM_CHAIN_ID, errors::E_CHAIN_ID_INVALID);
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

    public fun decode_governance_action(raw: vector<u8>): GovernanceAction {
        let decoded = bcs::from_bytes<GovernanceAction>(&raw);
        validate_schema_version(decoded.schema_version);
        validate_governance_action(decoded.action_type);
        validate_target_module(&decoded.target_module, decoded.action_type);
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
    public fun action_type(action: &GovernanceAction): u8 { action.action_type }
    public fun action_proof_root(action: &GovernanceAction): vector<u8> { copy action.proof_root }

    public fun kind_system_halt(): u8 { KIND_SYSTEM_HALT }
    public fun kind_system_resume(): u8 { KIND_SYSTEM_RESUME }
    public fun kind_fund_update(): u8 { KIND_FUND_UPDATE }
    public fun kind_x_mint(): u8 { KIND_X_MINT }
    public fun kind_x_burn(): u8 { KIND_X_BURN }
    public fun schema_v1(): u16 { SCHEMA_V1 }
    public fun xlayer_chain_id(): u64 { XLAYER_EVM_CHAIN_ID }
    public fun target_breaker(): String { string::utf8(TARGET_BREAKER) }
    public fun target_treasury(): String { string::utf8(TARGET_TREASURY) }
    public fun target_aoxc(): String { string::utf8(TARGET_AOXC) }
}
