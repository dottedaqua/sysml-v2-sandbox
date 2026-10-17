package TC08_unknown_value {
    // A constructed item with an attribute that has no modeled default: the
    // value is unknown (D15, D33 rule 3); the transition effect that reads
    // it pauses the run until the user supplies a value (D11), which is
    // recorded in the trace (section 3.3). Rules: D3, D11, D15, D22, D24,
    // D26, D33; finding W02.
    // Expected load findings: W02 for (s2, Payload) and (done, Payload);
    // acknowledged per D18.
    // Expected run: init -> s1 -> s1Do sends a fresh Payload with code
    // unknown -> dispatch Payload -> transition effect reads pl.code ->
    // D11 pause -> the user supplies 42 (recorded) -> s2 stable ->
    // completion s2 -> done -> success.
    // Status: validated against the SysML v2 Pilot Implementation parser
    // (release 2026-08, kernel 0.62.0); no parser findings.

    package defs {
        item def Payload { attribute code : ScalarValues::Integer; }
    }

    part p1 {
        attribute lastCode : ScalarValues::Integer; // no default: unknown until assigned (D15)

        exhibit state sm {
            entry;
            then state s1 {
                do action s1Do {
                    send new defs::Payload() to p1;
                    then done;
                }
            }
            accept pl : defs::Payload then s2 {
                assign p1.lastCode := pl.code;
            }
            state s2;
            then done;
        }
    }
} // package TC08_unknown_value
