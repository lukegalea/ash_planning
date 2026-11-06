defmodule AshPlanning.Candidate do
  @moduledoc """
  One proposed solution. Backends carry candidates in `SolveResult.payload.candidates`
  as plain maps with these keys; `from_map/1` lifts one into the struct. Objectives and
  assignment values are `Decimal`, never `Float`. Checker verdicts are *recorded* here,
  not judged.
  """

  defstruct [:index, :objective, :checker_output, :checker_ok?, data: %{}]

  @type t :: %__MODULE__{
          index: pos_integer() | nil,
          data: map(),
          objective: Decimal.t() | nil,
          checker_output: String.t() | nil,
          checker_ok?: boolean() | nil
        }

  @doc "Builds a candidate from a backend candidate map."
  @spec from_map(map()) :: t()
  def from_map(%{} = m),
    do:
      struct(__MODULE__, Map.take(m, [:index, :data, :objective, :checker_output, :checker_ok?]))
end
