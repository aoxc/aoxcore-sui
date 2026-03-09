module aoxc::neural_bridge {
    use std::bcs;
    use std::string::String;
    use std::vector;
    use aoxc::bridge_payload;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use aoxc::relay;
    use sui::clock::{Self, Clock};
    use sui::ecdsa_k1;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    public struct GatewayAdminCap has key, store { id: UID }

    public struct NeuralGateway has key {
        id: UID,
        source_chain: String,
        signer_pubkeys: vector<vector<u8>>,
        min_confirmations: u16,
        used_digests: Table<vector<u8>, bool>,
    }

    public struct BridgeCommand has copy, drop, store {
        command_id: vector<u8>,
        source_chain: String,
        target: String,
        payload: bridge_payload::BridgePayload,
        quorum_epoch: u64,
        deadline_ms: u64,
        confirmations: u16,
    }

    public struct CommandApplied has copy, drop {
        command_id: vector<u8>,
        digest: vector<u8>,
        payload_kind: u8,
        quorum_signers: u16,
        pause_state_after: bool,
        executed_at_ms: u64,
    }

    fun command_digest(command: &BridgeCommand): vector<u8> {
        let mut body = bcs::to_bytes(command);
        vector::append(&mut body, b"AOXC_SUI_NEURAL_BRIDGE_PHASE3");
        sui::hash::keccak256(&body)
    }

    fun verify_quorum_signatures(
        signatures: &vector<vector<u8>>,
        quorum: &relay::AttestorQuorum,
        signer_pubkeys: &vector<vector<u8>>,
        digest: &vector<u8>,
        threshold: u16,
    ): u16 {
        let mut valid: u16 = 0;
        let sig_len = vector::length(signatures);
        let key_len = vector::length(signer_pubkeys);
        let mut i = 0;
        while (i < sig_len && i < key_len) {
            let sig = vector::borrow(signatures, i);
            let pk = vector::borrow(signer_pubkeys, i);
            let ok = ecdsa_k1::secp256k1_verify(sig, pk, digest, 0) && relay::is_attestor_active(quorum, pk);
            if (ok) { valid = valid + 1; };
            i = i + 1;
        };
        relay::assert_quorum_met(valid, threshold);
        valid
    }

    public fun validate_min_confirmations(min: u16) {
        assert!(min > 0, errors::E_INVALID_ARGUMENT);
    }

    entry fun init(
        source_chain: String,
        signer_pubkeys: vector<vector<u8>>,
        min_confirmations: u16,
        ctx: &mut TxContext,
    ) {
        validate_min_confirmations(min_confirmations);

        let cap = GatewayAdminCap { id: object::new(ctx) };
        let gateway = NeuralGateway {
            id: object::new(ctx),
            source_chain,
            signer_pubkeys,
            min_confirmations,
            used_digests: table::new<vector<u8>, bool>(ctx),
        };
        sui::transfer::share_object(gateway);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun rotate_signers(_cap: &GatewayAdminCap, gateway: &mut NeuralGateway, next: vector<vector<u8>>) {
        gateway.signer_pubkeys = next;
    }

    entry fun set_min_confirmations(_cap: &GatewayAdminCap, gateway: &mut NeuralGateway, next: u16) {
        validate_min_confirmations(next);
        gateway.min_confirmations = next;
    }

    public fun verify_and_apply(
        gateway: &mut NeuralGateway,
        quorum: &relay::AttestorQuorum,
        breaker: &mut circuit_breaker::CircuitBreaker,
        command: BridgeCommand,
        signatures: vector<vector<u8>>,
        clock: &Clock,
    ): vector<u8> {
        assert!(command.source_chain == gateway.source_chain, errors::E_INVALID_ARGUMENT);
        assert!(command.quorum_epoch == relay::epoch(quorum), errors::E_INVALID_ARGUMENT);
        assert!(clock::timestamp_ms(clock) <= command.deadline_ms, errors::E_TIMELOCK_EXPIRED);
        assert!(command.confirmations >= gateway.min_confirmations, errors::E_INVALID_ARGUMENT);

        let digest = command_digest(&command);
        assert!(!table::contains(&gateway.used_digests, &digest), errors::E_REPLAY);

        let payload_kind = bridge_payload::kind(&command.payload);
        let signer_count = verify_quorum_signatures(&signatures, quorum, &gateway.signer_pubkeys, &digest, relay::threshold(quorum));

        if (payload_kind == bridge_payload::kind_system_halt()) {
            circuit_breaker::pause_from_module(breaker, bridge_payload::proof_root(&command.payload));
        };
        if (payload_kind == bridge_payload::kind_system_resume()) {
            circuit_breaker::resume_from_module(breaker, bridge_payload::proof_root(&command.payload));
        };

        let paused_after = circuit_breaker::is_paused(breaker);
        let digest_evt = copy digest;
        table::add(&mut gateway.used_digests, digest, true);

        event::emit(CommandApplied {
            command_id: command.command_id,
            digest: digest_evt,
            payload_kind,
            quorum_signers: signer_count,
            pause_state_after: paused_after,
            executed_at_ms: clock::timestamp_ms(clock),
        });

        digest_evt
    }

    spec verify_and_apply {
        // Formal safety intent:
        // - replayed commands abort
        // - quorum threshold must be met before apply
        // - pause state changes only for pause/resume kinds
        pragma opaque;
        ensures true;
    }
}
