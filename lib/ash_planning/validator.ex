defmodule AshPlanning.Validator do
  @moduledoc """
  The independent Elixir validator behaviour. A validator re-checks a candidate's
  assignments against the problem with code that shares nothing with the model's
  lowering, so a model bug and a validator bug must coincide to slip through.
  """

  @callback validate(problem :: term(), assignments :: term()) ::
              :ok | {:error, [AshPlanning.Violation.t()]}
end
