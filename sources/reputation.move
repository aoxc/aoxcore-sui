module aoxc::reputation {
    use std::string::String;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    const E_PROFILE_EXISTS: u64 = 1;
    const E_PROFILE_NOT_FOUND: u64 = 2;

    public struct ReputationAdminCap has key, store { id: UID }

    /// Shared registry enabling transparent and community-observable reputation state.
    public struct ReputationBook has key {
        id: UID,
        namespace: String,
        profiles: Table<address, ScoreProfile>,
    }

    public struct ScoreProfile has copy, drop, store {
        score: u64,
        trust_tier: u8,
        repair_actions: u64,
        latest_evidence_hash: vector<u8>,
    }

    public struct ProfileCreated has copy, drop {
        user: address,
        score: u64,
        trust_tier: u8,
    }

    public struct ProfileUpdated has copy, drop {
        user: address,
        score: u64,
        trust_tier: u8,
    }

    entry fun init(namespace: String, ctx: &mut TxContext) {
        let cap = ReputationAdminCap { id: object::new(ctx) };
        let book = ReputationBook {
            id: object::new(ctx),
            namespace,
            profiles: table::new<address, ScoreProfile>(ctx),
        };

        sui::transfer::share_object(book);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun create_profile(
        _cap: &ReputationAdminCap,
        book: &mut ReputationBook,
        user: address,
        starting_score: u64,
        trust_tier: u8,
        evidence_hash: vector<u8>,
    ) {
        assert!(!table::contains(&book.profiles, user), E_PROFILE_EXISTS);

        table::add(&mut book.profiles, user, ScoreProfile {
            score: starting_score,
            trust_tier,
            repair_actions: 0,
            latest_evidence_hash: evidence_hash,
        });

        event::emit(ProfileCreated { user, score: starting_score, trust_tier });
    }

    /// Update can be called by governance or automation keeper signed by cap holder.
    entry fun update_profile(
        _cap: &ReputationAdminCap,
        book: &mut ReputationBook,
        user: address,
        next_score: u64,
        next_tier: u8,
        evidence_hash: vector<u8>,
        repaired: bool,
    ) {
        assert!(table::contains(&book.profiles, user), E_PROFILE_NOT_FOUND);
        let profile = table::borrow_mut(&mut book.profiles, user);

        profile.score = next_score;
        profile.trust_tier = next_tier;
        if (repaired) {
            profile.repair_actions = profile.repair_actions + 1;
        };
        profile.latest_evidence_hash = evidence_hash;

        event::emit(ProfileUpdated { user, score: next_score, trust_tier: next_tier });
    }
}
