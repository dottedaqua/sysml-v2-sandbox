package TC02_reference_perform {
    // One declared usage per action definition (convention 10), started by
    // reference performs inside a do behavior; wiring is checked on the
    // declared usages. Rules: D9, D14, D32.
    // Expected load findings: none. No W08: the do-level performs are
    // references to the declared usages, not additional usages (D32).
    // Expected run: init -> s1 -> s1Do: perform a1 starts a1 (first
    // perform, D32 rule 3) -> a1 completes, token on a1.iout -> flow ->
    // a3.iin (D14) -> perform a3 starts, consumes, completes (D9) ->
    // s1Do completes -> completion s1 -> done -> success.
    // Status: DRAFT pending validation.

    package defs {
        item def I1;
        action def A1 { out item iout : I1; }
        action def A3 { in item iin : I1; }
    }

    part p1 {
        action a1 : defs::A1;
        action a3 : defs::A3;
        flow from a1.iout to a3.iin;

        exhibit state sm {
            entry;
            then state s1 {
                do action s1Do {
                    first perform a1;
                    then perform a3;
                    then done;
                }
            }
            then done;
        }
    }
} // package TC02_reference_perform
