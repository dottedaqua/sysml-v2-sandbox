package TC03_owning_perform {
    // An owning performance at part level starts at initialization and runs
    // concurrently with the exhibited state machine. Contrast with TC02.
    // Rules: D16, D18, D19, D32 rule 1.
    // Expected load findings: none. A1 has no inputs and no outputs, so
    // no wiring finding applies.
    // Expected run: initialization starts a1 and the exhibit concurrently
    // (the user steps their order, recorded, D10/D18) -> a1 completes ->
    // entry -> s1 -> completion s1 -> done -> success.
    // Status: validated against the SysML v2 Pilot Implementation parser
    // (release 2026-08, kernel 0.62.0); no parser findings.

    package defs {
        action def A1 { }
    }

    part p1 {
        perform action a1 : defs::A1;

        exhibit state sm {
            entry;
            then state s1;
            then done;
        }
    }
} // package TC03_owning_perform
