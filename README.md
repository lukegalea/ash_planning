# AshPlanning

A constraint-solving **proposal kernel** for [Ash](https://ash-hq.org). A solver backend
turns a problem into candidate assignments; each candidate is verified by the model's
own checker and by an independent Elixir validator; only a person commits one.

Git-only, version 0.1.0 (not published to Hex).

```elixir
{:ash_planning, github: "lukegalea/ash_planning"}
```

Optional: `{:solverl, "~> 1.1"}` enables `AshPlanning.Backend.Solverl` (MiniZinc). Without
it the module is simply not compiled.

## What is in the package

| Module | Role |
|---|---|
| `AshPlanning.Backend` | Behaviour: `capabilities/0`, `start/2`, `await/2`, `status/1`, `cancel/1`. |
| `AshPlanning.Backend.Solverl` | MiniZinc via Solverl (optional dep). Governed (`prlimit`), decimal-exact. |
| `AshPlanning.Backend.Fake` | Deterministic scripted backend for tests. |
| `AshPlanning.{Problem, Candidate, SolveResult, Error, Violation}` | IR structs/shapes. |
| `AshPlanning.Validator` | Behaviour: `validate(problem, assignments) :: :ok \| {:error, [violation]}`. |
| `AshPlanning.Validators.{Intervals, Capacity, Deadlines}` | Generic pure validators. |
| `AshPlanning.Fragment.{ModelVersion, Binding, Run, Candidate, CheckResult}` | Pure `Spark.Dsl.Fragment` resource fragments. |
| `AshPlanning.Snapshot` | Accessors/verification over `AshOpenLineage.Snapshot`. |

The fragments declare attributes, actions, validations and identities only. Policies,
tenancy, encryption of sealed payloads, relationships and the data layer are the host's:

```elixir
defmodule MyApp.Planning.ModelVersion do
  use Ash.Resource,
    domain: MyApp.Planning,
    data_layer: AshPostgres.DataLayer,
    fragments: [AshPlanning.Fragment.ModelVersion]

  # + your policies, tenancy, table, relationships
end
```

## Verification

```
mix format --check-formatted
MIX_ENV=dev mix compile --warnings-as-errors
SHELL=/bin/sh mix test     # erlexec (via solverl) needs $SHELL
mix planning.boundary
```

`mix planning.boundary` fails if the dependency tree or compiled modules reference
`phoenix*`, `ash_phoenix*`, `ash_enterprise*` or `oban*`, or if `test/`/`priv/` fixtures
match a non-synthetic marker from `priv/boundary_markers.txt`.

See `usage-rules.md` and `docs/REVERSAL.md`.
