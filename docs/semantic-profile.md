
# SysML v2 Simulator — Semantic Profile

This document records the language and simulation semantics decisions for the planned SysML v2 behavior simulator. It is the specification baseline from which the tool architecture shall be derived.

## 1. Purpose and Simulation Class

The simulator is a logical, untimed, token-flow interpreter with the purpose of:

1. validating that flows, actions, and states are correctly connected;
2. visualizing what happens during a run;
3. tracing the origin of errors.

Explicitly out of scope: physics, equation solving, finite element analysis, continuous time, quantitative results, and exhaustive state-space exploration.

## 2. Recorded Decisions

### D1 — Simulation nature
A single concrete run, user-stepped and user-observed. The kernel is an operational semantics: a scheduler that moves tokens and dispatches events.

### D2 — Formal kernel
Two interlocking layers:

1. Activity-style token flow: a node fires when its inputs are available, consumes input tokens, and produces output tokens.
2. Event-driven state machines attached to parts: a transition fires when a triggering event arrives and its guard holds.

The layers interlock: a transition may perform an action, and an action completion may constitute an event.

### D3 — Time semantics
Purely causal. A strictly increasing global event counter defines the order of all events. No physical time units. Flow propagation is instantaneous. Time-of-flight delays are not modeled. Time-related constructs (time events, durations) are either excluded from the executability profile or mapped to abstract logical delays.

### D4 — Structure
The part structure is instantiated once at run start and remains static during the run. No structural events (creation, becoming, disbanding).

### D5 — Instantiation of multiplicities
Full multiplicity instantiation. A part usage such as `part sensors[4]` yields four independent instances, each with its own features, its own state machine, and its own event queue. Rationale: error traces can name the exact originating instance, and indexed routing faults are detectable.

### D6 — Item flows on connections
A flow carries a single item. Item multiplicities (flows carrying collections) are excluded from the first version.

### D7 — Scope: inter-part from the start
Simulation covers behavior within parts and flows and events between parts. Consequences:

1. A routing layer maps an item flow crossing a connection into an event placed in the receiving part's queue.
2. Each part owns a first-in-first-out event queue.
3. The visualization must highlight crossings of part boundaries.

### D8 — Event and step semantics
Run-to-completion for state machine transitions: once a transition starts, its guard, effects, and completion behaviors run to completion before the next event is dispatched to that part. One user interaction step corresponds to one event dispatch or one run-to-completion cycle.

### D9 — Non-streaming executability profile
An action requires all of its non-streaming inputs, computes, and produces all of its outputs. Streaming inputs and outputs are excluded from the first version.

### D10 — Non-determinism resolution
The simulation pauses and the user chooses. Options are presented at the pause point (enabled transitions, racing actions). The choice is recorded in the trace so that runs can be replayed deterministically.

### D11 — Non-executable behavior
When execution reaches behavior without an executable body (for example a function without a modeled body), the simulation pauses and shows the affected element to the user, who may supply the output values manually or abort. A small expression evaluator automatically computes expressions that are fully determined by known values (arithmetic, comparison, boolean logic over features); a pause occurs only when a value is genuinely unknown.

### D12 — Constraints
Constraints are never constitutive. Simple boolean constraints may be evaluated post-hoc as advisory checks.

### D13 — Unhandled events are hard errors
An event arriving at a part in a state where no transition can accept it is a hard error: the run terminates with a fatal error report, including the full provenance of the event and its sender. Rationale: this enforces explicit behavior in the model; implicit discarding is not permitted.

### D14 — Flow buffer semantics
An unbounded first-in-first-out buffer applies per consuming input, both between actions within a behavior and at part event queues. Producers never block. A buffer growing beyond a threshold produces a warning, since unbounded growth indicates a consumer that never fires. Rendezvous and bounded buffers are rejected: rendezvous can create scheduler-induced deadlocks, and SysML v2 does not carry standardized buffer capacities.

### D15 — Initial values
Initial feature values come from modeled defaults only (for example `attribute speed : Real = 0`). Features without a modeled default remain undefined; any expression requiring an undefined value triggers the D11 pause. Implicit zero defaults are rejected: they would mask wiring errors.

