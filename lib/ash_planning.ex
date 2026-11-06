defmodule AshPlanning do
  @moduledoc """
  A constraint-solving proposal kernel for Ash.

  A backend (`AshPlanning.Backend`) turns an `AshPlanning.Problem` into an
  `AshPlanning.SolveResult` whose candidates are *proposals*: each is checked by the
  model's own checker and by an independent `AshPlanning.Validator`, and only a person
  commits one. The five `AshPlanning.Fragment.*` modules are pure Ash resource
  fragments (attributes, actions, identities — no policies, tenancy, cloak or data layer)
  that a host mixes into its own resources.

  The `model :key do ... end` Spark extension is deferred; see `docs/REVERSAL.md`.
  """
end
