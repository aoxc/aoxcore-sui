module aoxc::neural_bridge {
    use std::bcs;
    use std::string::String;
    use std::vector;
    use aoxc::errors;
    use sui::clock::{Self, Clock};
    use sui::ecdsa_k1;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    const COMMAND_SYSTEM_HALT: u8 = 250;
    const COMMAND_SYSTEM_RESUME: u8 = 251;

    public struct GatewayAdminCap has key, store { id: UID }

    /// Shared bridge verifier and protocol-wide circuit breaker.
    public struct NeuralGateway has key {
        id: UID,
        source_chain: String,
        signer_pubkey: vector<u8>,
        min_confirmations: u16,
        paused: bool,
        used_digests: Table<vector<u8>, bool>,
    }

    public struct BridgeCommand has copy, drop, store {
        command_id: vector<u8>,
        source_chain: String,
        target: String,
        command_type: u8,
        payload: vector<u8>,
        deadline_ms: u64,
        confirmations: u16,
    }

    public struct CommandApplied has copy, drop {
        command_id: vector<u8>,
        digest: vector<u8>,
        command_type: u8,
        paused: bool,
        executed_at_ms: u64,
    }

    fun command_digest(command: &BridgeCommand): vector<u8> {
        let mut body = bcs::to_bytes(command);
        vector::append(&mut body, b"AOXC_SUI_NEURAL_BRIDGE_V3");
        sui::hash::keccak256(&body)
    }

    entry fun init(source_chain: String, signer_pubkey: vector<u8>, min_confirmations: u16, ctx: &mut TxContext) {
        let cap = GatewayAdminCap { id: object::new(ctx) };
        let gateway = NeuralGateway {
            id: object::new(ctx),
            source_chain,
            signer_pubkey,
            min_confirmations,
            paused: false,
            used_digests: table::new<vector<u8>, bool>(ctx),
        };
        sui::transfer::share_object(gateway);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun rotate_signer(_cap: &GatewayAdminCap, gateway: &mut NeuralGateway, next: vector<u8>) {
        gateway.signer_pubkey = next;
    }

    /// Verifies command and applies atomic pause/resume directives from XLayer.
    public fun verify_and_apply(
        gateway: &mut NeuralGateway,
        command: BridgeCommand,
        signature: vector<u8>,
        clock: &Clock,
    ): vector<u8> {
        assert!(command.source_chain == gateway.source_chain, errors::E_INVALID_ARGUMENT);
        assert!(clock::timestamp_ms(clock) <= command.deadline_ms, errors::E_TIMELOCK_EXPIRED);
        assert!(command.confirmations >= gateway.min_confirmations, errors::E_INVALID_ARGUMENT);

        let digest = command_digest(&command);
        assert!(!table::contains(&gateway.used_digests, &digest), errors::E_REPLAY);

        let ok = ecdsa_k1::secp256k1_verify(&signature, &gateway.signer_pubkey, &digest, 0);
        assert!(ok, errors::E_SIGNATURE_INVALID);

        if (command.command_type == COMMAND_SYSTEM_HALT) { gateway.paused = true; };
        if (command.command_type == COMMAND_SYSTEM_RESUME) { gateway.paused = false; };

        let digest_evt = copy digest;
        table::add(&mut gateway.used_digests, digest, true);
        event::emit(CommandApplied {
            command_id: command.command_id,
            digest: digest_evt,
            command_type: command.command_type,
            paused: gateway.paused,
            executed_at_ms: clock::timestamp_ms(clock),
        });

        digest_evt
    }

    public fun assert_transfers_enabled(gateway: &NeuralGateway) {
        assert!(!gateway.paused, errors::E_PROTOCOL_PAUSED);
    }

    public fun is_paused(gateway: &NeuralGateway): bool { gateway.paused }
}
