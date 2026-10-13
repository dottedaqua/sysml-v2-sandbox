package example010 {
    part p1 {
        item def IstateTransition;
        item def iAnything;
        perform action a1 {
            out item iout : IstateTransition;
        }
        perform action a2 {
            in item iin : IstateTransition;
        }

        // port required for "via"
        exhibit state stateMachine {
            entry;
            then state s1 {
                do action s1Do {
                    perform a1;
                    send a1.iout to p1;
                    then done;
                }
            }
            accept IstateTransition via p1 then s2; // Accepts the item from p1 and transitions to state s2
            state s2 {
                do action s2Do {
                    action getDataFromS1 accept iFromS1 : IstateTransition;
                    flow from getDataFromS1.iFromS1 to a2.iin;
                    first getDataFromS1;
                    then perform a2;
                    then done;
                }
            }
        }
    }
} // package example010
