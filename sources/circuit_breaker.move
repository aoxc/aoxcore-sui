module aoxc::circuit_breaker {
    use std::vector;
    use aoxc::errors;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    public struct CircuitBreakerAdminCap has key, store { id: UID }

    /// Single source of truth for protocol transfer liveness.
    public struct CircuitBreaker has key {
        id: UID,
        paused: bool,
        permanently_halted: bool,
        last_reason_hash: vector<u8>,
    }

    public struct BreakerStateChanged has copy, drop {
        paused: bool,
        permanently_halted: bool,
        reason_hash: vector<u8>,
    }

    entry fun init(ctx: &mut TxContext) {
        let cap = CircuitBreakerAdminCap { id: object::new(ctx) };
        let breaker = CircuitBreaker {
            id: object::new(ctx),
            paused: false,
            permanently_halted: false,
            last_reason_hash: vector::empty<u8>(),
        };
        sui::transfer::share_object(breaker);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun set_paused(
        _cap: &CircuitBreakerAdminCap,
        breaker: &mut CircuitBreaker,
        paused: bool,
        reason_hash: vector<u8>,
    ) {
        if (!paused) {
            assert!(!breaker.permanently_halted, errors::E_ALREADY_FINALIZED);
        };
        breaker.paused = paused;
        breaker.last_reason_hash = reason_hash;
        event::emit(BreakerStateChanged {
            paused: breaker.paused,
            permanently_halted: breaker.permanently_halted,
            reason_hash: copy breaker.last_reason_hash,
        });
    }

    public(package) fun pause_from_module(breaker: &mut CircuitBreaker, reason_hash: vector<u8>) {
        breaker.paused = true;
        breaker.last_reason_hash = reason_hash;
        event::emit(BreakerStateChanged {
            paused: true,
            permanently_halted: breaker.permanently_halted,
            reason_hash: copy breaker.last_reason_hash,
        });
    }

    public(package) fun emergency_freeze_permanent(breaker: &mut CircuitBreaker, reason_hash: vector<u8>) {
        breaker.paused = true;
        breaker.permanently_halted = true;
        breaker.last_reason_hash = reason_hash;
        event::emit(BreakerStateChanged {
            paused: true,
            permanently_halted: true,
            reason_hash: copy breaker.last_reason_hash,
        });
    }

    public(package) fun resume_from_module(breaker: &mut CircuitBreaker, reason_hash: vector<u8>) {
        assert!(!breaker.permanently_halted, errors::E_ALREADY_FINALIZED);
        breaker.paused = false;
        breaker.last_reason_hash = reason_hash;
        event::emit(BreakerStateChanged {
            paused: false,
            permanently_halted: false,
            reason_hash: copy breaker.last_reason_hash,
        });
    }

    public fun assert_live(breaker: &CircuitBreaker) {
        assert!(!breaker.paused, errors::E_PROTOCOL_PAUSED);
    }

    public fun is_paused(breaker: &CircuitBreaker): bool { breaker.paused }
    public fun is_permanently_halted(breaker: &CircuitBreaker): bool { breaker.permanently_halted }
    public fun last_reason_hash(breaker: &CircuitBreaker): vector<u8> { copy breaker.last_reason_hash }

    // Testable invariant helpers.
    public fun validate_live_flag(paused: bool) {
        assert!(!paused, errors::E_PROTOCOL_PAUSED);
    }
}
