defmodule AshPlanning.Backend do
  @moduledoc """
  Solver backend behaviour.

  A backend turns a `AshPlanning.Problem` into a `AshPlanning.SolveResult` through an
  opaque session reference. Honesty rules every backend must honour:

  * `:infeasible` only when the solver *proved* unsatisfiability. A timeout with an
    incumbent is `:feasible` + `complete?: false` + `optimality: :none`; a timeout without
    one is `:unknown`.
  * `optimality: :proven` only with a solver optimality certificate.
  * Numeric values (objectives, assignments) are `Decimal`, never `Float`.
  """

  alias AshPlanning.{Error, Problem, SolveResult}

  @capability_keys [
    :integer_variables,
    :optional_intervals,
    :cumulative,
    :no_overlap,
    :time_windows,
    :precedence,
    :objective_bound,
    :warm_start,
    :routing
  ]

  @doc "The nine v1 capability keys."
  @spec capability_keys() :: [atom()]
  def capability_keys, do: @capability_keys

  @type session_ref :: term()
  @type status :: %{
          stage: :compiling | :solving,
          solution_count: non_neg_integer(),
          running_time_ms: non_neg_integer()
        }

  @callback capabilities() :: %{required(atom()) => boolean()}
  @callback start(Problem.t() | map(), keyword()) :: {:ok, session_ref()} | {:error, Error.t()}
  @callback await(session_ref(), timeout()) :: {:ok, SolveResult.t()} | {:error, Error.t()}
  @callback status(session_ref()) :: {:ok, status()} | {:error, :not_running}
  @callback cancel(session_ref()) :: :ok | {:error, :not_running | {:survivors, [pos_integer()]}}
end
