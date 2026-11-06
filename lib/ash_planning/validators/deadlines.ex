defmodule AshPlanning.Validators.Deadlines do
  @moduledoc """
  Generic window validator: each assignment must start no earlier than its `:release`
  and end no later than its `:deadline` (both optional, inclusive bounds on the
  half-open interval `[start, end)`).

  `validate(problem, assignments)` — `problem` is unused (pass `%{}`); assignments are
  maps with `:id`, `:start`, `:end` and optional `:release`, `:deadline`.

  Violations: `:invalid_interval`, `:invalid_window` (non-numeric bound),
  `:before_release`, `:after_deadline` (detail carries the offending values as `Decimal`).
  Pure; no model lowering.
  """

  @behaviour AshPlanning.Validator

  alias AshPlanning.Validators.Support
  alias AshPlanning.Violation

  @impl true
  def validate(_problem, assignments) when is_list(assignments) do
    {ivs, bad} = Support.intervals(assignments)
    Support.result(bad ++ Enum.flat_map(ivs, &check/1))
  end

  defp check(iv) do
    release = bound(iv, :release)
    deadline = bound(iv, :deadline)

    cond do
      release == :error or deadline == :error ->
        [Violation.new(:invalid_window, iv.id, %{})]

      true ->
        early =
          case release do
            {:ok, r} ->
              if Support.lt?(iv.start, r),
                do: [Violation.new(:before_release, iv.id, %{start: iv.start, release: r})],
                else: []

            nil ->
              []
          end

        late =
          case deadline do
            {:ok, d} ->
              if Support.gt?(iv.end, d),
                do: [Violation.new(:after_deadline, iv.id, %{end: iv.end, deadline: d})],
                else: []

            nil ->
              []
          end

        early ++ late
    end
  end

  defp bound(iv, key) do
    case Support.get(iv.item, key) do
      nil -> nil
      v -> Support.num(v)
    end
  end
end
