defmodule AshPlanning.Snapshot do
  @moduledoc """
  Consumption helpers over `AshOpenLineage.Snapshot`, used by snapshot builders and
  check pipelines. The snapshot carries references and hashes only; these helpers read
  and verify, they never fetch resource payloads.
  """

  alias AshOpenLineage.Snapshot
  alias AshOpenLineage.Snapshot.{Definition, Input}

  @doc "Returns the snapshot with its digest computed."
  @spec seal(Snapshot.t()) :: Snapshot.t()
  def seal(%Snapshot{} = snapshot), do: Snapshot.put_digest(snapshot)

  @doc "The stored digest (nil if unsealed)."
  @spec digest(Snapshot.t()) :: String.t() | nil
  def digest(%Snapshot{digest: digest}), do: digest

  @doc "True when the stored digest equals the recomputed one."
  @spec verify(Snapshot.t()) :: boolean()
  def verify(%Snapshot{digest: digest} = snapshot) when is_binary(digest),
    do: Snapshot.put_digest(snapshot).digest == digest

  def verify(%Snapshot{}), do: false

  @doc "All pinned definitions, optionally of one `kind`."
  @spec definitions(Snapshot.t(), atom() | nil) :: [Definition.t()]
  def definitions(%Snapshot{definitions: defs}, kind \\ nil) do
    Enum.filter(defs || [], &(is_nil(kind) or &1.kind == kind))
  end

  @doc "The pinned definition for `(kind, key)`, or nil."
  @spec definition(Snapshot.t(), atom(), String.t()) :: Definition.t() | nil
  def definition(%Snapshot{} = snapshot, kind, key),
    do: Enum.find(definitions(snapshot, kind), &(&1.key == key))

  @doc "All inputs, optionally filtered by `:role` and/or `:status`."
  @spec inputs(Snapshot.t(), keyword()) :: [Input.t()]
  def inputs(%Snapshot{inputs: inputs}, filters \\ []) do
    role = Keyword.get(filters, :role)
    status = Keyword.get(filters, :status)

    Enum.filter(inputs || [], fn i ->
      (is_nil(role) or i.role == role) and (is_nil(status) or i.status == status)
    end)
  end

  @doc "Inputs that are not `:value` — what a builder surfaces as needing input."
  @spec unresolved_inputs(Snapshot.t()) :: [Input.t()]
  def unresolved_inputs(%Snapshot{inputs: inputs}),
    do: Enum.reject(inputs || [], &(&1.status == :value))

  @doc "True when every input is a resolved `:value`."
  @spec complete?(Snapshot.t()) :: boolean()
  def complete?(%Snapshot{} = snapshot), do: unresolved_inputs(snapshot) == []

  @doc "`{resource, id, version_number}` source references of resolved inputs (apply-time drift check)."
  @spec sources(Snapshot.t()) :: [map()]
  def sources(%Snapshot{inputs: inputs}),
    do: for(%Input{source: %{} = s} <- inputs || [], do: s)
end
