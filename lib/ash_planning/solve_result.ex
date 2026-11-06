defmodule AshPlanning.SolveResult do
  @moduledoc """
  Terminal solve outcome. `payload.candidates` hold decimal-exact candidate maps (see
  `AshPlanning.Candidate`); checker verdicts ride along per candidate but are *recorded*,
  not judged, here (the host's check pipeline owns judgement).
  """
  @enforce_keys [:status]
  defstruct [
    :status,
    complete?: false,
    optimality: :none,
    outcome_reason: :normal,
    payload: %{candidates: []},
    stats: %{}
  ]

  @type t :: %__MODULE__{
          status: :feasible | :infeasible | :unknown,
          complete?: boolean(),
          optimality: :proven | :none,
          outcome_reason: atom(),
          payload: %{candidates: [map()]},
          stats: map()
        }
end