### D16 — Run start
The run begins with a single initialization event: the structure is instantiated (D5), defaults are evaluated (D15), and every part's `do` behaviors and all `initially` successions start. Everything thereafter is user-stepped. Part-level performed actions (`performedActions` of a part) start at initialization and run concurrently with the part's exhibited state machine (D19). A part-level action usage declared without perform is not started by initialization; it is started by the behaviors that perform it (D32).

### D17 — Expression evaluator
A tier-one subset: Boolean, Integer, Real, String, and enumerations; comparisons; boolean operators; arithmetic; conditional expressions; item constructor expressions (D33); and feature references through qualified names and `self`. Collections and sequences are excluded. Unknown operands propagate as unknown and trigger the D11 pause; expressions fully determined by known values are computed automatically.

### D18 — Static findings enforcement
Structural errors (unfed required input, missing initial state, unroutable event, type mismatch) prevent a run from starting. Warnings (unreachable nodes, potential unhandled events, buffer growth) are displayed but not blocking.

### D19 — Requirements, allocations, analyses
Execution follows only explicit constructs: `perform`, `do`, and structural containment. Allocations are descriptive metadata and are ignored by the simulator. Requirements and analyses are out of scope.

### D20 — Model access and representation
The simulator accesses the model as a client through a REST API with JSON serialization. The authoritative model representation is a graph structure, not textual notation. Consequences:

1. The simulator defines an internal simulation metamodel covering the semantic subset decided in D1 through D19. An adapter layer maps the JSON graph onto this metamodel. The concrete API schema is treated as replaceable and is isolated in the adapter, so that later schema changes do not affect the kernel.
2. Expressions arrive as operator trees within the graph, not as textual strings. The simulator therefore contains no textual parser; the evaluator consumes expression nodes directly.
3. All static checks and all semantic operations act on the simulation metamodel, never directly on the API schema.

### D21 — Run isolation and access mode
The simulator is strictly read-only toward the model store. Each run executes on an immutable snapshot: at run start, the model is loaded once through the API and copied into the simulation metamodel; all checks and all execution act on that snapshot. Consequences:

1. Runs are reproducible against the exact model version they started from; the snapshot is retained together with the trace.
2. No change-notification or synchronization mechanism is required in the API.
3. Findings such as explicit-unused declarations (E11) must exist in the model; the simulator cannot persist them and therefore cannot resolve findings on behalf of the modeler.
4. Traces and results are produced and stored by the simulator itself, not written back to the model store.

### D22 — Completion transitions
Triggerless completion transitions are part of the executability profile. A completion transition becomes enabled when the enclosing state's entry behavior and do behavior have run to completion. Completion conditions are evaluated before the next event is dispatched to the part, so completion transitions take priority over queued events.

### D23 — Preemption of do behaviors
When a transition fires while a state's do behavior is executing, the do behavior is aborted immediately. Any action in progress at the abort instant is terminated, and all tokens within the do behavior are discarded. The abort is recorded in the trace with the position of every discarded token; discarding is reported, never silent. The exit behavior then runs.

### D24 — Run termination
A run ends successfully only when all parts' state machines are in a final state. Quiescence with at least one part not in a final state is the deadlock anomaly of section 3.2. W02 statically reports events that could arrive in unprotected states, including final states. The implicit done state that a top-level completion transition of an exhibited state machine reaches is final for this purpose; the adapter marks it accordingly.

### D25 — Ports and event identity
Ports carry multiple typed items. Event identity is the triple of receiving part instance, port, and item type. The receiving part holds one first-in-first-out queue per (port, item type) pair, refining D7 and D14; an accept action matches the oldest event in its queue, and its guard is evaluated on the payload of that event.

Superseded in part by D31: ports are optional, the queue key is the item type, and each entry carries an optional port qualifier. Self-delivery (D28) is the untagged case.

