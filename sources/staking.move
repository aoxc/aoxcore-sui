module aoxc::staking {
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use aoxc::treasury;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    public struct StakingAdminCap has key, store { id: UID }

    public struct StakingPool<phantom T> has key {
        id: UID,
        principal: Balance<T>,
        stake_shares: Table<address, u64>,
        slash_bps: u16,
        compounded_total: u64,
    }

    public struct StakeAdded has copy, drop { user: address, amount: u64 }
    public struct Unstaked has copy, drop { user: address, amount: u64 }
    public struct Slashed has copy, drop { amount: u64, slash_bps: u16 }
    public struct AutoCompounded has copy, drop { amount: u64, compounded_total: u64 }

    public fun validate_slash_bps(slash_bps: u16) {
        assert!((slash_bps as u64) <= 3_000, errors::E_SLASH_TOO_HIGH);
    }

    entry fun init<T>(slash_bps: u16, ctx: &mut TxContext) {
        validate_slash_bps(slash_bps);
        let cap = StakingAdminCap { id: object::new(ctx) };
        let pool = StakingPool<T> {
            id: object::new(ctx),
            principal: balance::zero<T>(),
            stake_shares: table::new<address, u64>(ctx),
            slash_bps,
            compounded_total: 0,
        };

        sui::transfer::share_object(pool);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun set_slash_bps<T>(_cap: &StakingAdminCap, pool: &mut StakingPool<T>, slash_bps: u16) {
        validate_slash_bps(slash_bps);
        pool.slash_bps = slash_bps;
    }

    entry fun stake<T>(pool: &mut StakingPool<T>, payment: Coin<T>, ctx: &TxContext) {
        let user = tx_context::sender(ctx);
        let amount = coin::value(&payment);
        assert!(amount > 0, errors::E_AMOUNT_ZERO);

        let received = coin::into_balance(payment);
        balance::join(&mut pool.principal, received);

        if (!table::contains(&pool.stake_shares, user)) {
            table::add(&mut pool.stake_shares, user, amount);
        } else {
            let shares = table::borrow_mut(&mut pool.stake_shares, user);
            *shares = *shares + amount;
        };

        event::emit(StakeAdded { user, amount });
    }

    entry fun unstake<T>(pool: &mut StakingPool<T>, amount: u64, ctx: &mut TxContext) {
        let user = tx_context::sender(ctx);
        assert!(amount > 0, errors::E_AMOUNT_ZERO);
        assert!(table::contains(&pool.stake_shares, user), errors::E_NOT_FOUND);

        let shares = table::borrow_mut(&mut pool.stake_shares, user);
        assert!(*shares >= amount, errors::E_INSUFFICIENT_BALANCE);
        *shares = *shares - amount;

        let payout = balance::split(&mut pool.principal, amount);
        let coin_out = coin::from_balance(payout, ctx);
        sui::transfer::public_transfer(coin_out, user);

        event::emit(Unstaked { user, amount });
    }

    entry fun slash<T>(
        _cap: &StakingAdminCap,
        breaker: &circuit_breaker::CircuitBreaker,
        pool: &mut StakingPool<T>,
        ctx: &mut TxContext,
    ) {
        circuit_breaker::assert_live(breaker);
        let principal = balance::value(&pool.principal);
        let slash_amt = (principal * (pool.slash_bps as u64)) / 10_000;
        if (slash_amt > 0) {
            let burned = balance::split(&mut pool.principal, slash_amt);
            let burn_coin = coin::from_balance(burned, ctx);
            sui::transfer::public_transfer(burn_coin, @0x0);
        };
        event::emit(Slashed { amount: slash_amt, slash_bps: pool.slash_bps });
    }

    entry fun auto_compound_from_treasury<T>(
        _cap: &StakingAdminCap,
        breaker: &circuit_breaker::CircuitBreaker,
        treasury_ref: &treasury::AutonomousTreasury<T>,
        pool: &mut StakingPool<T>,
        reward_bps: u16,
    ) {
        circuit_breaker::assert_live(breaker);
        assert!((reward_bps as u64) <= 2_000, errors::E_POLICY_LIMIT);
        let reward = (treasury::balance_of(treasury_ref) * (reward_bps as u64)) / 10_000;
        pool.compounded_total = pool.compounded_total + reward;
        event::emit(AutoCompounded { amount: reward, compounded_total: pool.compounded_total });
    }

    public fun principal_of<T>(pool: &StakingPool<T>): u64 { balance::value(&pool.principal) }
}
