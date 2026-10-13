# SysML v2 Behavior Simulator

A logical, untimed simulator for SysML v2 behavior models. The simulator executes a single
concrete, user-stepped run of a model in order to:

1. validate that flows, actions, and states are correctly connected;
2. visualize what happens during a run;
3. trace the origin of errors.

Explicitly out of scope: physics, equation solving, finite element analysis, continuous
time, quantitative results, and exhaustive state-space exploration.

## Approach

The simulator is a client of a modeling tool: it loads the model through a REST API as a
JSON graph, never in textual notation. An adapter maps the graph onto an internal
simulation metamodel; the static checks, the expression evaluator, and the execution
kernel operate exclusively on that metamodel. The concrete API schema is treated as
replaceable and is isolated in the adapter.

Expressions arrive as operator trees within the graph, not as textual strings, so the
simulator contains no textual parser. Each run executes on an immutable, read-only
snapshot of the model and produces its own trace; the model store is never modified.

## Repository layout

- `docs/semantic-profile.md` — the specification baseline: simulation semantics,
  decisions D1 through D32, error semantics, static check catalogue, expression
  evaluator semantics, and the supported modeling conventions.
- `docs/simulation-metamodel.md` — the simulator-internal metamodel and the inputs
  required from the modeling tool for the adapter.
- `models/diagnostic-system.sysml` — the reference example model (textual rendering;
  status DRAFT pending validation against the SysML v2 Pilot Implementation parser).

## Planned roadmap

1. Provisional JSON graph schema derived from the metamodel, including an example
   export of the DiagnosticSystem model.
2. Python implementation, test-first: metamodel types, graph loader, static checks,
   expression evaluator, execution kernel with interactive pause-and-choose stepping.
3. Replacement of the provisional schema with the real modeling tool API adapter.

## Status

Specification baseline complete; implementation not yet started.
