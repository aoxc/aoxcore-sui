module aoxc::treasury {
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

    /// Revenue pool for protocol income. Stores real on-chain balances.
    public struct AutonomousTreasury<phantom T> has key {
        id: UID,
        vault: Balance<T>,
        min_reputation_score: u64,
        distributed_total: u64,
    }

    public struct RevenueDeposited has copy, drop {
        amount: u64,
        new_balance: u64,
    }

    public struct RewardDistributed has copy, drop {
        user: address,
        amount: u64,
    }

    public fun validate_distribution_vectors(recipients_len: u64, amounts_len: u64) {
        assert!(recipients_len == amounts_len, errors::E_LENGTH_MISMATCH);
    }

    entry fun init<T>(min_reputation_score: u64, ctx: &mut TxContext) {
        let cap = TreasuryDistributorCap { id: object::new(ctx) };
        let treasury = AutonomousTreasury<T> {
            id: object::new(ctx),
            vault: balance::zero<T>(),
            min_reputation_score,
            distributed_total: 0,
        };
        sui::transfer::share_object(treasury);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun set_min_reputation_score<T>(
        _cap: &TreasuryDistributorCap,
        treasury: &mut AutonomousTreasury<T>,
        next: u64,
    ) {
        treasury.min_reputation_score = next;
    }

    entry fun deposit_revenue<T>(
        _cap: &TreasuryDistributorCap,
        treasury: &mut AutonomousTreasury<T>,
        payment: Coin<T>,
    ) {
        let amt = coin::value(&payment);
        assert!(amt > 0, errors::E_AMOUNT_ZERO);

        let received = coin::into_balance(payment);
        balance::join(&mut treasury.vault, received);

        event::emit(RevenueDeposited {
            amount: amt,
            new_balance: balance::value(&treasury.vault),
        });
    }

    /// Fair distribution gated by minimum reputation score and global circuit breaker.
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

    public fun balance_of<T>(treasury: &AutonomousTreasury<T>): u64 { balance::value(&treasury.vault) }
}
