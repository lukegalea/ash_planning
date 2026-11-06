defmodule AshPlanning.Error do
  @moduledoc "Backend failure. `kind` is a closed set; `details` never carries secrets."
  @enforce_keys [:kind]
  defstruct [:kind, :message, details: %{}]

  @type kind ::
          :invalid_model
          | :invalid_problem
          | :resource_governor_unavailable
          | :limit_exceeds_ceiling
          | :solver_unavailable
          | :resource_exhausted
          | :runtime
          | :backend_crashed

  @type t :: %__MODULE__{kind: kind(), message: String.t() | nil, details: map()}
end
