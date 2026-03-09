module aoxc::reputation {
    use std::string::String;
    use std::vector;
    use aoxc::errors;
    use aoxc::relay;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    public struct ReputationAdminCap has key, store { id: UID }

    /// Shared registry for transparent community trust scores.
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

    public struct ProfileUpdated has copy, drop {
        user: address,
        score: u64,
        trust_tier: u8,
        evidence_blob_id: vector<u8>,
    }

    public fun validate_evidence_hash(evidence_hash: &vector<u8>) {
        assert!(vector::length(evidence_hash) > 0, errors::E_EMPTY_HASH);
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

    /// Upsert allows deterministic off-chain scoring pipelines.
    /// Evidence must be attested in relay as a REPORT_REPUTATION blob.
    entry fun upsert_profile(
        _cap: &ReputationAdminCap,
        relay_ref: &relay::PublicReportRelay,
        book: &mut ReputationBook,
        user: address,
        next_score: u64,
        next_tier: u8,
        evidence_blob_id: vector<u8>,
        evidence_hash: vector<u8>,
        repaired: bool,
    ) {
        validate_evidence_hash(&evidence_hash);
        relay::assert_attested(
            relay_ref,
            copy evidence_blob_id,
            relay::reputation_report_type(),
            copy evidence_hash,
        );

        if (!table::contains(&book.profiles, user)) {
            let mut repairs = 0;
            if (repaired) { repairs = 1; };
            table::add(&mut book.profiles, user, ScoreProfile {
                score: next_score,
                trust_tier: next_tier,
                repair_actions: repairs,
                latest_evidence_hash: evidence_hash,
            });
        } else {
            let profile = table::borrow_mut(&mut book.profiles, user);
            profile.score = next_score;
            profile.trust_tier = next_tier;
            if (repaired) { profile.repair_actions = profile.repair_actions + 1; };
            profile.latest_evidence_hash = evidence_hash;
        };

        event::emit(ProfileUpdated {
            user,
            score: next_score,
            trust_tier: next_tier,
            evidence_blob_id,
        });
    }

    public fun require_min_score(book: &ReputationBook, user: address, threshold: u64) {
        assert!(table::contains(&book.profiles, user), errors::E_NOT_FOUND);
        let p = table::borrow(&book.profiles, user);
        assert!(p.score >= threshold, errors::E_SCORE_TOO_LOW);
    }

    public fun score_of(book: &ReputationBook, user: address): u64 {
        assert!(table::contains(&book.profiles, user), errors::E_NOT_FOUND);
        let p = table::borrow(&book.profiles, user);
        p.score
    }
}
