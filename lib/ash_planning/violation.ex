defmodule AshPlanning.Violation do
  @moduledoc """
  The `AshPlanning.Validator` error shape: a plain map `%{code, subject, detail}`.

  `code` is a snake_case atom, `subject` identifies what is violated (an id or a list of
  ids), `detail` is a map of structural values only.
  """

  @type t :: %{code: atom(), subject: term(), detail: map()}

  @doc "Builds a violation map."
  @spec new(atom(), term(), map()) :: t()
  def new(code, subject, detail \\ %{}) when is_atom(code) and is_map(detail),
    do: %{code: code, subject: subject, detail: detail}
end
