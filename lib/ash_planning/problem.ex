defmodule AshPlanning.Problem do
  @moduledoc "What a backend is asked to solve: model/checker locations, data, limits."
  @enforce_keys [:model_path]
  defstruct [:model_path, :checker_path, data: %{}, limits: %{}, solver: "gecode", opts: %{}]

  @type t :: %__MODULE__{
          model_path: Path.t(),
          checker_path: Path.t() | nil,
          data: map() | keyword(),
          limits: map(),
          solver: String.t(),
          opts: map()
        }
end
