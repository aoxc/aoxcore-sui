module aoxc::zk_light_client {
    use std::bcs;
    use std::vector;
    use aoxc::errors;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    public struct ZkVerifierAdminCap has key, store { id: UID }

    public struct ZkLightClient has key {
        id: UID,
        latest_height: u64,
        finalized_headers: Table<u64, vector<u8>>,
        consumed_tx_roots: Table<vector<u8>, bool>,
    }

    public struct HeaderFinalized has copy, drop {
        height: u64,
        block_root: vector<u8>,
    }

    public struct TxProofVerified has copy, drop {
        height: u64,
        tx_leaf: vector<u8>,
        block_root: vector<u8>,
    }

    struct HeaderEnvelope has copy, drop, store {
        height: u64,
        parent_root: vector<u8>,
        tx_root: vector<u8>,
        state_root: vector<u8>,
    }

    fun hash_pair(left: vector<u8>, right: vector<u8>): vector<u8> {
        let mut acc = left;
        vector::append(&mut acc, right);
        sui::hash::keccak256(&acc)
    }

    fun compute_header_root(header: &HeaderEnvelope): vector<u8> {
        let raw = bcs::to_bytes(header);
        sui::hash::keccak256(&raw)
    }

    fun verify_merkle_path(leaf: vector<u8>, siblings: vector<vector<u8>>, path_is_left: vector<bool>): vector<u8> {
        assert!(vector::length(&siblings) == vector::length(&path_is_left), errors::E_LENGTH_MISMATCH);
        let mut acc = leaf;
        let mut i = 0;
        while (i < vector::length(&siblings)) {
            let sibling = *vector::borrow(&siblings, i);
            let is_left = *vector::borrow(&path_is_left, i);
            if (is_left) {
                acc = hash_pair(sibling, acc);
            } else {
                acc = hash_pair(acc, sibling);
            };
            i = i + 1;
        };
        acc
    }

    entry fun init(ctx: &mut TxContext) {
        let cap = ZkVerifierAdminCap { id: object::new(ctx) };
        let client = ZkLightClient {
            id: object::new(ctx),
            latest_height: 0,
            finalized_headers: table::new<u64, vector<u8>>(ctx),
            consumed_tx_roots: table::new<vector<u8>, bool>(ctx),
        };
        sui::transfer::share_object(client);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun finalize_header(
        _cap: &ZkVerifierAdminCap,
        client: &mut ZkLightClient,
        height: u64,
        parent_root: vector<u8>,
        tx_root: vector<u8>,
        state_root: vector<u8>,
    ) {
        assert!(height > client.latest_height, errors::E_INVALID_ARGUMENT);
        assert!(vector::length(&tx_root) > 0, errors::E_EMPTY_HASH);
        assert!(vector::length(&state_root) > 0, errors::E_EMPTY_HASH);
        let env = HeaderEnvelope { height, parent_root, tx_root, state_root };
        let root = compute_header_root(&env);
        table::add(&mut client.finalized_headers, height, copy root);
        client.latest_height = height;
        event::emit(HeaderFinalized { height, block_root: root });
    }

    public fun assert_tx_inclusion(
        client: &mut ZkLightClient,
        height: u64,
        tx_leaf: vector<u8>,
        siblings: vector<vector<u8>>,
        path_is_left: vector<bool>,
    ): vector<u8> {
        assert!(table::contains(&client.finalized_headers, height), errors::E_NOT_FOUND);
        let block_root = *table::borrow(&client.finalized_headers, height);
        let calc = verify_merkle_path(tx_leaf, siblings, path_is_left);
        assert!(calc == block_root, errors::E_INVALID_ARGUMENT);
        assert!(!table::contains(&client.consumed_tx_roots, &calc), errors::E_REPLAY);
        table::add(&mut client.consumed_tx_roots, copy calc, true);
        event::emit(TxProofVerified { height, tx_leaf: copy calc, block_root: copy block_root });
        block_root
    }
}
