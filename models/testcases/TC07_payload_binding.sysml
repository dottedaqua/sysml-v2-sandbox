package TC07_payload_binding {
    // Single event occurrence crossing a transition through trigger payload
    // binding (deferred-scope item 9, first handover pattern), minimized
    // from example011. Rules: D22, D24, D26, D27, D31, D33; finding W02.
    // Expected load findings: W02 for (s2, Trigger) and (final, Trigger);
    // acknowledged per D18.
    // Expected run: init -> s1 -> s1Do sends a fresh Trigger (D33) ->
    // s1Do completes -> dispatch Trigger -> transition fires, the effect
    // binds the payload to the part feature (identity preserved, D26,
    // D27) -> s2 stable -> completion s2 -> final (D22) -> queues empty
    // -> success (D24). The occurrence is consumed exactly once.
    // Status: DRAFT pending validation, in particular the payload binding,
    // the transition effect, and the final notation (as with example011).

    package defs {
        item def Trigger;
    }

    part p1 {
        item received : defs::Trigger;

        exhibit state sm {
            entry;
            then state s1 {
                do action s1Do {
                    send new defs::Trigger() to p1;
                    then done;
                }
            }
            accept defs::Trigger : tr then s2 {
                assign self.received = tr;
            }
            state s2;
            s2 then final;
            final;
        }
    }
} // package TC07_payload_binding
