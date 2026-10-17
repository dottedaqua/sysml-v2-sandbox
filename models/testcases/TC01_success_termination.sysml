package TC01_success_termination {
    // Minimal successful run. Rules: D10, D16, D19, D22, D24.
    // Expected load findings: none.
    // Expected run: init -> entry -> s1 -> completion s1 -> done (implicit
    // final, D24) -> all queues empty -> run ends successfully.
    // Status: DRAFT pending validation against the SysML v2 Pilot
    // Implementation parser.

    part p1 {
        exhibit state sm {
            entry;
            then state s1;
            then done;
        }
    }
} // package TC01_success_termination
