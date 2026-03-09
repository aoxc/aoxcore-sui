module aoxc::treasury {
    use std::vector;
    use aoxc::errors;
    use aoxc::neural_bridge;
    use aoxc::reputation;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    public struct TreasuryDistributorCap has key, store { id: UID }

    /// Revenue pool for bridge fees and protocol income.
    public struct AutonomousTreasury has key {
        id: UID,
        balance: u64,
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

    entry fun init(min_reputation_score: u64, ctx: &mut TxContext) {
        let cap = TreasuryDistributorCap { id: object::new(ctx) };
        let treasury = AutonomousTreasury {
            id: object::new(ctx),
            balance: 0,
            min_reputation_score,
            distributed_total: 0,
        };
        sui::transfer::share_object(treasury);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun deposit_revenue(_cap: &TreasuryDistributorCap, treasury: &mut AutonomousTreasury, amount: u64) {
        treasury.balance = treasury.balance + amount;
        event::emit(RevenueDeposited { amount, new_balance: treasury.balance });
    }

    /// Fair distribution gated by minimum reputation score.
    entry fun distribute_fair(
        _cap: &TreasuryDistributorCap,
        gateway: &neural_bridge::NeuralGateway,
        rep_book: &reputation::ReputationBook,
        treasury: &mut AutonomousTreasury,
        recipients: vector<address>,
        amounts: vector<u64>,
    ) {
        neural_bridge::assert_transfers_enabled(gateway);
        assert!(vector::length(&recipients) == vector::length(&amounts), errors::E_LENGTH_MISMATCH);

        let len = vector::length(&recipients);
        let mut i = 0;
        let mut required = 0;
        while (i < len) {
            let amt = *vector::borrow(&amounts, i);
            required = required + amt;
            i = i + 1;
        };
        assert!(treasury.balance >= required, errors::E_INSUFFICIENT_BALANCE);

        let mut j = 0;
        while (j < len) {
            let user = *vector::borrow(&recipients, j);
            let amt = *vector::borrow(&amounts, j);
            reputation::require_min_score(rep_book, user, treasury.min_reputation_score);
            treasury.balance = treasury.balance - amt;
            treasury.distributed_total = treasury.distributed_total + amt;
            event::emit(RewardDistributed { user, amount: amt });
            j = j + 1;
        };
    }

    public fun balance_of(treasury: &AutonomousTreasury): u64 { treasury.balance }
}
