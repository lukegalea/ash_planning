# The settled DSL shape

This records the agreed shape for the `model :key do ... end` Spark extension
deferred in [REVERSAL.md](REVERSAL.md) ("returns in a later release once its
shape is settled against real hosts"). The shape is now settled (owner decision,
2026-11). No code implements it yet; this document is the contract a future
release builds against, so hosts can plan around it and the design does not
drift while parked.

## The settled shape

The extension is **a model binding plus the nine v1 capability combinators** —
exactly the keys in `AshPlanning.Backend.capability_keys/0`:

| Combinator          | Constraint family                      |
|---------------------|----------------------------------------|
| `integer_variables` | typed decision variables               |
| `optional_intervals`| optional interval variables            |
| `cumulative`        | cumulative resource limits             |
| `no_overlap`        | disjunctive scheduling                 |
| `time_windows`      | interval placement windows             |
| `precedence`        | ordering between intervals             |
| `objective_bound`   | objective value bounds                 |
| `warm_start`        | hinting from a previous solution       |
| `routing`           | assignment/routing structure           |

No grammar beyond the nine is invented: **MiniZinc is the constraint grammar**.
The combinators are the typed surface over the global constraints hosts
actually need in v1; anything else rides the raw `.mzn` escape hatch (which
stays).

## One declaration, three artifacts

Each combinator declaration derives three artifacts from a single source, so
they cannot disagree:

1. **The MiniZinc global in the reviewed `.mzn`** — the artifact under review,
   hash-pinned as today (the model snapshot's content hash still gates a run).
2. **A check in the Elixir validator** — or a pin to the existing hand-written
   validator where one already covers the family.
3. **A compile-time capability requirement** — checked against the backend a
   host declares, so a backend lacking `:routing` fails at compile, not at
   solve.

## Division of ownership

- **DMN (ash_decisions)** owns lookup tables and policy parameters — decisions
  over *known* values.
- **ash_rules** owns rules over *unknown-valued* facts. The bridge is fixed: an
  unknown becomes an optional constraint or a surfaced gap — never silently
  hard.
- The raw `.mzn` escape hatch stays for everything the nine combinators do not
  express.