### D26 — Items, payload structure, and bind
Items are structured: an item type may carry attributes, for example an error code as Integer. The complete item value, including all attributes, travels unchanged across connections and bind chains. Bind is used for abstraction-level item transfer: the routing layer follows flow delegation across hierarchy levels and delivers the event with its full payload. Guards may navigate payload attributes through feature access on the accepted item (section 6.5). Bind is additionally used to alias feature values: bound features denote one shared value; reading either feature yields the current value, and assignment to either bound feature changes it for both (section 6.5).

### D27 — Item identity
Exchanged items are instances with identity, modeled as parts. Item values are references, not copies; the evaluator never mutates a payload, so references are safe. Token genealogy (section 3.3) tracks item identity across part boundaries. An explicit ID attribute convention may be used for readability and external tooling, but it is not required for identity tracking.

### D28 — Self-directed events
A send action may target the sending part itself, delivering an event to the part's own state machine. The event is placed in the part's own queue and is dispatched only after the current run-to-completion step has finished (D8); self-sends never take effect immediately or recursively.

### D29 — Behavior completion
A behavior completes implicitly when all its sub-actions have completed and no successor remains enabled; no explicit end node is required. An explicit end node in the graph, should the modeling tool provide one, maps to a no-op marker with no additional semantics. The implicit completion acts as a join: after a fork, the behavior completes only when every branch has completed. Completing a behavior never cancels an event it has sent; the event is dispatched after the current run-to-completion step (D28). Stopping execution despite other running branches is not a behavior-internal construct; it is realized only through transition preemption (D23).

### D30 — Indexed references through multiplicity
A perform reference or send target through a part usage with multiplicity greater than one must carry an explicit instance index. Unindexed references are static findings (E06). Broadcast semantics, in which an unindexed reference denotes all instances, is excluded from the profile.

### D31 — Port-less event routing
Ports are optional in event routing. This decision resolves a latent contradiction between D25, which keys every queue on a port, and D28, which places self-sent events in the part's own queue without a port. It also aligns the profile with the graph representation of D20, in which the receiver of a send action and of an accept action is a part usage; a model need not contain any port.

1. An event occurrence is identified by the pair of receiving part instance and item type, and carries an optional port qualifier.
2. A send action may address a port usage (the event is tagged with that port), another part usage (untagged direct delivery), or the sending part itself (untagged self-delivery, D28). The sender is materialized by the adapter as the part instance performing the enclosing behavior.
3. Each part instance holds one first-in-first-out queue per item type, refining D7 and D14. Each entry records its optional port qualifier and its global event number (D3).
4. An accept action with an explicit port matches only entries tagged with the same port instance; an accept action without a port matches every entry of its item type. An accept action without an explicit receiver defaults to the part instance performing the enclosing behavior. The guard is evaluated on the payload of the matched event.
5. Dispatch takes the oldest entry of a queue; if no active acceptor matches it, D13 applies. Entries are never reordered or silently discarded.
6. The absence of a port is not a finding. E06 remains reserved for references that do not resolve or resolve ambiguously, including an incomplete payload operator chain.

Consequential edits: convention 5 is reworded; the detection methods of E03, W02, and W05 are extended to port-less and self-directed sends.

### D32 — Perform references and usage counting
A model declares each action usage once; behaviors may reference the declared usage through perform. This decision records how many usages and how many executions exist and when they start.

1. A perform that declares the usage, for example `perform action a1 : defs::A1;`, is an owning performance. At part level it starts at initialization and runs concurrently with the exhibited state machine (D16); within a behavior it starts when the behavior reaches it.
2. A perform that references an existing usage, for example `perform a1;`, is a PerformActionUsage whose reference subsetting targets the declared usage. It denotes the same execution as the referenced usage; it creates no additional usage and no additional execution. The parser graph contains two elements joined by ReferenceSubsetting, but they denote one occurrence.
3. The execution of a declared usage that is not itself performed starts when the first perform referencing it is reached. A reference perform of a running execution joins it: the performing step completes when the referenced execution completes. A reference perform of a completed execution is satisfied immediately. A declared usage that no behavior ever performs never starts and is reported under W01.
4. Input and output wiring is checked on the declared usage (E01, E11). Flows declared in any behavior of the part that target or source the pins of the declared usage count as wiring of that usage.
5. An action output that no flow carries but that at least one expression reads, for example as a send payload, is not an orphan. Reading it before production is the finding E12 and, at runtime, a D11 pause.

