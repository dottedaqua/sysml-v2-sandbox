# Simulator Test Cases

## 1. Purpose

This document defines the unit-level test-case suite of the simulator. The suite serves three purposes:

1. Discussion: each case isolates one rule or one interaction of the semantic profile, so that the expected behavior can be agreed upon and documented before implementation.
2. Documentation: each case is a canonical example of a modeling artifact or rule, referenced by the decision, error, and warning codes of docs/semantic-profile.md.
3. Verification: each case defines machine-checkable expectations, consisting of the load findings by code and a scripted run whose choice sequence is part of the expectation.

The existing examples, models/010_example_state_change_item_transition.sysml (two-send handover) and models/011_example_state_change_payload_binding.sysml (trigger payload binding), remain the integration-level examples. The TC cases are unit-level and deliberately minimal.

## 2. Conventions

- All case models are validated against the SysML v2 Pilot Implementation parser (release 2026-08, kernel 0.62.0). The validation is repeated automatically on every push by the workflow .github/workflows/validate-models.yml using the helper tools/Validate.java. The pilot parser checks the textual syntax and the language semantics; the E and W findings catalogued below are expectations of the simulator's own static checks and are not reported by the pilot parser.
- A simulator passes a case if it: reports exactly the listed load findings; follows the scripted run, recording every listed choice in the trace (D10, section 3.3); and terminates with the listed outcome.
- Warnings are acknowledged per run (D18); the acknowledgement is part of the scripted run.
- Per D22, completion transitions take priority over queued events at every choice point; this priority is part of the expected traces.
- The scripted run always takes the intended path, except where a case documents a wrong path explicitly.

## 3. Catalogue

| Case | File | Rules exercised | Expected outcome |
| --- | --- | --- | --- |
| TC01 | models/testcases/TC01_success_termination.sysml | D10, D16, D19, D22, D24 | Successful termination; no findings |
| TC02 | models/testcases/TC02_reference_perform.sysml | D9, D14, D32 | Success; one execution per declared usage |
| TC03 | models/testcases/TC03_owning_perform.sysml | D16, D18, D19, D32 | Owning performance starts at initialization |
| TC04 | models/testcases/TC04_unused_item.sysml | E13, W02, D22, D27, D31, D33, D34 | Hard error E13 at final entry |
| TC05 | models/testcases/TC05_protecting_transition.sysml | W02, D13, D22, D28, D31, D32, convention 15 | Intended path: success; wrong path: D13 |
| TC06 | models/testcases/TC06_undefined_ordering.sysml | E12, W02, D18 | Blocking; the run cannot start |
| TC07 | models/testcases/TC07_payload_binding.sysml | W02, D22, D24, D26, D27, D33 | Success; single consumption |
| TC08 | models/testcases/TC08_unknown_value.sysml | W02, D11, D15, D22, D24, D26, D33 | Success after a D11 pause |

## 4. Case specifications

### TC01 - Successful termination
- Intent: the smallest model that terminates successfully, exercising initialization, entry, completion, and the implicit final done state.
- Load findings: none.
- Scripted run: (1) initialization instantiates p1, entry runs, s1 is entered; (2) s1 has no do behavior and is stable; its completion transition fires (D22); (3) done is final; all queues are empty; the run ends successfully (D24).
- Pass criteria: success report; empty findings list; no choices recorded.

### TC02 - Reference performs and usage counting
- Intent: one declared usage per action definition (convention 10), started by reference performs inside a do behavior; wiring checked on the declared usages.
- Load findings: none. No W08: the do-level performs are references, not additional usages (D32).
- Scripted run: (1) s1 is entered, s1Do starts; (2) perform a1 starts a1 (first perform, D32 rule 3); (3) a1 completes; its token is buffered on the flow to a3.iin (D14); (4) perform a3 starts a3, which consumes the token and completes (D9); (5) s1Do completes; the completion transition fires (D22); (6) done is final, queues are empty, success.
- Pass criteria: exactly one execution each of a1 and a3; the token genealogy shows a1.iout as the origin of the token consumed by a3.iin.

