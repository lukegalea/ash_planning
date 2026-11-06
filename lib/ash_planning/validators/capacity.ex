defmodule AshPlanning.Validators.Capacity do
  @moduledoc """
  Generic cumulative-capacity validator: at no instant may the summed `:demand` of
  active half-open intervals exceed the capacity.

  `validate(problem, assignments)`:

    * `problem` — map with `:capacity` (integer or `Decimal`); optional `:pinned` items
      (same shape as assignments) count toward load.
    * `assignments` — maps with `:id`, `:start`, `:end`, optional `:demand` (default 1).

  Violations: `:invalid_interval`, `:invalid_demand`, `:invalid_capacity`,
  `:capacity_exceeded` (subject = ids active at the first overloaded instant, detail
  `%{at: start_of_overload, load: load, capacity: capacity}` as `Decimal`s).
  Capacity 1 therefore subsumes no-overlap. Pure; no model lowering.
  """

  @behaviour AshPlanning.Validator

  alias AshPlanning.Validators.Support
  alias AshPlanning.Violation

  @impl true
  def validate(problem, assignments) when is_list(assignments) do
    pinned = Support.get(problem, :pinned) || []

    case Support.num(Support.get(problem, :capacity)) do
      {:ok, capacity} -> check(capacity, assignments ++ pinned)
      :error -> {:error, [Violation.new(:invalid_capacity, nil, %{})]}
    end
  end

  defp check(capacity, items) do
    {ivs, bad} = Support.intervals(items)

    {loads, bad_demand} =
      Enum.reduce(ivs, {[], []}, fn iv, {ok, bad} ->
        case Support.num(Support.get(iv.item, :demand) || 1) do
          {:ok, d} -> {[Map.put(iv, :demand, d) | ok], bad}
          :error -> {ok, [Violation.new(:invalid_demand, iv.id, %{}) | bad]}
        end
      end)

    # Load only changes at interval starts; the max over start points is the max load.
    {over, _} =
      loads
      |> Enum.map(& &1.start)
      |> Enum.uniq_by(&Decimal.to_string/1)
      |> Enum.sort(Decimal)
      |> Enum.reduce({[], false}, fn t, {acc, prev_over?} ->
        active =
          Enum.filter(loads, &(not Support.gt?(&1.start, t) and Support.gt?(&1.end, t)))

        load = active |> Enum.map(& &1.demand) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        cond do
          not Support.gt?(load, capacity) ->
            {acc, false}

          # One violation per contiguous overloaded stretch.
          prev_over? ->
            {acc, true}

          true ->
            v =
              Violation.new(:capacity_exceeded, Enum.map(active, & &1.id), %{
                at: t,
                load: load,
                capacity: capacity
              })

            {[v | acc], true}
        end
      end)

    over = Enum.reverse(over)

    Support.result(bad ++ Enum.reverse(bad_demand) ++ over)
  end
end
