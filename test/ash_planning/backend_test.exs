defmodule AshPlanning.BackendTest do
  use ExUnit.Case, async: true

  alias AshPlanning.{Backend, Problem, SolveResult}
  alias AshPlanning.Backend.Fake

  test "nine capability keys, all offered by the fake" do
    assert length(Backend.capability_keys()) == 9
    assert Enum.all?(Fake.capabilities(), fn {_k, v} -> v end)
  end

  test "fake solve returns proven optimal with decimal objective" do
    problem = %Problem{
      model_path: "m.mzn",
      data: %{fake_candidates: [%{"x" => 1}], fake_objective: 3}
    }

    {:ok, ref} = Fake.start(problem, [])

    assert {:ok, %SolveResult{status: :feasible, complete?: true, optimality: :proven} = r} =
             Fake.await(ref, 1000)

    assert [%{objective: %Decimal{}} = c] = r.payload.candidates
    assert %AshPlanning.Candidate{index: 1, data: %{"x" => 1}} = AshPlanning.Candidate.from_map(c)
  end

  test "infeasible only when proven; unknown otherwise; scripted errors" do
    {:ok, ref} = Fake.start(%Problem{model_path: "m", data: %{fake_outcome: :infeasible}}, [])
    assert {:ok, %SolveResult{status: :infeasible, complete?: true}} = Fake.await(ref, 1000)

    {:ok, ref} = Fake.start(%Problem{model_path: "m", data: %{fake_outcome: :unknown}}, [])
    assert {:ok, %SolveResult{status: :unknown, complete?: false}} = Fake.await(ref, 1000)

    assert {:error, %AshPlanning.Error{kind: :invalid_model}} =
             Fake.start(
               %Problem{model_path: "m", data: %{fake_outcome: {:error, :invalid_model}}},
               []
             )
  end

  test "cancel stops a session with outcome_reason :stopped" do
    {:ok, ref} = Fake.start(%Problem{model_path: "m", data: %{fake_candidates: [%{}]}}, [])
    assert {:ok, %{stage: :compiling}} = Fake.status(ref)
    assert :ok = Fake.cancel(ref)
    assert {:ok, %SolveResult{outcome_reason: :stopped, complete?: false}} = Fake.await(ref, 1000)
    assert {:error, :not_running} = Fake.cancel(ref)
  end

  test "solverl adapter is present iff solverl is available" do
    assert Code.ensure_loaded?(AshPlanning.Backend.Solverl) == Code.ensure_loaded?(MinizincSolver)
  end
end
