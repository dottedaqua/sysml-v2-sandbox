package TC06_undefined_ordering {
    // A send payload reads the output of an action that no succession
    // orders before the send. Finding: E12 (blocking, D18).
    // Expected load findings: E12; W02 for (s2, I1) and (done, I1).
    // Expected behavior: the run cannot start (D18). Resolution in the
    // model: an explicit succession, perform a1; then send a1.iout
    // to p1. The pilot parser accepts the uncorrected model without
    // findings; the ordering violation is detected only by the simulator
    // (E12).
    // Status: validated against the SysML v2 Pilot Implementation parser
    // (release 2026-08, kernel 0.62.0); no parser findings.

    package defs {
        item def I1;
        action def A1 { out item iout : I1; }
    }

    part p1 {
        action a1 : defs::A1;

        exhibit state sm {
            entry;
            then state s1 {
                do action s1Do {
                    perform a1;
                    send a1.iout to p1;
                    then done;
                }
            }
            accept defs::I1 via p1 then s2;
            state s2;
            then done;
        }
    }
} // package TC06_undefined_ordering
