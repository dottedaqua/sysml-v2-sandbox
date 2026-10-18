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
  decisions D1 through D35, error semantics, static check catalogue, expression
  evaluator semantics, and the supported modeling conventions.
- `docs/simulation-metamodel.md` — the simulator-internal metamodel and the inputs
  required from the modeling tool for the adapter.
- `docs/testcases.md` — the unit-level test-case suite: purpose, expected findings, scripted runs, and open discussion points.
- `models/010_example_state_change_item_transition.sysml` and
  `models/011_example_state_change_payload_binding.sysml` — the integration-level
  examples (two-send handover and trigger payload binding).
- `models/testcases/` — small unit-level case models (TC01 through TC08), one rule
  per case.
- `tools/Validate.java` and `.github/workflows/validate-models.yml` — the model
  validation pipeline against the SysML v2 Pilot Implementation parser (release
  2026-08, kernel 0.62.0); runs on every push to main.

## Model validation

Every model in `models/` is validated against the official SysML v2 Pilot
Implementation parser in CI (workflow `validate-models.yml`). The workflow downloads
the `jupyter-sysml-kernel` release artifact, compiles the small helper
`tools/Validate.java`, and runs it over all `*.sysml` files; a syntax or semantic
error fails the build. The pilot parser checks the textual syntax and the language
semantics only; the profile-specific findings (E, W codes) are expectations of the
simulator's own static checks and are catalogued in `docs/testcases.md`.

## Planned roadmap

1. Provisional JSON graph schema derived from the metamodel, including an example
   export of the DiagnosticSystem model.
2. Python implementation, test-first: metamodel types, graph loader, static checks,
   expression evaluator, execution kernel with interactive pause-and-choose stepping.
3. Replacement of the provisional schema with the real modeling tool API adapter.

## Status

Specification baseline complete; implementation not yet started. All example and
test-case models validate against the official pilot parser; the validation runs in
CI on every push.