Consequential edits: convention 10 is reworded; the W08 wording and the E11 condition are narrowed to declared usages; D16 references this decision.

### D33 — Constructor expressions for item types
A ConstructorExpression of an item type, for example `new defs::StateTransitionTrigger()`, is admitted to the tier-one subset (D17) in every value position, for example as a send payload or on the right side of an assignment. Rules:

1. The argument expressions, if any, must themselves be tier-one (D17); an argument outside the subset is E07.
2. Each evaluation creates a fresh item instance with identity (D27); two evaluations never yield the same instance.
3. An argument initializes the attribute it targets; an attribute without an argument takes its modeled default (D15) and remains unknown if no default is modeled.
4. Constructor expressions of non-item types and other allocation constructs remain outside the profile (E07, E08).

Consequential edits: D17 names item constructor expressions as part of the subset; section 6.6 records that the construction sends no events and changes no features.

## 3. Error Semantics

### 3.1 Structural findings (static, before any run)

| Finding | Description |
| --- | --- |
| Unfed required input | A required input pin of an action has no incoming flow; the action can never fire. |
| Orphan output | An output pin produces tokens with no destination. |
| Unreachable node | An action or state that cannot be reached from any initial state or start behavior. |
| Missing initial state | A state machine without a defined initial state. |
| Unroutable event | An event that no part can ever accept. |
| Type mismatch | A flow whose item type does not conform to its counterpart. |

### 3.2 Runtime anomalies (during a run)

| Anomaly | Description | Reaction |
| --- | --- | --- |
| Deadlock | The system becomes quiescent while at least one part is not in a final state (D24). | Pause and report. |
| Event without accepting transition | An event arrives at a part in a state where no transition can accept it. | Hard error (D13): the run terminates with a fatal error report and full event provenance. |
| Blocking guard | A guard permanently prevents a branch from being taken. | Report as a warning when detected. |
| Stranded token | A token can no longer proceed to any successor. | Pause and report. |
| Arithmetic fault | Division by zero or an invalid operation on known operands. | Hard error: the run terminates with provenance of the expression and its inputs. |

### 3.3 Token genealogy
Every token carries a causal history: the nodes it passed through and the decisions that produced it. Runtime anomalies present this provenance so that the user can trace from which side of the model an error originated. User choices at pause points are part of the recorded history, enabling deterministic replay.

## 4. Deferred Scope

The following are deliberately out of scope for the first version and may be revisited later:

1. Streaming inputs and outputs (excluded by D9).
2. Flows carrying item multiplicities, that is, collections (excluded by D6).
3. Physical time and time events (excluded by D3); abstract logical delays remain possible.
4. Structural dynamics (excluded by D4).
5. Semantic interpretation of allocations (excluded by D19).
6. Messaging over occurrences, the planned model extension. The trace format is occurrence-based from the start, so this extension enriches the trace rather than breaking it.
7. Orthogonal (parallel) state regions. Parallelism is modeled exclusively through fork and join inside behaviors.
8. Broadcast semantics for unindexed references and send targets through part usages with multiplicity (excluded by D30).
9. Broadcast of a single event occurrence to multiple acceptors. An occurrence is consumed exactly once; the handover of an item across a state transition is modeled either through trigger payload binding on the transition or through a second send whose event is consumed by an accept action in the target state's do behavior, never through multiple consumption.

All modeling-convention clarifications are resolved. The unexpected-event convention (an else-guarded or default transition to an explicit error state for every event type a state can receive) is adopted as a mandatory modeling rule; W02 reports violations of this rule (see section 8).

## 5. Static Check Catalogue

All checks operate on the simulation metamodel after loading, never on the API schema. Per D18, errors block a run; warnings are advisory and may be acknowledged by the user for a single run. Findings are resolved in the model itself, for example by declaring an output explicitly unused or by adding an else transition, not by tool configuration.

