# Reversing ash_planning

`ash_planning` is additive and its fragment resources are inert until a host mounts them.
To remove it:

1. **Remove the domain.** Drop the host planning domain (and its entry in any
   domain registry/GraphQL/JSON:API/A2UI exposure) so no planning action is reachable.
2. **Remove host bindings.** Delete the host resources that use
   `fragments: [AshPlanning.Fragment.*]` (ModelVersion, Binding, Run, Candidate,
   CheckResult), their policies, workers/supervisors and any apply wiring. Generate the
   drop-table migration with the host's normal codegen. Applied assignments live in the
   host's own resources and are unaffected; Run/Candidate rows are proposals, not facts.
3. **Remove the dependency.** Delete `{:ash_planning, ...}` (and `:solverl` if nothing
   else uses it) from `mix.exs`, then `mix deps.clean ash_planning`.

Until step 2 completes the fragments are inert: they hold no processes, schedule nothing
and never write to a host resource other than their own.

## Deferred

The `model :key do ... end` Spark extension (declaring a model binding on a host
resource) is **not** part of 0.1. It is not extractable as designed yet: the incubating
kernel implemented `ModelVersion` + seed instead of the DSL. No DSL is invented here;
it returns in a later release once its shape is settled against real hosts.
