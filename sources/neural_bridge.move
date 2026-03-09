module aoxc::neural_bridge {
    use std::bcs;
    use std::string::String;
    use std::vector;
    use sui::clock::{Self, Clock};
    use sui::ecdsa_k1;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    const E_INVALID_SOURCE: u64 = 1;
    const E_EXPIRED: u64 = 2;
    const E_REPLAY: u64 = 3;
    const E_BAD_SIGNATURE: u64 = 4;
    const E_CONF_TOO_LOW: u64 = 5;

    /// Governance authority (timelock + council) for signer lifecycle.
    public struct GatewayAdminCap has key, store { id: UID }

    /// Shared gateway state coordinating XLayer -> Sui command settlement.
    public struct NeuralGateway has key {
        id: UID,
        source_chain: String,
        signer_pubkey: vector<u8>,
        min_confirmations: u16,
        used_digests: Table<vector<u8>, bool>,
    }

    /// Canonical cross-chain envelope.
    public struct BridgeCommand has copy, drop, store {
        command_id: vector<u8>,
        source_chain: String,
        target: String,
    use std::option;
    use std::vector;
    use std::bcs;
    use std::string::{Self, String};
    use sui::clock::{Self, Clock};
    use sui::ecdsa_k1;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};

    const ENotAuthorized: u64 = 1;
    const EExpiredPayload: u64 = 2;
    const EReplayDetected: u64 = 3;
    const EInvalidSignature: u64 = 4;
    const EInvalidBridgeSource: u64 = 5;

    /// Admin capability for governance / timelock executors.
    public struct GatewayAdminCap has key, store {
        id: UID,
    }

    /// Global gateway state used for cross-chain verification.
    public struct NeuralGateway has key {
        id: UID,
        signer_pubkey: vector<u8>,
        bridge_source: String,
        min_confirmations: u16,
        nonce_book: vector<vector<u8>>,
    }

    /// Canonical payload received from XLayer sentinel/bridge verifier.
    public struct BridgeCommand has copy, drop, store {
        command_id: vector<u8>,
        source_chain: String,
        target_module: String,
        command_type: u8,
        payload: vector<u8>,
        nonce: vector<u8>,
        deadline_ms: u64,
        confirmations: u16,
    }

    public struct CommandExecuted has copy, drop {
        command_id: vector<u8>,
        digest: vector<u8>,
        target: String,
        command_type: u8,
        executed_at_ms: u64,
    }

    fun command_digest(command: &BridgeCommand): vector<u8> {
        let mut body = bcs::to_bytes(command);
        vector::append(&mut body, b"AOXC_SUI_NEURAL_BRIDGE_V2");
        sui::hash::keccak256(&body)
    }

    entry fun init(
        source_chain: String,
        signer_pubkey: vector<u8>,
    }

    public struct CommandAccepted has copy, drop {
        command_id: vector<u8>,
        target_module: String,
        command_type: u8,
        accepted_at_ms: u64,
    }

    fun nonce_seen(book: &vector<vector<u8>>, nonce: &vector<u8>): bool {
        let len = vector::length(book);
        let mut i = 0;
        while (i < len) {
            if (*vector::borrow(book, i) == *nonce) {
                return true
            };
            i = i + 1;
        };
        false
    }

    fun hash_command(command: &BridgeCommand): vector<u8> {
        // Structured hash to mirror EIP-712 style domain separation semantics on Sui.
        let domain = b"AOXC_NEURAL_GATEWAY_V1";
        let mut bytes = bcs::to_bytes(command);
        vector::append(&mut bytes, domain);
        sui::hash::keccak256(&bytes)
    }

    entry fun init(
        signer_pubkey: vector<u8>,
        bridge_source: String,
        min_confirmations: u16,
        ctx: &mut TxContext,
    ) {
        let cap = GatewayAdminCap { id: object::new(ctx) };
        let gateway = NeuralGateway {
            id: object::new(ctx),
            source_chain,
            signer_pubkey,
            min_confirmations,
            used_digests: table::new<vector<u8>, bool>(ctx),
            signer_pubkey,
            bridge_source,
            min_confirmations,
            nonce_book: vector::empty<vector<u8>>(),
        };

        sui::transfer::share_object(gateway);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun rotate_signer(_cap: &GatewayAdminCap, gateway: &mut NeuralGateway, new_pubkey: vector<u8>) {
        gateway.signer_pubkey = new_pubkey;
    }

    entry fun set_min_confirmations(_cap: &GatewayAdminCap, gateway: &mut NeuralGateway, min_confirmations: u16) {
        gateway.min_confirmations = min_confirmations;
    }

    /// Verifies signature + replay + expiry and returns digest for downstream modules.
    public fun verify_command(
    entry fun rotate_signer(
        cap: &GatewayAdminCap,
        gateway: &mut NeuralGateway,
        next_pubkey: vector<u8>,
    ) {
        let _ = cap;
        gateway.signer_pubkey = next_pubkey;
    }

    entry fun set_source(
        cap: &GatewayAdminCap,
        gateway: &mut NeuralGateway,
        next_source: String,
    ) {
        let _ = cap;
        gateway.bridge_source = next_source;
    }

    public fun verify_and_lock(
        gateway: &mut NeuralGateway,
        command: BridgeCommand,
        signature: vector<u8>,
        clock: &Clock,
    ): vector<u8> {
        assert!(command.source_chain == gateway.source_chain, E_INVALID_SOURCE);
        assert!(clock::timestamp_ms(clock) <= command.deadline_ms, E_EXPIRED);
        assert!(command.confirmations >= gateway.min_confirmations, E_CONF_TOO_LOW);

        let digest = command_digest(&command);
        assert!(!table::contains(&gateway.used_digests, &digest), E_REPLAY);

        let ok = ecdsa_k1::secp256k1_verify(&signature, &gateway.signer_pubkey, &digest, 0);
        assert!(ok, E_BAD_SIGNATURE);

        let digest_for_event = copy digest;
        table::add(&mut gateway.used_digests, copy digest, true);

        event::emit(CommandExecuted {
            command_id: command.command_id,
            digest: digest_for_event,
            target: command.target,
            command_type: command.command_type,
            executed_at_ms: clock::timestamp_ms(clock),
        });

        digest
    }

    public fun min_confirmations(gateway: &NeuralGateway): u16 { gateway.min_confirmations }
    ): BridgeCommand {
        assert!(command.source_chain == gateway.bridge_source, EInvalidBridgeSource);
        assert!(clock::timestamp_ms(clock) <= command.deadline_ms, EExpiredPayload);
        assert!(!nonce_seen(&gateway.nonce_book, &command.nonce), EReplayDetected);

        let digest = hash_command(&command);
        let ok = ecdsa_k1::secp256k1_verify(&signature, &gateway.signer_pubkey, &digest, 0);
        assert!(ok, EInvalidSignature);

        vector::push_back(&mut gateway.nonce_book, command.nonce);

        event::emit(CommandAccepted {
            command_id: command.command_id,
            target_module: command.target_module,
            command_type: command.command_type,
            accepted_at_ms: clock::timestamp_ms(clock),
        });
        command
    }

    public fun min_confirmations(gateway: &NeuralGateway): u16 {
        gateway.min_confirmations
    }

    public fun bridge_source(gateway: &NeuralGateway): String {
        gateway.bridge_source
    }
}
