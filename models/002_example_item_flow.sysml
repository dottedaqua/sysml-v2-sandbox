package example001 {
    part p1 {
        item def I1;
        perform action a1 {
            out item i1 : I1;
        }
        perform action a2 {
            in item i1 : I1;
        }

        // Flow item from action a1 to action a2
        flow a1.i1 to a2.i1;

        exhibit state stateMachine {
            entry;
            then action a1;
            then action a2;
            then done;
        }
    }
} // package example001
