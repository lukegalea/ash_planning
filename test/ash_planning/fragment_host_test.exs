defmodule AshPlanning.FragmentHostTest do
  # Host independence: the five fragments mixed into plain Ash.Resource hosts on
  # Ash.DataLayer.Ets, no policies/tenancy/cloak/the host kernel anywhere.
  use ExUnit.Case, async: false

  alias AshPlanning.Test.{Binding, Candidate, ModelVersion, Run}

  doctest AshPlanning.Fragment.Binding

  @sha String.duplicate("a", 64)

  defp model_version(attrs \\ %{}) do
    %{
      key: "demo_week",
      version: 1,
      model_sha256: @sha,
      checker_sha256: @sha,
      validator_module: "Demo.Validator",
      validator_sha256: @sha,
      capabilities: [:no_overlap]
    }
    |> Map.merge(attrs)
  end

  test "model version lifecycle: draft -> published -> retired, immutable after publish" do
    mv =
      ModelVersion
      |> Ash.Changeset.for_create(:draft, model_version())
      |> Ash.create!(authorize?: false)

    assert mv.status == :draft

    published = mv |> Ash.Changeset.for_update(:publish, %{}) |> Ash.update!(authorize?: false)
    assert published.status == :published

    assert {:error, _} =
             published
             |> Ash.Changeset.for_update(:revise, %{model_sha256: String.duplicate("b", 64)})
             |> Ash.update(authorize?: false)

    retired =
      published |> Ash.Changeset.for_update(:retire, %{}) |> Ash.update!(authorize?: false)

    assert retired.status == :retired
  end

  test "model version identity (key, version) is declared; capability vocabulary is closed" do
    assert Enum.any?(Ash.Resource.Info.identities(ModelVersion), &(&1.keys == [:key, :version]))

    assert {:error, _} =
             ModelVersion
             |> Ash.Changeset.for_create(
               :draft,
               model_version(%{key: "bad", capabilities: [:teleport]})
             )
             |> Ash.create(authorize?: false)

    assert AshPlanning.Fragment.ModelVersion.capabilities() ==
             AshPlanning.Backend.capability_keys()
  end

  test "binding builds a canonical selector and temporal history is readable" do
    t0 = ~U[2026-01-01 00:00:00.000000Z]

    binding =
      Binding
      |> Ash.Changeset.for_create(
        :bind,
        %{
          model_key: "demo_week",
          purpose: "planning.personal_week",
          backend_profile_hash: @sha,
          selection: [
            %{"kind" => "mzn", "key" => "demo_week", "version" => "1", "content_hash" => @sha},
            %{"kind" => "dmn", "key" => "policy", "version" => "1", "content_hash" => @sha}
          ]
        },
        as_of: t0
      )
      |> Ash.create!(authorize?: false)

    assert binding.selector == ~s({"model_key":"demo_week","purpose":"planning.personal_week"})
    assert [%{"kind" => "dmn"}, %{"kind" => "mzn"}] = binding.selection

    # The public function builds the stored string, so a host reads the binding by it.
    selector = AshPlanning.Fragment.Binding.selector("demo_week", "planning.personal_week")
    assert selector == binding.selector

    assert [%{id: id}] =
             Binding
             |> Ash.Query.for_read(:read, %{}, as_of: t0)
             |> Ash.Query.filter_input(selector: selector)
             |> Ash.read!(authorize?: false)

    assert id == binding.id
  end

  test "the selector escapes its parts, and the old change module still answers" do
    alias AshPlanning.Fragment.Binding, as: Fragment

    # Quotes and backslashes cannot forge a different pair's selector.
    assert Fragment.selector(~s(a","purpose":"b), "c") ==
             ~s({"model_key":"a\\",\\"purpose\\":\\"b","purpose":"c"})

    refute Fragment.selector(~s(a","purpose":"b), "c") == Fragment.selector("a", "b")

    assert Jason.decode!(Fragment.selector("k", "p.q")) == %{
             "model_key" => "k",
             "purpose" => "p.q"
           }

    assert AshPlanning.Fragment.Binding.Changes.BuildSelector.selector("k", "p.q") ==
             Fragment.selector("k", "p.q")
  end

  test "run request guards the world/scenario pairing and candidate proposes" do
    assert {:error, _} =
             Run
             |> Ash.Changeset.for_create(:request, %{world: :scenario},
               actor: %{id: Ash.UUID.generate()}
             )
             |> Ash.create(authorize?: false)

    run =
      Run
      |> Ash.Changeset.for_create(
        :request,
        %{
          world: :operational,
          binding_id: Ash.UUID.generate(),
          model_version_id: Ash.UUID.generate()
        },
        actor: %{id: Ash.UUID.generate()}
      )
      |> Ash.create!(authorize?: false)

    assert run.preparation_status == :pending

    cand =
      Candidate
      |> Ash.Changeset.for_create(:propose, %{run_id: run.id, index: 1, assignments: "sealed"})
      |> Ash.create!(authorize?: false)

    assert cand.disposition == :proposed
    assert cand.freshness == :current
  end

  describe "candidate world" do
    defp request_run(world, extra \\ %{}) do
      Run
      |> Ash.Changeset.for_create(
        :request,
        Map.merge(
          %{world: world, binding_id: Ash.UUID.generate(), model_version_id: Ash.UUID.generate()},
          extra
        ),
        actor: %{id: Ash.UUID.generate()}
      )
      |> Ash.create!(authorize?: false)
    end

    defp propose(run, params \\ %{}) do
      Candidate
      |> Ash.Changeset.for_create(
        :propose,
        Map.merge(%{run_id: run.id, index: 0, assignments: "sealed"}, params)
      )
      |> Ash.create(authorize?: false)
    end

    defp approved(candidate) do
      candidate
      |> Ash.Changeset.for_update(:record_check, %{check_status: :correct})
      |> Ash.update!(authorize?: false)
      |> Ash.Changeset.for_update(:approve, %{}, actor: %{id: Ash.UUID.generate()})
      |> Ash.update!(authorize?: false)
    end

    defp apply_candidate(candidate) do
      candidate
      |> Ash.Changeset.for_update(:apply, %{}, actor: %{id: Ash.UUID.generate()})
      |> Ash.update(authorize?: false)
    end

    test "propose copies the run's world" do
      {:ok, operational} = propose(request_run(:operational))
      assert operational.world == :operational

      {:ok, scenario} = propose(request_run(:scenario, %{scenario_ref: "s-1"}))
      assert scenario.world == :scenario
    end

    test "world is not an input to propose" do
      run = request_run(:scenario, %{scenario_ref: "s-1"})

      assert {:error, _} = propose(run, %{world: :operational})
    end

    test "no action accepts world" do
      for action <- Ash.Resource.Info.actions(Candidate), action.type in [:create, :update] do
        refute :world in action.accept, "#{action.name} accepts world"
      end
    end

    test "propose refuses a run that is not found" do
      assert {:error, _} = propose(%{id: Ash.UUID.generate()})
    end

    test "a scenario candidate is never applied" do
      {:ok, candidate} = propose(request_run(:scenario, %{scenario_ref: "s-1"}))
      approved = approved(candidate)

      assert {:error, error} = apply_candidate(approved)
      assert Exception.message(error) =~ "scenario_world"
      assert Ash.reload!(approved, authorize?: false).disposition == :approved
    end

    test "an operational candidate is still applied" do
      {:ok, candidate} = propose(request_run(:operational))

      assert {:ok, %{disposition: :applied}} = candidate |> approved() |> apply_candidate()
    end
  end
end
