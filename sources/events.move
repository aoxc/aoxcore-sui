module aoxc::events {
    use std::vector;
    use sui::event;

    /// Reserved event slots for future AI-agent and Web4 interaction channels.
    public struct ReservedAgentSignalV1 has copy, drop {
        channel: u8,
        payload_hash: vector<u8>,
    }

    public struct ReservedAgentSettlementV1 has copy, drop {
        job_id: vector<u8>,
        status_code: u16,
        evidence_hash: vector<u8>,
    }

    public fun emit_reserved_signal(channel: u8, payload_hash: vector<u8>) {
        event::emit(ReservedAgentSignalV1 { channel, payload_hash });
    }

    public fun emit_reserved_settlement(job_id: vector<u8>, status_code: u16, evidence_hash: vector<u8>) {
        event::emit(ReservedAgentSettlementV1 { job_id, status_code, evidence_hash });
    }
}