### TC03 - Owning performance at initialization
- Intent: contrast with TC02; a part-level owning performance starts at initialization and runs concurrently with the exhibited state machine.
- Load findings: none.
- Scripted run: (1) initialization starts a1 and the exhibit concurrently; the user steps their order (choice recorded, D10, D18); (2) a1 completes; (3) entry runs, s1 is entered, the completion transition fires (D22); (4) success.
- Pass criteria: a1 starts at initialization, before or concurrently with entry; the trace shows the concurrency and the recorded choice.

### TC04 - Unused item at termination
- Intent: two produced items, one consumed; the leftover item surfaces as E13, with the genealogy naming the producing send.
- Load findings: W02 for (s2, I1) and (done, I1) (over-approximating detection); acknowledged.
- Scripted run: (1) s1 is entered; s1Do sends two fresh I1 instances (distinct identities, D27, D33) and completes; (2) the oldest I1 is dispatched (D31); the transition to s2 fires; (3) s2 is stable; its completion transition takes priority over the queued second I1 (D22); s2 to done; (4) done is final and the queue of p1 is not empty: E13 fires (D34 rules 1 and 2); the report names the second send as the producer of the leftover item; the run is not reported as successful.
- Pass criteria: hard error E13; the genealogy of the reported item resolves to the second send; the first item is reported as consumed.

### TC05 - Protecting transition
- Intent: the example010 two-send handover, minimized, with the unexpected-event protection of convention 15; both dispatch orders are documented.
- Load findings: W02 for (s2, Trigger), (sErr, I1), (sErr, Trigger), (done, I1), (done, Trigger); acknowledged. (s2, I1) is covered by get as the unconditional first step of s2Do.
- Intended path: (1) s1Do performs a1, sends a1.iout, sends a fresh Trigger, and completes; (2) the user dispatches the Trigger (choice); s1 to s2; (3) s2Do: get accepts the queued I1, the flow carries it to a2.iin, perform a2 starts a2, which consumes and completes; s2Do completes; (4) completion s2 to done (D22); queues are empty; success.
- Wrong path: (1) the user dispatches I1 first; the protecting transition s1 to sErr fires and consumes it; (2) the Trigger is still queued; the user dispatches it; no handler of sErr accepts it: D13 hard error with provenance.
- Pass criteria: both paths behave as specified; the wrong path terminates through D13, not through a silent discard.

### TC06 - Undefined ordering dependency
- Intent: a send payload reads an action output that no succession orders before the send; E12 is blocking.
- Load findings: E12 (blocking); W02 for (s2, I1) and (done, I1).
- Expected behavior: the run cannot start (D18). The pilot parser accepts the uncorrected model without findings; the ordering violation is detected only by the simulator (E12). Resolution in the model: an explicit succession, perform a1; then send a1.iout to p1; the corrected model matches TC05 structurally.
- Pass criteria: E12 reported with the reading expression and the unordered producer named.

### TC07 - Trigger payload binding
- Intent: the first handover pattern of deferred-scope item 9, minimized from example011: a single occurrence crosses the transition through payload binding, consumed exactly once.
- Load findings: W02 for (s2, Trigger) and (done, Trigger); acknowledged.
- Scripted run: (1) s1Do sends a fresh Trigger (D33) and completes; (2) the Trigger is dispatched; the transition fires; the effect binds the payload to the part feature (identity preserved, D26, D27); (3) s2 is stable; its completion transition fires (D22); (4) done is final; queues are empty; success.
- Pass criteria: success; exactly one consumption of the occurrence; the bound feature and the sent item have the same identity.

### TC08 - Unknown value and the D11 pause
- Intent: a constructed item attribute without a modeled default is unknown (D15, D33 rule 3); the effect that reads it pauses the run; the user-supplied value is recorded.
- Load findings: W02 for (s2, Payload) and (done, Payload); acknowledged.
- Scripted run: (1) s1Do sends a fresh Payload with unknown code and completes; (2) the Payload is dispatched; the transition effect reads pl.code: D11 pause; the user supplies 42; the choice is recorded (section 3.3); (3) s2 is stable; the completion transition fires (D22); done is final; success.
- Pass criteria: exactly one pause; the recorded value 42 appears in the trace and in the subsequent state of lastCode.

