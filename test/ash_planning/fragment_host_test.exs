defmodule AshPlanning.FragmentHostTest do
  # Host independence: the five fragments mixed into plain Ash.Resource hosts on
  # Ash.DataLayer.Ets, no policies/tenancy/cloak/AshEnterprise anywhere.
  use ExUnit.Case, async: false

  alias AshPlanning.Test.{Binding, Candidate, ModelVersion, Run}

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
end
