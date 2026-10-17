package example011 {
    // Corrected variant of example010, demonstrating the profile decisions of
    // 2026-10-13:
    //   - D31: port-less event routing; send and accept address the part p1
    //     directly, no port is modeled.
    //   - E12: explicit succession between the producing action and the send.
    //   - Single consumption: the item crosses the state transition through
    //     trigger payload binding and a transition effect, not through a
    //     second event.
    //   - Conventions 10 and 16: action definitions A1 and A2 with one named
    //     usage per performance site.
    //   - D22 and D24: completion transition from s2 to done, the implicit
    //     final state, so a successful termination exists.
    //   - Convention 15: an unexpected IstateTransition in s2 goes to an
    //     explicit error state.
    //
    // Expected run: init -> s1 -> a1u fires -> self-send queues IstateTransition
    // -> s1Do completes -> dispatch: transition to s2, effect stores the payload
    // -> s2Do reads the part feature -> a2u fires -> s2Do completes ->
    // completion to done -> run ends successfully (D24).
    //
    // Status: validated against the SysML v2 Pilot Implementation parser
    // (release 2026-08, kernel 0.62.0); no parser findings. Notation
    // corrections applied during validation:
    //   - perform chains: no "first" before a perform; the unchained first
    //     statement starts at the do behavior's start;
    //   - accept payload naming: accept trItem : IstateTransition;
    //   - assignment operator ":=" and part features qualified by the part
    //     name (self did not resolve in the transition effect body);
    //   - completion transition "then done;" (the library done state; the
    //     pilot grammar has no "final" notation);
    //   - protecting transition: the accept shorthand attaches to the
    //     preceding state usage; no explicit source prefix.

    part p1 {
        item def IstateTransition;
        item def iAnything; // kept for the discussion; no current check covers unused item definitions

        // Part feature holding the accepted payload, written by the transition effect.
        item itemFromS1 : IstateTransition;

        action def A1 {
            out item iout : IstateTransition;
        }
        action def A2 {
            in item iin : IstateTransition;
        }

        exhibit state stateMachine {
            entry;
            then state s1 {
                do action s1Do {
                    perform action a1u : A1;
                    then send a1u.iout to p1;
                    then done;
                }
            }
            accept trItem : IstateTransition then s2 {
                // Transition effect (profile 6.6): store the accepted payload.
                assign p1.itemFromS1 := trItem;
            }
            state s2 {
                do action s2Do {
                    action getDataFromS1 { out item iFromS1 : IstateTransition = p1.itemFromS1; }
                    flow from getDataFromS1.iFromS1 to a2u.iin;
                    first getDataFromS1;
                    then perform action a2u : A2;
                    then done;
                }
            }
            then done;                        // completion transition (D22, D24)
            accept IstateTransition then sErr;  // unexpected-event protection (convention 15)
            state sErr;                           // explicit error state
        }
    }
} // package example011
