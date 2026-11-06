defmodule AshPlanning.Validators.Support do
  @moduledoc false
  # Shared pure helpers: tolerant field access (atom or string keys) and exact
  # comparison of integers/Decimals. Floats are refused, never coerced.

  @spec get(map(), atom()) :: term()
  def get(%{} = m, key), do: Map.get(m, key, Map.get(m, Atom.to_string(key)))

  @spec num(term()) :: {:ok, Decimal.t()} | :error
  def num(%Decimal{} = d), do: {:ok, d}
  def num(i) when is_integer(i), do: {:ok, Decimal.new(i)}
  def num(_), do: :error

  @spec lt?(Decimal.t(), Decimal.t()) :: boolean()
  def lt?(a, b), do: Decimal.compare(a, b) == :lt
  @spec gt?(Decimal.t(), Decimal.t()) :: boolean()
  def gt?(a, b), do: Decimal.compare(a, b) == :gt

  @doc "Normalises items to `%{id, start, end, raw}` with Decimal bounds, or collects violations."
  @spec intervals([map()], atom(), atom()) :: {[map()], [AshPlanning.Violation.t()]}
  def intervals(items, start_key \\ :start, end_key \\ :end) do
    Enum.reduce(items, {[], []}, fn item, {ok, bad} ->
      id = get(item, :id)

      with {:ok, s} <- num(get(item, start_key)),
           {:ok, e} <- num(get(item, end_key)),
           false <- not gt?(e, s) do
        {[%{id: id, start: s, end: e, item: item} | ok], bad}
      else
        _ ->
          {ok, [AshPlanning.Violation.new(:invalid_interval, id, %{}) | bad]}
      end
    end)
    |> then(fn {ok, bad} -> {Enum.reverse(ok), Enum.reverse(bad)} end)
  end

  @spec result([AshPlanning.Violation.t()]) :: :ok | {:error, [AshPlanning.Violation.t()]}
  def result([]), do: :ok
  def result(violations), do: {:error, violations}
end
