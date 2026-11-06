defmodule AshPlanning.GoldenDigestTest do
  # The Wave-1 cross-host golden fixture, rebuilt from the envelope in
  # ash_open_lineage's snapshot_canonical_json_test (synthetic values). Every host that
  # consumes the snapshot contract must reproduce this digest.
  use ExUnit.Case, async: true

  alias AshOpenLineage.Snapshot

  @golden_digest "2be6f74cd9c618c1c0d0513b1acada801eda16113e21e6f33b86d542b73c036d"

  def golden_snapshot do
    {:ok, eff, _} = DateTime.from_iso8601("2026-11-05T08:30:00.123456Z")
    {:ok, cut, _} = DateTime.from_iso8601("2026-11-04T22:00:00.000000Z")

    %Snapshot{
      id: "019a2c7e-4b1d-7c2e-9f3a-5d6e7f8a9b0c",
      purpose: :"planning.personal_week",
      effective_at: eff,
      knowledge_cutoff: cut,
      world: :operational,
      authority: %{tenant: "t-demo-01", actor_id: "usr-042", completeness: :full},
      inputs: [
        %Snapshot.Input{
          key: "task.alpha",
          role: :demand,
          status: :value,
          source: %{resource: "Task", id: "task-1", version_number: 7},
          content_hash: "aa11"
        },
        %Snapshot.Input{
          key: "policy.hours",
          role: :parameter,
          status: :value,
          source: %{resource: "Policy", id: "pol-9", version_number: 2},
          content_hash: "bb22"
        },
        %Snapshot.Input{
          key: "policy.hours",
          role: :constraint,
          status: :unresolved,
          source: nil,
          content_hash: nil
        }
      ],
      definitions: [
        %Snapshot.Definition{
          kind: :dmn,
          key: "canonical.planning_requirements",
          version: "1.0.0",
          content_hash: "cc33"
        },
        %Snapshot.Definition{kind: :mzn, key: "personal_week", version: "3", content_hash: "dd44"}
      ],
      payload_hash: "ee55"
    }
  end

  test "golden digest reproduces through AshPlanning.Snapshot" do
    sealed = AshPlanning.Snapshot.seal(golden_snapshot())
    assert AshPlanning.Snapshot.digest(sealed) == @golden_digest
    assert AshPlanning.Snapshot.verify(sealed)
  end

  test "tampering breaks verification" do
    sealed = AshPlanning.Snapshot.seal(golden_snapshot())
    refute AshPlanning.Snapshot.verify(%{sealed | payload_hash: "ff66"})
    refute AshPlanning.Snapshot.verify(golden_snapshot())
  end

  test "consumption accessors" do
    snap = golden_snapshot()
    assert [%{key: "personal_week"}] = AshPlanning.Snapshot.definitions(snap, :mzn)

    assert %{content_hash: "cc33"} =
             AshPlanning.Snapshot.definition(snap, :dmn, "canonical.planning_requirements")

    assert length(AshPlanning.Snapshot.inputs(snap, role: :demand)) == 1
    assert [%{status: :unresolved}] = AshPlanning.Snapshot.unresolved_inputs(snap)
    refute AshPlanning.Snapshot.complete?(snap)
    assert [%{id: "task-1"}, %{id: "pol-9"}] = AshPlanning.Snapshot.sources(snap)
  end
end
