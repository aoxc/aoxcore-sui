module aoxc::sentinel_dao {
    use std::vector;
    use aoxc::bridge_payload;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    const PROPOSAL_PENDING: u8 = 0;
    const PROPOSAL_EXECUTED: u8 = 1;
    const PROPOSAL_VETOED: u8 = 2;

    /// guardrails
    const MAX_TIMELOCK_MS: u64 = 7 * 24 * 60 * 60 * 1000;
    const MIN_COOLDOWN_MS: u64 = 60 * 60 * 1000;
    const MAX_FUND_DELTA_BPS: u16 = 2000;

    public struct DaoAdminCap has key, store { id: UID }

    public struct SentinelDao has key {
        id: UID,
        timelock_ms: u64,
        min_veto_votes: u64,
        next_id: u64,
        last_exec_ms: u64,
        proposals: Table<u64, Proposal>,
        veto_votes: Table<u64, u64>,
    }

    public struct Proposal has copy, drop, store {
        id: u64,
        action: bridge_payload::GovernanceAction,
        eta_ms: u64,
        status: u8,
        requested_fund_delta_bps: u16,
    }

    public struct ProposalQueued has copy, drop {
        id: u64,
        action_type: u8,
        eta_ms: u64,
    }

    public struct ProposalFinalized has copy, drop {
        id: u64,
        status: u8,
    }

    public fun validate_action_type(action_type: u8) {
        bridge_payload::validate_governance_action(action_type);
    }

    public fun assert_not_vetoed(votes: u64, min_veto_votes: u64) {
        assert!(votes < min_veto_votes, errors::E_VETOED);
    }

    public fun validate_policy_limits(timelock_ms: u64, requested_fund_delta_bps: u16) {
        assert!(timelock_ms > 0 && timelock_ms <= MAX_TIMELOCK_MS, errors::E_POLICY_LIMIT);
        assert!(requested_fund_delta_bps <= MAX_FUND_DELTA_BPS, errors::E_POLICY_LIMIT);
    }

    entry fun init(min_veto_votes: u64, ctx: &mut TxContext) {
        let cap = DaoAdminCap { id: object::new(ctx) };
        let dao = SentinelDao {
            id: object::new(ctx),
            timelock_ms: 24 * 60 * 60 * 1000,
            min_veto_votes,
            next_id: 1,
            last_exec_ms: 0,
            proposals: table::new<u64, Proposal>(ctx),
            veto_votes: table::new<u64, u64>(ctx),
        };
        sui::transfer::share_object(dao);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun set_timelock_ms(_cap: &DaoAdminCap, dao: &mut SentinelDao, next: u64) {
        validate_policy_limits(next, 0);
        dao.timelock_ms = next;
    }

    entry fun queue_proposal(
        _cap: &DaoAdminCap,
        dao: &mut SentinelDao,
        action: bridge_payload::GovernanceAction,
        requested_fund_delta_bps: u16,
        clock: &Clock,
    ) {
        validate_action_type(bridge_payload::action_type(&action));
        validate_policy_limits(dao.timelock_ms, requested_fund_delta_bps);

        let id = dao.next_id;
        dao.next_id = dao.next_id + 1;
        let eta_ms = clock::timestamp_ms(clock) + dao.timelock_ms;

        let proposal = Proposal { id, action, eta_ms, status: PROPOSAL_PENDING, requested_fund_delta_bps };
        table::add(&mut dao.proposals, id, proposal);
        table::add(&mut dao.veto_votes, id, 0);

        event::emit(ProposalQueued { id, action_type: bridge_payload::action_type(&action), eta_ms });
    }

    entry fun cast_veto_vote(dao: &mut SentinelDao, proposal_id: u64, weight: u64) {
        assert!(table::contains(&dao.veto_votes, proposal_id), errors::E_NOT_FOUND);
        let votes = table::borrow_mut(&mut dao.veto_votes, proposal_id);
        *votes = *votes + weight;
    }

    entry fun finalize_proposal(
        _cap: &DaoAdminCap,
        dao: &mut SentinelDao,
        breaker: &mut circuit_breaker::CircuitBreaker,
        proposal_id: u64,
        clock: &Clock,
    ) {
        assert!(table::contains(&dao.proposals, proposal_id), errors::E_NOT_FOUND);
        let p = table::borrow_mut(&mut dao.proposals, proposal_id);
        assert!(p.status == PROPOSAL_PENDING, errors::E_ALREADY_FINALIZED);
        assert!(clock::timestamp_ms(clock) >= p.eta_ms, errors::E_TIMELOCK_PENDING);
        assert!(clock::timestamp_ms(clock) >= dao.last_exec_ms + MIN_COOLDOWN_MS, errors::E_POLICY_LIMIT);

        let votes = *table::borrow(&dao.veto_votes, proposal_id);
        if (votes >= dao.min_veto_votes) {
            p.status = PROPOSAL_VETOED;
            event::emit(ProposalFinalized { id: proposal_id, status: PROPOSAL_VETOED });
            return
        };

        let action_type = bridge_payload::action_type(&p.action);
        if (action_type == bridge_payload::kind_system_halt()) {
            circuit_breaker::pause_from_module(breaker, bridge_payload::action_proof_root(&p.action));
        };
        if (action_type == bridge_payload::kind_system_resume()) {
            circuit_breaker::resume_from_module(breaker, bridge_payload::action_proof_root(&p.action));
        };

        dao.last_exec_ms = clock::timestamp_ms(clock);
        p.status = PROPOSAL_EXECUTED;
        event::emit(ProposalFinalized { id: proposal_id, status: PROPOSAL_EXECUTED });
    }
}