### 5.1 Errors (blocking)

| ID | Check | Condition |
| --- | --- | --- |
| E01 | Unfed required input | An action input has no incoming flow and no modeled default. |
| E02 | Missing initial state | A state machine used as a do behavior has no initially enabled transition; a composite state has no initial transition. |
| E03 | Unroutable event | An event type that can be produced somewhere in the model has no part that can ever accept it. |
| E04 | Type mismatch | A flow or connection carries an item type that does not conform to the receiving input, parameter, or port type. |
| E05 | Multiplicity mismatch | A connection joins ports or flows with incompatible multiplicities. |
| E06 | Unresolved or ambiguous reference | An expression or a perform, do, or send reference names a feature, behavior, or action usage that cannot be resolved statically, or resolves ambiguously, for example through a part usage with multiplicity greater than one without an explicit index (D30). |
| E07 | Expression outside profile | The expression graph uses types, operators, or constructs outside the tier-one subset (D17). |
| E08 | Construct outside profile | The model uses streaming (D9), item multiplicities (D6), or physical time constructs (D3) without a defined mapping. |
| E09 | Uninstantiable part | A part usage resolves to an abstract or missing part definition. |
| E10 | Recursive containment | A part directly or indirectly contains itself with unbounded multiplicity, which would produce infinite instantiation. |
| E11 | Orphan output | An action output produces tokens with no destination, that is, no outgoing flow and no expression reading it (D32), and is not explicitly declared unused in the model. |
| E12 | Undefined ordering dependency | An expression, for example a send payload or a computed output, reads a feature of another occurrence while no explicit succession or flow orders that occurrence before the reading occurrence. The kernel does not derive implicit data dependencies; the model must express the ordering explicitly. |

### 5.2 Warnings (advisory)

| ID | Check | Condition |
| --- | --- | --- |
| W01 | Unreachable node | An action or state cannot be reached from any initially started behavior or initial state. |
| W02 | Potential unhandled event | Part P may statically receive event type E in state S while no transition of S accepts E, no else or completion transition covers it, and no accept action that the do behavior of S reaches unconditionally accepts E. Runtime verification of such a situation is a hard error (D13). |
| W03 | Non-exhaustive decision | A decision node has no else guard and its guards are not provably exhaustive. |
| W04 | Constant-false guard | A guard is statically always false; the transition or branch can never fire. |
| W05 | Unproducible trigger | A transition trigger names an event type that no element in the model ever produces. |
| W06 | Unused part | No event or initial construct can ever trigger any behavior of the part. |
| W07 | Deadlock potential | A composite structure can become quiescent while behavior is incomplete; reported where decidable. |
| W08 | Multiple usages of one action definition | An action definition acquires more than one declared usage, violating convention 10 and making state machine references ambiguous; reference performs of the one declared usage are not usages (D32). |

Detection method for W02: for each part, compute the set of event types it can receive, from item flows across connections targeting it and from send actions in other parts, including port-less sends and self-sends (D31), and the set of statically reachable states. Report every (state, event type) pair not covered by an accepting transition, an else guard, a completion transition, or an accept action that the do behavior of the state reaches unconditionally, that is, without an intervening guard, decision, or event-dependent step; where this reachability is not decidable, the pair is reported, as with W07. The computation over-approximates, which is why the finding is a warning; at runtime, D13 applies.

## 6. Expression Evaluator Semantics

### 6.1 Representation
Expressions arrive as operator trees within the model graph (D20), not as textual strings. The evaluator consumes expression nodes directly; a node outside the tier-one subset is finding E07.

### 6.2 Values
Known values are: Boolean; Integer without fixed width; Real as IEEE-754 double; String as a Unicode sequence; enumeration values; and references to part or item instances, which compare by identity. Additionally, the unknown value exists: a feature that is unset or undefined holds unknown (D15).

### 6.3 Unknown propagation
Strong Kleene three-valued logic. `not` applied to unknown yields unknown. `and` yields false if either operand is false; `or` yields true if either operand is true; `implies` yields true if the antecedent is false; otherwise unknown. Every comparison, arithmetic operation, or feature access with an unknown operand yields unknown. An unknown result in a guard triggers the D11 pause; the user-supplied value becomes a known value and is recorded in the trace.

