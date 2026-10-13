package example011 {
    // Corrected variant of example010, demonstrating the profile decisions of
    // 2026-10-13, revised to the two-send pattern:
    //   - D31: port-less event routing; both sends address the part p1
    //     directly, no port is modeled.
    //   - D6: a send action carries exactly one payload item, so the trigger
    //     and the handed-over item travel as two separate events.
    //   - E12: explicit successions order the producer before both sends.
    //   - Single consumption: the trigger is consumed by the transition to s2;
    //     the data item is consumed by the accept action in the do behavior of
    //     s2 (refined W02 counts it as the handler for (s2, ErrorData)).
    //   - Conventions 10 and 16: action definitions A1 and A2 with one named
    //     usage per performance site.
    //   - D22 and D24: completion transition from s2 to a final state.
    //   - Convention 15: every (state, event type) pair is handled explicitly;
    //     unexpected events go to the error state sErr.
    //   - D26: the data item is structured (an error code).
    //
    // Expected run: init -> s1 -> a1u fires, producing iTrig and iData ->
    // both self-sends are queued (two type queues, D31) -> s1Do completes ->
    // D10 pause: the user dispatches the trigger -> transition to s2 ->
    // the user dispatches ErrorData -> getDataFromS1 consumes it -> flow ->
    // a2u fires -> s2Do completes -> completion to final -> run ends
    // successfully (D24). Dispatching ErrorData while still in s1 takes the
    // protecting transition to sErr; the choice is recorded in the trace.
    //
    // Status: DRAFT pending validation against the SysML v2 Pilot Implementation
    // parser, in particular the typed perform usage, the completion transition,
    // and the attribute in the item definition.

    part p1 {
        // Control item: triggers the change to s2.
        item def IstateTransition;
        // Data item handed over to s2, for example an error code (D26).
        item def ErrorData { attribute code : Integer; }

        action def A1 {
            out item iTrig : IstateTransition;
            out item iData : ErrorData;
        }
        action def A2 {
            in item iin : ErrorData;
        }

        exhibit state stateMachine {
            entry;
            then state s1 {
                do action s1Do {
                    first perform action a1u : A1;
                    then send a1u.iTrig to p1;   // 1st send: trigger for the transition to s2
                    then send a1u.iData to p1;   // 2nd send: item consumed by the do behavior of s2
                    then done;
                }
            }
            accept IstateTransition then s2;      // trigger consumed by the transition (single consumption)
            state s2 {
                do action s2Do {
                    action getDataFromS1 accept iFromS1 : ErrorData;
                    flow from getDataFromS1.iFromS1 to a2u.iin;
                    first getDataFromS1;
                    then perform action a2u : A2;
                    then done;
                }
            }
            s2 then final;                         // completion transition (D22, D24)
            s2 accept IstateTransition then sErr;  // unexpected trigger in s2 (convention 15)
            s1 accept ErrorData then sErr;         // data arriving while still in s1 (convention 15)
            final;
            state sErr;                            // explicit error state
        }
    }
} // package example011
