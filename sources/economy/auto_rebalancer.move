module aoxc::auto_rebalancer {
    use std::vector;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    public struct RebalancerAdminCap has key, store { id: UID }

    public struct AutoRebalancer has key {
        id: UID,
        soft_mismatch_bps: u64,
        hard_mismatch_bps: u64,
        snapshots_taken: u64,
    }

    public struct RebalanceActionTaken has copy, drop {
        mismatch_bps: u64,
        used_soft_rebalance: bool,
        escalated_to_dao: bool,
        snapshot_id: u64,
    }

    public fun validate_thresholds(soft_mismatch_bps: u64, hard_mismatch_bps: u64) {
        assert!(soft_mismatch_bps > 0, errors::E_INVALID_ARGUMENT);
        assert!(hard_mismatch_bps >= soft_mismatch_bps, errors::E_INVALID_ARGUMENT);
    }

    entry fun init(soft_mismatch_bps: u64, hard_mismatch_bps: u64, ctx: &mut TxContext) {
        validate_thresholds(soft_mismatch_bps, hard_mismatch_bps);
    entry fun init(soft_mismatch_bps: u64, hard_mismatch_bps: u64, ctx: &mut TxContext) {
        assert!(soft_mismatch_bps > 0, errors::E_INVALID_ARGUMENT);
        assert!(hard_mismatch_bps >= soft_mismatch_bps, errors::E_INVALID_ARGUMENT);
        let cap = RebalancerAdminCap { id: object::new(ctx) };
        let state = AutoRebalancer {
            id: object::new(ctx),
            soft_mismatch_bps,
            hard_mismatch_bps,
            snapshots_taken: 0,
        };
        sui::transfer::share_object(state);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun set_thresholds(
        _cap: &RebalancerAdminCap,
        state: &mut AutoRebalancer,
        soft_mismatch_bps: u64,
        hard_mismatch_bps: u64,
    ) {
        validate_thresholds(soft_mismatch_bps, hard_mismatch_bps);
        assert!(soft_mismatch_bps > 0, errors::E_INVALID_ARGUMENT);
        assert!(hard_mismatch_bps >= soft_mismatch_bps, errors::E_INVALID_ARGUMENT);
        state.soft_mismatch_bps = soft_mismatch_bps;
        state.hard_mismatch_bps = hard_mismatch_bps;
    }

    entry fun evaluate_and_act(
        _cap: &RebalancerAdminCap,
        state: &mut AutoRebalancer,
        breaker: &mut circuit_breaker::CircuitBreaker,
        mismatch_bps: u64,
        reason_hash: vector<u8>,
    ) {
        assert!(vector::length(&reason_hash) > 0, errors::E_EMPTY_HASH);
        let mut soft = false;
        let mut escalated = false;

        if (mismatch_bps <= state.soft_mismatch_bps) {
            soft = true;
        } else if (mismatch_bps <= state.hard_mismatch_bps) {
            // degraded-but-recoverable range, keep protocol live with rebalancing intent
            soft = true;
        } else {
            escalated = true;
            state.snapshots_taken = state.snapshots_taken + 1;
            circuit_breaker::emergency_freeze_permanent(breaker, reason_hash);
        };

        event::emit(RebalanceActionTaken {
            mismatch_bps,
            used_soft_rebalance: soft,
            escalated_to_dao: escalated,
            snapshot_id: state.snapshots_taken,
        });
    }
}
