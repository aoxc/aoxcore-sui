module aoxc::verifier_registry {
    use std::string::{Self, String};
    use std::vector;
    use aoxc::errors;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    const VERIFIER_ZK_LIGHT_CLIENT: vector<u8> = b"zk_light_client";
    const VERIFIER_SENTINEL_SIGNAL: vector<u8> = b"sentinel_signal";

    public struct VerifierRegistryAdminCap has key, store { id: UID }

    public struct VerifierRegistry has key {
        id: UID,
        enabled: Table<vector<u8>, bool>,
    }

    public struct VerifierStatusChanged has copy, drop {
        verifier: String,
        enabled: bool,
    }

    public fun validate_verifier(verifier: &String) {
        let b = string::bytes(verifier);
        assert!(b == VERIFIER_ZK_LIGHT_CLIENT || b == VERIFIER_SENTINEL_SIGNAL, errors::E_INVALID_ARGUMENT);
    }

    entry fun init(ctx: &mut TxContext) {
        let cap = VerifierRegistryAdminCap { id: object::new(ctx) };
        let registry = VerifierRegistry {
            id: object::new(ctx),
            enabled: table::new<vector<u8>, bool>(ctx),
        };
        sui::transfer::share_object(registry);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun set_verifier(
        _cap: &VerifierRegistryAdminCap,
        registry: &mut VerifierRegistry,
        verifier: String,
        is_enabled: bool,
    ) {
        validate_verifier(&verifier);
        let key = *string::bytes(&verifier);
        if (table::contains(&registry.enabled, &key)) {
            *table::borrow_mut(&mut registry.enabled, key) = is_enabled;
        } else {
            table::add(&mut registry.enabled, key, is_enabled);
        };
        event::emit(VerifierStatusChanged { verifier, enabled: is_enabled });
    }

    public fun assert_enabled(registry: &VerifierRegistry, verifier: String) {
        validate_verifier(&verifier);
        let key = *string::bytes(&verifier);
        assert!(table::contains(&registry.enabled, &key), errors::E_NOT_FOUND);
        assert!(*table::borrow(&registry.enabled, key), errors::E_POLICY_LIMIT);
    }

    public fun verifier_zk_light_client(): String { string::utf8(VERIFIER_ZK_LIGHT_CLIENT) }
    public fun verifier_sentinel_signal(): String { string::utf8(VERIFIER_SENTINEL_SIGNAL) }
}
