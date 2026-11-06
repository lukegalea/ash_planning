defmodule AshPlanning.Validators.Intervals do
  @moduledoc """
  Generic interval validator: well-formed half-open intervals `[start, end)` that do not
  overlap one another or any pinned occupancy.

  `validate(problem, assignments)`:

    * `assignments` — list of maps with `:id`, `:start`, `:end` (integers or `Decimal`;
      atom or string keys). Optional `:resource` groups items: only items sharing a
      resource (including `nil`) conflict.
    * `problem` — map, optional `:pinned` (same shape as assignments) for occupancy that
      assignments must avoid.

  Violations: `:invalid_interval` (end <= start, non-numeric bound), `:overlap`
  (subject `[id_a, id_b]`), `:overlaps_pinned` (subject `[id, pinned_id]`).
  Touching intervals (`end == start`) do not overlap. Pure; no model lowering.
  """

  @behaviour AshPlanning.Validator

  alias AshPlanning.Validators.Support
  alias AshPlanning.Violation

  @impl true
  def validate(problem, assignments) when is_list(assignments) do
    {items, bad} = Support.intervals(assignments)
    pinned_raw = problem |> pinned() |> Enum.map(&tag_pinned/1)
    {pinned, bad_pinned} = Support.intervals(pinned_raw)

    overlaps =
      for {a, i} <- Enum.with_index(items),
          b <- Enum.drop(items, i + 1),
          same_resource?(a, b),
          overlap?(a, b),
          do: Violation.new(:overlap, [a.id, b.id], %{})

    against_pinned =
      for a <- items,
          p <- pinned,
          same_resource?(a, p),
          overlap?(a, p),
          do: Violation.new(:overlaps_pinned, [a.id, p.id], %{})

    Support.result(bad ++ bad_pinned ++ overlaps ++ against_pinned)
  end

  @doc false
  def overlap?(a, b), do: Support.lt?(a.start, b.end) and Support.lt?(b.start, a.end)

  defp pinned(%{} = problem), do: Support.get(problem, :pinned) || []
  defp pinned(_), do: []

  defp tag_pinned(item), do: item

  defp same_resource?(a, b), do: Support.get(a.item, :resource) == Support.get(b.item, :resource)
end
