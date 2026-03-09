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

    public struct RevenueDeposited has copy, drop { amount: u64, new_balance: u64 }
    public struct RewardDistributed has copy, drop { user: address, amount: u64 }
    public struct MerkleRootPublished has copy, drop { epoch: u64, root_hash: vector<u8> }
    public struct MerkleRewardClaimed has copy, drop { epoch: u64, user: address, amount: u64 }

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

    fun leaf_hash(user: address, amount: u64): vector<u8> {
        let bytes = bcs::to_bytes(&(user, amount));
        sui::hash::keccak256(&bytes)
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
        sui::transfer::share_object(treasury);
        sui::transfer::share_object(claim_pool);
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

    /// Gas-efficient claim path for large recipient sets.
    /// `proof_root` is a currently simplified aggregator proof root (must match active root).
    entry fun claim_reward<T>(
        breaker: &circuit_breaker::CircuitBreaker,
        pool: &mut MerkleClaimPool<T>,
        treasury: &mut AutonomousTreasury<T>,
        user: address,
        amount: u64,
        proof_root: vector<u8>,
        ctx: &mut TxContext,
    ) {
        circuit_breaker::assert_live(breaker);
        assert!(amount > 0, errors::E_AMOUNT_ZERO);
        assert!(proof_root == pool.current_root, errors::E_INVALID_ARGUMENT);

        let leaf = leaf_hash(user, amount);
        assert!(!contains_hash(&pool.claimed_leaf_hashes, &leaf), errors::E_ALREADY_CLAIMED);
        assert!(balance::value(&treasury.vault) >= amount, errors::E_INSUFFICIENT_BALANCE);

        vector::push_back(&mut pool.claimed_leaf_hashes, leaf);
        let payout_bal = balance::split(&mut treasury.vault, amount);
        let payout_coin = coin::from_balance(payout_bal, ctx);
        sui::transfer::public_transfer(payout_coin, user);
        treasury.distributed_total = treasury.distributed_total + amount;

        event::emit(MerkleRewardClaimed { epoch: pool.epoch, user, amount });
    }

    public fun balance_of<T>(treasury: &AutonomousTreasury<T>): u64 { balance::value(&treasury.vault) }
}
