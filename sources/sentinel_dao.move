module aoxc::sentinel_dao {
        use std::vector;
    use aoxc::errors;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    const PROPOSAL_PENDING: u8 = 0;
    const PROPOSAL_EXECUTED: u8 = 1;
    const PROPOSAL_VETOED: u8 = 2;

    public struct DaoAdminCap has key, store { id: UID }

    /// Global governance and circuit breaker state.
    public struct SentinelDao has key {
        id: UID,
        timelock_ms: u64,
        min_veto_votes: u64,
        next_id: u64,
        paused: bool,
        proposals: Table<u64, Proposal>,
        veto_votes: Table<u64, u64>,
    }

    public struct Proposal has copy, drop, store {
        id: u64,
        action_type: u8,
        payload_hash: vector<u8>,
        eta_ms: u64,
        status: u8,
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

    entry fun init(min_veto_votes: u64, ctx: &mut TxContext) {
        let cap = DaoAdminCap { id: object::new(ctx) };
        let dao = SentinelDao {
            id: object::new(ctx),
            timelock_ms: 24 * 60 * 60 * 1000,
            min_veto_votes,
            next_id: 1,
            paused: false,
            proposals: table::new<u64, Proposal>(ctx),
            veto_votes: table::new<u64, u64>(ctx),
        };
        sui::transfer::share_object(dao);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// Queue AI/sentinel decision and enforce 24h delay before execution.
    entry fun queue_proposal(
        _cap: &DaoAdminCap,
        dao: &mut SentinelDao,
        action_type: u8,
        payload_hash: vector<u8>,
        clock: &Clock,
    ) {
        let id = dao.next_id;
        dao.next_id = dao.next_id + 1;

        let proposal = Proposal {
            id,
            action_type,
            payload_hash,
            eta_ms: clock::timestamp_ms(clock) + dao.timelock_ms,
            status: PROPOSAL_PENDING,
        };
        table::add(&mut dao.proposals, id, proposal);
        table::add(&mut dao.veto_votes, id, 0);

        event::emit(ProposalQueued { id, action_type, eta_ms: clock::timestamp_ms(clock) + dao.timelock_ms });
    }

    /// Community veto accumulator (off-chain vote snapshot can call this entry multiple times).
    entry fun cast_veto_vote(dao: &mut SentinelDao, proposal_id: u64, weight: u64) {
        assert!(table::contains(&dao.veto_votes, proposal_id), errors::E_NOT_FOUND);
        let votes = table::borrow_mut(&mut dao.veto_votes, proposal_id);
        *votes = *votes + weight;
    }

    entry fun finalize_proposal(_cap: &DaoAdminCap, dao: &mut SentinelDao, proposal_id: u64, clock: &Clock) {
        assert!(table::contains(&dao.proposals, proposal_id), errors::E_NOT_FOUND);
        let p = table::borrow_mut(&mut dao.proposals, proposal_id);
        assert!(p.status == PROPOSAL_PENDING, errors::E_INVALID_ARGUMENT);
        assert!(clock::timestamp_ms(clock) >= p.eta_ms, errors::E_TIMELOCK_PENDING);

        let votes = *table::borrow(&dao.veto_votes, proposal_id);
        if (votes >= dao.min_veto_votes) {
            p.status = PROPOSAL_VETOED;
            event::emit(ProposalFinalized { id: proposal_id, status: PROPOSAL_VETOED });
            return
        };

        if (p.action_type == 1) { dao.paused = true; };
        if (p.action_type == 2) { dao.paused = false; };
        p.status = PROPOSAL_EXECUTED;
        event::emit(ProposalFinalized { id: proposal_id, status: PROPOSAL_EXECUTED });
    }

    public fun assert_live(dao: &SentinelDao) {
        assert!(!dao.paused, errors::E_PROTOCOL_PAUSED);
    }

    public fun is_paused(dao: &SentinelDao): bool { dao.paused }
}
