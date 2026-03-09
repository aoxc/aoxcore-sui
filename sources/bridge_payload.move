module aoxc::bridge_payload {
    use std::string::String;
    use std::vector;
    use aoxc::errors;

    const KIND_SYSTEM_HALT: u8 = 1;
    const KIND_SYSTEM_RESUME: u8 = 2;
    const KIND_TREASURY_POLICY: u8 = 3;

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

    public fun validate_payload_kind(kind: u8) {
        let valid = kind == KIND_SYSTEM_HALT || kind == KIND_SYSTEM_RESUME || kind == KIND_TREASURY_POLICY;
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
}
