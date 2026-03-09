module aoxc::bridge_payload {
    use std::bcs;
    use std::string::String;
    use std::vector;
    use aoxc::errors;

    const KIND_SYSTEM_HALT: u8 = 1;
    const KIND_SYSTEM_RESUME: u8 = 2;
    const KIND_FUND_UPDATE: u8 = 3;

    /// Typed bridge payload schema (replaces raw bytes payload).
    public struct BridgePayload has copy, drop, store {
        kind: u8,
        ref_id: u64,
        note: String,
        proof_root: vector<u8>,
    }

    /// Typed DAO action schema.
    public struct GovernanceAction has copy, drop, store {
        action_type: u8,
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    }

    /// Explicitly decodable payload for pause command.
    public struct PausePayload has copy, drop, store {
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    }

    /// Explicitly decodable payload for resume command.
    public struct ResumePayload has copy, drop, store {
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    }

    /// Explicitly decodable payload for treasury/fund policy updates.
    public struct FundUpdatePayload has copy, drop, store {
        ref_id: u64,
        policy_name: String,
        proof_root: vector<u8>,
    }

    public fun new_bridge_payload(
        kind: u8,
        ref_id: u64,
        note: String,
        proof_root: vector<u8>,
    ): BridgePayload {
        validate_payload_kind(kind);
        assert!(vector::length(&proof_root) > 0, errors::E_EMPTY_HASH);
        BridgePayload { kind, ref_id, note, proof_root }
    }

    public fun new_governance_action(
        action_type: u8,
        ref_id: u64,
        reason: String,
        proof_root: vector<u8>,
    ): GovernanceAction {
        validate_governance_action(action_type);
        assert!(vector::length(&proof_root) > 0, errors::E_EMPTY_HASH);
        GovernanceAction { action_type, ref_id, reason, proof_root }
    }


    public fun encode_pause_payload(ref_id: u64, reason: String, proof_root: vector<u8>): vector<u8> {
        let payload = PausePayload { ref_id, reason, proof_root };
        bcs::to_bytes(&payload)
    }

    public fun encode_resume_payload(ref_id: u64, reason: String, proof_root: vector<u8>): vector<u8> {
        let payload = ResumePayload { ref_id, reason, proof_root };
        bcs::to_bytes(&payload)
    }

    public fun encode_fund_update_payload(ref_id: u64, policy_name: String, proof_root: vector<u8>): vector<u8> {
        let payload = FundUpdatePayload { ref_id, policy_name, proof_root };
        bcs::to_bytes(&payload)
    }

    public fun decode_pause_payload(raw: vector<u8>): BridgePayload {
        let decoded = bcs::from_bytes<PausePayload>(&raw);
        new_bridge_payload(KIND_SYSTEM_HALT, decoded.ref_id, decoded.reason, decoded.proof_root)
    }

    public fun decode_resume_payload(raw: vector<u8>): BridgePayload {
        let decoded = bcs::from_bytes<ResumePayload>(&raw);
        new_bridge_payload(KIND_SYSTEM_RESUME, decoded.ref_id, decoded.reason, decoded.proof_root)
    }

    public fun decode_fund_update_payload(raw: vector<u8>): BridgePayload {
        let decoded = bcs::from_bytes<FundUpdatePayload>(&raw);
        new_bridge_payload(KIND_FUND_UPDATE, decoded.ref_id, decoded.policy_name, decoded.proof_root)
    }

    public fun decode_governance_action(raw: vector<u8>): GovernanceAction {
        let decoded = bcs::from_bytes<GovernanceAction>(&raw);
        validate_governance_action(decoded.action_type);
        assert!(vector::length(&decoded.proof_root) > 0, errors::E_EMPTY_HASH);
        decoded
    }

    public fun validate_payload_kind(kind: u8) {
        let valid = kind == KIND_SYSTEM_HALT || kind == KIND_SYSTEM_RESUME || kind == KIND_FUND_UPDATE;
        assert!(valid, errors::E_INVALID_ARGUMENT);
    }

    public fun validate_governance_action(action_type: u8) {
        let valid = action_type == KIND_SYSTEM_HALT || action_type == KIND_SYSTEM_RESUME;
        assert!(valid, errors::E_INVALID_ARGUMENT);
    }

    public fun kind(payload: &BridgePayload): u8 { payload.kind }
    public fun proof_root(payload: &BridgePayload): vector<u8> { copy payload.proof_root }
    public fun action_type(action: &GovernanceAction): u8 { action.action_type }
    public fun action_proof_root(action: &GovernanceAction): vector<u8> { copy action.proof_root }

    public fun kind_system_halt(): u8 { KIND_SYSTEM_HALT }
    public fun kind_system_resume(): u8 { KIND_SYSTEM_RESUME }
    public fun kind_fund_update(): u8 { KIND_FUND_UPDATE }
}
