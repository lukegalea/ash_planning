defmodule AshPlanning.ValidatorsTest do
  use ExUnit.Case, async: true

  alias AshPlanning.Validators.{Capacity, Deadlines, Intervals}

  defp codes({:error, vs}), do: Enum.map(vs, & &1.code)

  describe "Intervals" do
    test "touching half-open intervals are fine" do
      assert :ok =
               Intervals.validate(%{}, [
                 %{id: "a", start: 0, end: 5},
                 %{id: "b", start: 5, end: 9}
               ])
    end

    test "overlap, pinned overlap, and malformed intervals" do
      assert [:overlap] =
               codes(
                 Intervals.validate(%{}, [
                   %{id: "a", start: 0, end: 5},
                   %{id: "b", start: 4, end: 9}
                 ])
               )

      problem = %{pinned: [%{id: "m", start: 10, end: 12}]}

      assert [:overlaps_pinned] =
               codes(Intervals.validate(problem, [%{id: "a", start: 11, end: 13}]))

      assert [:invalid_interval] = codes(Intervals.validate(%{}, [%{id: "a", start: 3, end: 3}]))
    end

    test "resources isolate conflicts; string keys and Decimals work" do
      items = [
        %{"id" => "a", "start" => Decimal.new("0.5"), "end" => 5, "resource" => "r1"},
        %{"id" => "b", "start" => 4, "end" => 9, "resource" => "r2"}
      ]

      assert :ok = Intervals.validate(%{}, items)
    end

    test "floats are refused, not coerced" do
      assert [:invalid_interval] =
               codes(Intervals.validate(%{}, [%{id: "a", start: 0.5, end: 2}]))
    end
  end

  describe "Capacity" do
    test "within and over capacity" do
      a = %{id: "a", start: 0, end: 4, demand: 2}
      b = %{id: "b", start: 4, end: 8, demand: 2}
      c = %{id: "c", start: 3, end: 6, demand: 1}
      assert :ok = Capacity.validate(%{capacity: 2}, [a, b])
      assert [:capacity_exceeded] = codes(Capacity.validate(%{capacity: 2}, [a, b, c]))
    end

    test "capacity 1 default demand subsumes no-overlap; pinned counts" do
      assert :ok =
               Capacity.validate(%{capacity: 1}, [
                 %{id: "a", start: 0, end: 2},
                 %{id: "b", start: 2, end: 4}
               ])

      assert [:capacity_exceeded] =
               codes(
                 Capacity.validate(%{capacity: 1, pinned: [%{id: "p", start: 1, end: 3}]}, [
                   %{id: "a", start: 0, end: 2}
                 ])
               )

      assert [:invalid_capacity] = codes(Capacity.validate(%{}, []))
    end
  end

  describe "Deadlines" do
    test "release and deadline bounds" do
      ok = %{id: "a", start: 2, end: 5, release: 2, deadline: 5}
      assert :ok = Deadlines.validate(%{}, [ok])
      assert [:before_release] = codes(Deadlines.validate(%{}, [%{ok | start: 1}]))
      assert [:after_deadline] = codes(Deadlines.validate(%{}, [%{ok | end: 6}]))
      assert :ok = Deadlines.validate(%{}, [%{id: "free", start: 0, end: 1}])
    end
  end
end
