package TC05_protecting_transition {
    // The example010 two-send handover, minimized, with the
    // unexpected-event protection of convention 15. Rules: D10, D13,
    // D22, D28, D31, D32; findings W02.
    // Expected load findings: W02 for (s2, Trigger), (sErr, I1),
    // (sErr, Trigger), (done, I1), (done, Trigger); acknowledged per D18.
    // (s2, I1) is covered: get is the unconditional first step of s2Do.
    // Intended path: dispatch Trigger first -> s2 -> get accepts I1 ->
    // flow to a2.iin -> a2 -> completion s2 -> done -> success.
    // Wrong path: dispatch I1 first -> protecting transition s1 -> sErr ->
    // Trigger still queued -> dispatch in sErr -> D13 hard error with
    // provenance.
    // Status: validated against the SysML v2 Pilot Implementation parser
    // (release 2026-08, kernel 0.62.0); no parser findings. The accept
    // shorthand attaches to the preceding state usage; the explicit
    // transition source prefix was removed as invalid syntax.

    package defs {
        item def I1;
        item def Trigger;
        action def A1 { out item iout : I1; }
        action def A2 { in item iin : I1; }
    }

    part p1 {
        action a1 : defs::A1;
        action a2 : defs::A2;

        exhibit state sm {
            entry;
            then state s1 {
                do action s1Do {
                    perform a1;
                    then send a1.iout to p1;
                    then send new defs::Trigger() to p1;
                    then done;
                }
            }
            accept defs::Trigger via p1 then s2;
            accept defs::I1 via p1 then sErr; // protection (convention 15)
            state s2 {
                do action s2Do {
                    action get accept x : defs::I1;
                    flow from get.x to a2.iin;
                    first get;
                    then perform a2;
                    then done;
                }
            }
            then done;
            state sErr;
        }
    }
} // package TC05_protecting_transition
