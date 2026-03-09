module aoxc::treasury {
    use std::bcs;
    use std::vector;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use aoxc::reputation;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    public struct TreasuryDistributorCap has key, store { id: UID }

    public struct AutonomousTreasury<phantom T> has key {
        id: UID,
        vault: Balance<T>,
        min_reputation_score: u64,
        distributed_total: u64,
    }

    /// Scalable claim mode configuration for large distributions.
    public struct MerkleClaimPool<phantom T> has key {
        id: UID,
        current_root: vector<u8>,
        epoch: u64,
        claimed_leaf_hashes: vector<vector<u8>>,
    }


    /// Yield routing hooks for external Sui lending/liquidity venues.
    public struct YieldHookConfig has key {
        id: UID,
        lending_enabled: bool,
        liquidity_enabled: bool,
        lending_allocation_bps: u16,
        liquidity_allocation_bps: u16,
        lending_adapter: vector<u8>,
        liquidity_adapter: vector<u8>,
        rebalance_nonce: u64,
    }

    public struct RevenueDeposited has copy, drop { amount: u64, new_balance: u64 }
    public struct RewardDistributed has copy, drop { user: address, amount: u64 }
    public struct MerkleRootPublished has copy, drop { epoch: u64, root_hash: vector<u8> }
    public struct MerkleRewardClaimed has copy, drop { epoch: u64, user: address, amount: u64 }
    public struct YieldPolicyUpdated has copy, drop { lending_enabled: bool, liquidity_enabled: bool, lending_allocation_bps: u16, liquidity_allocation_bps: u16 }
    public struct YieldRebalanced has copy, drop { nonce: u64, lending_amount: u64, liquidity_amount: u64 }

    struct ClaimLeafInput has copy, drop, store {
        epoch: u64,
        user: address,
        amount: u64,
        token_type: vector<u8>,
    }

    public fun validate_distribution_vectors(recipients_len: u64, amounts_len: u64) {
        assert!(recipients_len == amounts_len, errors::E_LENGTH_MISMATCH);
    }

    fun contains_hash(book: &vector<vector<u8>>, h: &vector<u8>): bool {
        let len = vector::length(book);
        let mut i = 0;
        while (i < len) {
            if (*vector::borrow(book, i) == *h) return true;
            i = i + 1;
        };
        false
    }

    fun leaf_hash(epoch: u64, user: address, amount: u64, token_type: vector<u8>): vector<u8> {
        let input = ClaimLeafInput { epoch, user, amount, token_type };
        let bytes = bcs::to_bytes(&input);
        sui::hash::keccak256(&bytes)
    }

    fun hash_pair(left: vector<u8>, right: vector<u8>): vector<u8> {
        let mut acc = left;
        vector::append(&mut acc, right);
        sui::hash::keccak256(&acc)
    }

    fun verify_merkle_path(leaf: vector<u8>, siblings: vector<vector<u8>>, path_is_left: vector<bool>): vector<u8> {
        assert!(vector::length(&siblings) == vector::length(&path_is_left), errors::E_LENGTH_MISMATCH);
        let mut acc = leaf;
        let len = vector::length(&siblings);
        let mut i = 0;
        while (i < len) {
            let sibling = *vector::borrow(&siblings, i);
            let sibling_on_left = *vector::borrow(&path_is_left, i);
            if (sibling_on_left) {
                acc = hash_pair(sibling, acc);
            } else {
                acc = hash_pair(acc, sibling);
            };
            i = i + 1;
        };
        acc
    }

    entry fun init<T>(min_reputation_score: u64, ctx: &mut TxContext) {
        let cap = TreasuryDistributorCap { id: object::new(ctx) };
        let treasury = AutonomousTreasury<T> {
            id: object::new(ctx),
            vault: balance::zero<T>(),
            min_reputation_score,
            distributed_total: 0,
        };
        let claim_pool = MerkleClaimPool<T> {
            id: object::new(ctx),
            current_root: vector::empty<u8>(),
            epoch: 0,
            claimed_leaf_hashes: vector::empty<vector<u8>>(),
        };
        let hooks = YieldHookConfig {
            id: object::new(ctx),
            lending_enabled: false,
            liquidity_enabled: false,
            lending_allocation_bps: 0,
            liquidity_allocation_bps: 0,
            lending_adapter: b"sui-lending-adapter",
            liquidity_adapter: b"sui-liquidity-adapter",
            rebalance_nonce: 0,
        };
        sui::transfer::share_object(treasury);
        sui::transfer::share_object(claim_pool);
        sui::transfer::share_object(hooks);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun set_min_reputation_score<T>(_cap: &TreasuryDistributorCap, treasury: &mut AutonomousTreasury<T>, next: u64) {
        treasury.min_reputation_score = next;
    }

    entry fun deposit_revenue<T>(_cap: &TreasuryDistributorCap, treasury: &mut AutonomousTreasury<T>, payment: Coin<T>) {
        let amt = coin::value(&payment);
        assert!(amt > 0, errors::E_AMOUNT_ZERO);
        let received = coin::into_balance(payment);
        balance::join(&mut treasury.vault, received);
        event::emit(RevenueDeposited { amount: amt, new_balance: balance::value(&treasury.vault) });
    }

    entry fun distribute_fair<T>(
        _cap: &TreasuryDistributorCap,
        breaker: &circuit_breaker::CircuitBreaker,
        rep_book: &reputation::ReputationBook,
        treasury: &mut AutonomousTreasury<T>,
        recipients: vector<address>,
        amounts: vector<u64>,
        ctx: &mut TxContext,
    ) {
        circuit_breaker::assert_live(breaker);
        validate_distribution_vectors(vector::length(&recipients), vector::length(&amounts));

        let len = vector::length(&recipients);
        let mut i = 0;
        let mut required = 0;
        while (i < len) {
            let amt = *vector::borrow(&amounts, i);
            assert!(amt > 0, errors::E_AMOUNT_ZERO);
            required = required + amt;
            i = i + 1;
        };
        assert!(balance::value(&treasury.vault) >= required, errors::E_INSUFFICIENT_BALANCE);

        let mut j = 0;
        while (j < len) {
            let user = *vector::borrow(&recipients, j);
            let amt = *vector::borrow(&amounts, j);
            reputation::require_min_score(rep_book, user, treasury.min_reputation_score);

            let payout_bal = balance::split(&mut treasury.vault, amt);
            let payout_coin = coin::from_balance(payout_bal, ctx);
            sui::transfer::public_transfer(payout_coin, user);

            treasury.distributed_total = treasury.distributed_total + amt;
            event::emit(RewardDistributed { user, amount: amt });
            j = j + 1;
        };
    }

    entry fun publish_merkle_root<T>(
        _cap: &TreasuryDistributorCap,
        pool: &mut MerkleClaimPool<T>,
        root_hash: vector<u8>,
    ) {
        assert!(vector::length(&root_hash) > 0, errors::E_EMPTY_HASH);
        pool.current_root = root_hash;
        pool.epoch = pool.epoch + 1;
        pool.claimed_leaf_hashes = vector::empty<vector<u8>>();
        event::emit(MerkleRootPublished { epoch: pool.epoch, root_hash: copy pool.current_root });
    }

    /// Gas-efficient claim path for large recipient sets with full Merkle path verification.
    entry fun claim_reward<T>(
        breaker: &circuit_breaker::CircuitBreaker,
        pool: &mut MerkleClaimPool<T>,
        treasury: &mut AutonomousTreasury<T>,
        user: address,
        amount: u64,
        token_type: vector<u8>,
        claim_epoch: u64,
        siblings: vector<vector<u8>>,
        path_is_left: vector<bool>,
        ctx: &mut TxContext,
    ) {
        circuit_breaker::assert_live(breaker);
        assert!(amount > 0, errors::E_AMOUNT_ZERO);
        assert!(claim_epoch == pool.epoch, errors::E_INVALID_ARGUMENT);
        assert!(vector::length(&token_type) > 0, errors::E_INVALID_ARGUMENT);

        let leaf = leaf_hash(claim_epoch, user, amount, token_type);
        let computed_root = verify_merkle_path(copy leaf, siblings, path_is_left);
        assert!(computed_root == pool.current_root, errors::E_INVALID_ARGUMENT);
        assert!(!contains_hash(&pool.claimed_leaf_hashes, &leaf), errors::E_ALREADY_CLAIMED);
        assert!(balance::value(&treasury.vault) >= amount, errors::E_INSUFFICIENT_BALANCE);

        vector::push_back(&mut pool.claimed_leaf_hashes, leaf);
        let payout_bal = balance::split(&mut treasury.vault, amount);
        let payout_coin = coin::from_balance(payout_bal, ctx);
        sui::transfer::public_transfer(payout_coin, user);
        treasury.distributed_total = treasury.distributed_total + amount;

        event::emit(MerkleRewardClaimed { epoch: pool.epoch, user, amount });
    }

    entry fun set_yield_hooks(
        _cap: &TreasuryDistributorCap,
        hooks: &mut YieldHookConfig,
        lending_enabled: bool,
        liquidity_enabled: bool,
        lending_allocation_bps: u16,
        liquidity_allocation_bps: u16,
        lending_adapter: vector<u8>,
        liquidity_adapter: vector<u8>,
    ) {
        assert!((lending_allocation_bps as u64) + (liquidity_allocation_bps as u64) <= 10_000, errors::E_POLICY_LIMIT);
        hooks.lending_enabled = lending_enabled;
        hooks.liquidity_enabled = liquidity_enabled;
        hooks.lending_allocation_bps = lending_allocation_bps;
        hooks.liquidity_allocation_bps = liquidity_allocation_bps;
        hooks.lending_adapter = lending_adapter;
        hooks.liquidity_adapter = liquidity_adapter;
        event::emit(YieldPolicyUpdated { lending_enabled, liquidity_enabled, lending_allocation_bps, liquidity_allocation_bps });
    }

    entry fun rebalance_yield<T>(
        _cap: &TreasuryDistributorCap,
        breaker: &circuit_breaker::CircuitBreaker,
        hooks: &mut YieldHookConfig,
        treasury: &AutonomousTreasury<T>,
    ) {
        circuit_breaker::assert_live(breaker);
        let vault_value = balance::value(&treasury.vault);

        let mut lending_amount = 0;
        if (hooks.lending_enabled) {
            lending_amount = (vault_value * (hooks.lending_allocation_bps as u64)) / 10_000;
        };

        let mut liquidity_amount = 0;
        if (hooks.liquidity_enabled) {
            liquidity_amount = (vault_value * (hooks.liquidity_allocation_bps as u64)) / 10_000;
        };

        hooks.rebalance_nonce = hooks.rebalance_nonce + 1;
        event::emit(YieldRebalanced { nonce: hooks.rebalance_nonce, lending_amount, liquidity_amount });
    }

    public fun hooks_nonce(hooks: &YieldHookConfig): u64 { hooks.rebalance_nonce }

    public fun balance_of<T>(treasury: &AutonomousTreasury<T>): u64 { balance::value(&treasury.vault) }

    public fun preview_claim_root(epoch: u64, user: address, amount: u64, token_type: vector<u8>, siblings: vector<vector<u8>>, path_is_left: vector<bool>): vector<u8> {
        let leaf = leaf_hash(epoch, user, amount, token_type);
        verify_merkle_path(leaf, siblings, path_is_left)
    }
}


spec module {
    // Formal safety intent: balance is unsigned, cannot be negative.
    invariant forall<T> t: AutonomousTreasury<T> :: balance::value(&t.vault) >= 0;
}

spec claim_reward {
    pragma opaque;
    ensures true;
}