### 6.4 Operators
- Boolean: not, and, or, xor, implies.
- Equality: = and not-equals, on all known types; references by identity.
- Ordering: <, ≤, >, ≥, on Integer and Real.
- Arithmetic: +, −, ×, ÷, and unary minus, on Integer and Real. Division always yields Real. Division by zero on known operands is a runtime hard error with provenance (section 3.2).
- Conditional: if-then-else node; the condition is evaluated first, and branches are evaluated lazily.
- Feature access: navigation node; resolution is defined in 6.5.

### 6.5 Feature resolution
Scopes resolve innermost first. In an action: the action parameters, then local features of the enclosing behavior, then the features of the part instance performing the behavior, reached through `self`. In a transition guard or effect: the trigger parameters bound to the event payload, then features of the state machine, then `self`. `self` always denotes the part instance performing the behavior (D7). A reference to a statically nonexistent feature is finding E06; a reference to a currently unset feature yields unknown. Bound features are evaluated lazily on read; modeled defaults are evaluated at initialization (D15, D16). Feature access on an accepted item navigates its attributes, so guards may reference payload attributes such as an error code (D26). Feature value bindings (D26) are aliases: reading a bound feature yields the current value of the shared value, and assignment to either bound feature changes it for both. The name done inside an action body denotes the completion of the innermost enclosing behavior and is resolved contextually by the adapter; the model graph may represent it as a single shared element (observed in the Pilot Implementation graph of example010), in which case element identity must not be used to distinguish the completions of different behaviors.

### 6.6 Purity and effects
Expressions are pure: they produce no events and change no features. All effects are behavior constructs; in the first version these are assignment to a feature and sending of an event. The construction of a fresh item instance (D33) sends no events and changes no features; it is admitted in expressions for that reason. Guards are evaluated at event dispatch; decision conditions at token arrival.

## 7. Conformance Baseline

The simulator implements an operational semantics for a defined subset of SysML v2 and KerML. Where the official specifications and the reference Pilot Implementation of the SysML v2 Release project define semantics for the executable subset, the simulator shall align with them. Deviations must be documented explicitly in this profile.

## 8. Supported Modeling Conventions

The simulator targets the following modeling style, which the adapter (D20) must recognize:

1. Each part with behavior exhibits exactly one state machine as its root behavior.
2. State transitions are triggered by accept actions; events originate in send actions. No implicit event generation exists.
3. Behavior inside states is described through entry, do, and exit. Completion transitions (D22) are used after entry and do complete.
4. All behavior is described as actions. Items carry objects and information; energy flows are not modeled; flows are not streams.
5. Items flow between parts through ports where ports are modeled; direct part-to-part and self-directed delivery without a port is also supported (D31). Ports carry multiple typed items; event identity is the pair of receiving part instance and item type with an optional port qualifier (D25, D31).
6. Bind is used for abstraction-level item transfer; the routing layer follows flow delegation across hierarchy levels, carrying the complete structured payload including all attributes (D26).
7. Item flows are modeled separately from succession flows, which express the order of activation of actions.
8. Decisions use decision nodes with explicit if and else.
9. Parallel behavior is modeled explicitly with fork, join, and merge.
10. Actions are predefined and referenced through perform. Each action definition has exactly one declared usage; further perform references to the declared usage are references to the same execution, not additional usages (D32).
11. Planned extension: messages during occurrences (see deferred scope, item 6).
12. Items are instances with identity; item types may be structured with attributes (D27).
13. A part may send events to itself; self-sends are dispatched after the current run-to-completion step (D28).
14. No orthogonal state regions; parallelism is modeled only with fork and join.
15. The unexpected-event convention is mandatory: every reachable state must handle every event type it can receive, either through a specific transition or through an else-guarded or default transition to an explicit error state. W02 reports violations.
16. References to action usages from state machines use qualified names; through part usages with multiplicity greater than one, an explicit instance index is required (D30).
