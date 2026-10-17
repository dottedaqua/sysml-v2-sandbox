package TC04_unused_item {
    // Two produced items, one consumed: the run reaches a final state while
    // the second item waits in the queue. Rules: D3, D22, D27, D31, D33,
    // D34; findings E13, W02.
    // Expected load findings: W02 for (s2, I1) and (done, I1), from the
    // over-approximating detection; acknowledged per D18.
    // Expected run: init -> s1 -> s1Do sends two fresh I1 instances
    // (distinct identities, D27, D33) -> s1Do completes -> dispatch of the
    // oldest I1 (D31) fires the transition to s2 -> s2 stable, its
    // completion transition takes priority over the queued second I1
    // (D22) -> done is final with a waiting item -> E13 hard error; the
    // report names the second send through the token genealogy (section
    // 3.3). The run is not reported as successful (D34 rule 2).
    // Status: validated against the SysML v2 Pilot Implementation parser
    // (release 2026-08, kernel 0.62.0); no parser findings.

    package defs {
        item def I1;
    }

    part p1 {
        exhibit state sm {
            entry;
            then state s1 {
                do action s1Do {
                    send new defs::I1() to p1;
                    then send new defs::I1() to p1;
                    then done;
                }
            }
            accept defs::I1 via p1 then s2;
            state s2;
            then done;
        }
    }
} // package TC04_unused_item