## 5. Discussion points

1. Convention 15 and final states: final states cannot carry outgoing transitions, so every receivable event type yields a W02 pair for every final state (TC04, TC05, TC07, TC08). In the pilot notation the final target is the library done member; there is no final-state usage that could own further transitions. Options: exempt the done target from convention 15 and from W02, or keep the warnings as advisory noise. A decision is pending.
2. Error states: resolved by D35. A plain error state (TC05 sErr, example011 sErr) is legitimate: the machine becomes quiescent in a non-final state, the run ends as an ended-in-state end (D24, D35), and a queued item without a handler surfaces as D13 on the next dispatch rather than as an end. A final error state would instead surface leftover items as E13 (D34 rule 1). Which form a model uses is the modeller's choice and expresses what the modeller wants to show; TC05 and example011 use the plain form and require no change.
3. Example010: TC05 is the minimized resolution of the (s1, I1) question; whether example010 itself receives the protecting transition remains open.

## 6. Validated textual notation

All models in models/ validate against the SysML v2 Pilot Implementation parser (release 2026-08, kernel 0.62.0). The corpus fixes the following textual forms, on which the profile's examples and the test cases rely:

| Construct | Validated form | Note |
| --- | --- | --- |
| Initial transition | `entry;` then `then state s1;` | The entry transition targets the state introduced by the succession shorthand. |
| Chaining in a do behavior | `perform a1;` then `then send a1.iout to p1;` | There is no `first` before a perform; an unchained statement starts at the do behavior's start. |
| `first` | `first get;` for a declared usage, e.g. `action get accept x : defs::I1;` | `first` takes a reference to a declared usage, never a perform or a send. |
| Completion | `then done;` | Targets the `done` completion member of the enclosing exhibited state or do behavior (Action::done, redefined as a state by StateAction in the Systems Library); the pilot grammar has no `final` keyword or final-state notation. |
| Transition shorthand | `accept defs::T via p1 then s2;` directly after the state usage | The source is the preceding state usage; an explicit `s1 accept ...` prefix is invalid syntax. |
| Accept payload naming | `accept tr : defs::Trigger then s2 { ... }` | The name precedes the type. |
| Assignment | `assign p1.received := tr;` | The operator is `:=`; in transition effect bodies `self` did not resolve, so part features are qualified by the part name. |
| Constructor send | `send new defs::Trigger() to p1;` | ConstructorExpression with an item definition (D33). |
| Scalar types | `ScalarValues::Integer` | Library types are not implicitly imported into a model package. |

The pilot parser is silent on all profile-specific findings: it accepts the unordered model of TC06, the concurrent part-level perform of TC03, and the unconsumed items of TC04 without complaint. The E, W, and D findings of the profile therefore remain simulator-side checks.

## 7. Roadmap: second batch

- E01 and E11, positive and negative, including the D32 rule 5 exception for outputs read by an expression.
- W01 for a declared usage that no behavior performs (D32 rule 3).
- W08 for two declared usages of one action definition.
- D23 preemption: a transition firing during a running do behavior; the abort trace with discarded tokens.
- D5 and D30: multiplicity instantiation and indexed references (E06).
- E04: type mismatch across a flow.
- D29: fork and join; behavior completion as join.
- Guards: W03 non-exhaustive decision, W04 constant-false guard, the blocking-guard anomaly.
- D26: bind chains across hierarchy levels.
- D14: the buffer-growth warning for a consumer that never fires.
- D35: an ended-in-state end, a plain terminal state (for example an off or error state) reached with empty queues, and the informational listing of queued items when the modeller ends the run at a pause point (D34 rule 5).
- Two-part cases: cross-part delivery without ports (D31 rule 2) and E03, the unroutable event.
