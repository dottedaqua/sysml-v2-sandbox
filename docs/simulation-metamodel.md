
# Simulation Metamodel — SysML v2 Simulator

The simulation metamodel is the simulator-internal representation (D20 of the semantic profile). The adapter translates the modeling tool's JSON graph into it; all static checks, the expression evaluator, and the kernel operate exclusively on these elements. Every element retains a reference to its source element in the graph, so that findings and trace events can be traced back to the model in the tool.

## 1. Structural Elements

| Element | Purpose | Essential properties |
| --- | --- | --- |
| PartDefinition | Type of a part; owns features, ports, and the root behavior. | Name; abstract flag (E09); specialization; owned elements. |
| PartUsage | Named occurrence of a part within an owning part. | Name; type; multiplicity (D5). |
| PortUsage | Port of a part; anchor for inter-part flows. | Name; carried item types, at least one (D25). |
| Connection | Link between two ports. | Source port; target port; carried item types. |
| ItemDefinition | Structured item type; attributes travel with the payload (D26). | Attributes with name, type, and optional default; specialization of the scalar types Boolean, Integer, Real, String, or of enumerations. |
| Attribute | Data feature of a part. | Name; type; default expression (D15); multiplicity. |
| FlowBind | Abstraction-level flow delegation; routing concern (D26). | Bound item flows or ports at different hierarchy levels. |
| ValueBind | Feature alias across levels; evaluation concern (D26). | Two bound features denoting one shared value. |

A PartDefinition owns at most one StateMachine as root behavior (convention 1 of the profile). Parts without behavior own none.

## 2. Behavioral Elements

| Element | Purpose | Essential properties |
| --- | --- | --- |
| ActionDefinition | Reusable behavior. | Input and output parameters with type and direction. |
| ActionUsage | Usage of an action definition inside a behavior, referenced through perform (convention 10). | Definition; input bindings; outputs. |
| SuccessionFlow | Control edge; order of activation of actions (convention 7). | Source action usage; target action usage. |
| ItemFlow | Data edge; carries one item (D6). | Source output; target input; item type. |
| DecisionNode | Branching with explicit else (convention 8, W03). | Branches with guard expressions; exactly one else branch. |
| ForkNode | Explicit start of parallel branches (convention 9). | Multiple outgoing SuccessionFlows. |
| JoinNode | Synchronization; waits for all incoming branches. | Multiple incoming SuccessionFlows. |
| MergeNode | Union of alternative branches. | Multiple incoming; one outgoing SuccessionFlow. |
| AcceptAction | Consumes an event; triggers transitions or continues a behavior. | Item type; port; payload binding; guard evaluated on the payload (D25, D26). |
| SendAction | Produces an event. | Target part or self (D28), with explicit instance index when the target multiplicity is greater than one (D30); port; item type; payload expression. |
| AssignmentAction | Sets a feature value. | Target feature path; value expression. |
| OpaqueAction | Action without an executable body. | Inputs; outputs; triggers the D11 pause. |

## 3. State Machine Elements

| Element | Purpose | Essential properties |
| --- | --- | --- |
| StateMachine | Root behavior of a part (convention 1, D16). | Owned states and transitions. |
| State | State with entry, do, and exit. | Entry, do, exit as perform references; nested substates; final flag (D24). |
| Transition | State change. | Source; target; trigger as AcceptAction, or triggerless completion including the initial transition (D22); guard with optional else; effect as assignments, sends, and performs. |

## 4. Expression Elements

Operator trees, not text (D20). Semantics per section 6 of the profile.

| Element | Purpose |
| --- | --- |
| BooleanLiteral, IntegerLiteral, RealLiteral, StringLiteral, EnumLiteral | Known constant values. |
| FeatureAccess | Navigation: `self` plus a path of feature names; payload attribute access included (D26). |
| Not, And, Or, Xor, Implies | Boolean operators, strong Kleene semantics for unknown (profile section 6.3). |
| Equals, NotEquals | Equality on all known types; identity for references (profile section 6.4). |
| Less, LessEqual, Greater, GreaterEqual | Ordering on Integer and Real. |
| Plus, Minus, Multiply, Divide, UnaryMinus | Arithmetic; Divide yields Real; division by zero is a hard error. |
| Conditional | If-then-else with lazy branches. |

## 5. Annotations

| Element | Purpose |
| --- | --- |
| UnusedDeclaration | Marks an output as explicitly unused (E11; the companion to convention 15). |

## 6. Key Relations and Rules

1. Composition: a PartDefinition owns PartUsages, PortUsages, Attributes, and at most one StateMachine. PartDefinition specializes PartDefinition; abstract definitions cannot be instantiated (E09).
2. A Connection joins exactly two PortUsages; routing follows FlowBinds when ports lie at different hierarchy levels (D7, D26).
3. Event identity is the triple of receiving part instance, port, and item type (D25).
4. A behavior contains ActionUsages and exactly the control and data constructs of section 2; a SuccessionFlow never carries items, and an ItemFlow never controls activation (convention 7).
5. Every reachable, non-final state must handle every event type the part can receive, directly or through an else transition (convention 15, W02).
6. A behavior completes implicitly when all its sub-actions have completed; explicit end nodes, should the tool provide them, are no-op markers (D29).
7. Guards are evaluated at event dispatch, decision conditions at token arrival, computed features lazily on read (profile section 6.6).
8. Perform references and send targets through part usages with multiplicity greater than one carry an explicit instance index; unindexed references are findings (E06, D30).

## 7. Runtime Object Model (Derived, Kernel Side)

PartInstance, one per element of full multiplicity instantiation (D5); one first-in-first-out queue per (PortUsage, item type) per part instance (D25); Token with causal genealogy for provenance (profile section 3.3); Occurrence records forming the trace, designed for later extension to messaging over occurrences; Pause records containing user choices and user-supplied values for deterministic replay (D10, D11).

## 8. Required from the Modeling Tool for the Adapter

To finalize the adapter mapping (D20), the following inputs are required from the modeling tool:

1. The concrete JSON schema of the graph, or a representative example export containing: two parts with state machines, a structured item, a connection with ports, both bind kinds, a decision with else, a fork and join, and accept and send actions.
2. The element type names and identifier conventions of the graph.
3. The serialization of expression trees.
4. The representation of perform, entry, do, and exit references.
5. The representation of multiplicities and of port item types.
6. The representation of annotations (UnusedDeclaration) and of the distinction between FlowBind and ValueBind.
