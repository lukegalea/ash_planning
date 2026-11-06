defmodule Mix.Tasks.Planning.Boundary do
  @shortdoc "Asserts ash_planning stays host-independent and its fixtures synthetic"

  @moduledoc """
  Fails when:

    1. the dependency tree contains `phoenix*`, `ash_phoenix*`, `ash_enterprise*` or `oban*`;
    2. any compiled package module references a banned host module (`AshEnterprise`,
       `Phoenix`, `AshPhoenix`, `Oban`) — checked against the atoms and remote imports
       of every `.beam` in the package's build (the same edges `mix xref` reports);
    3. a file under `test/` or `priv/` matches a regex from `priv/boundary_markers.txt`
       (non-synthetic fixture markers).
  """

  use Mix.Task

  @banned_deps ~r/^(phoenix|ash_phoenix|ash_enterprise|oban)/
  @banned_modules ~r/^Elixir\.(AshEnterprise|Phoenix|AshPhoenix|Oban)(\.|$)/
  @markers_file "priv/boundary_markers.txt"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")

    problems = dep_problems() ++ module_problems() ++ fixture_problems()

    case problems do
      [] ->
        Mix.shell().info("planning.boundary: ok (deps, modules, fixtures)")

      _ ->
        shell = Mix.shell()
        Enum.each(problems, &shell.error/1)
        Mix.raise("planning.boundary: #{length(problems)} violation(s)")
    end
  end

  defp dep_problems do
    Mix.Project.deps_paths()
    |> Map.keys()
    |> Enum.map(&Atom.to_string/1)
    |> Enum.filter(&Regex.match?(@banned_deps, &1))
    |> Enum.map(&"banned dependency in tree: #{&1}")
  end

  defp module_problems do
    ebin = Path.join(Mix.Project.app_path(), "ebin")

    for beam <- Path.wildcard(Path.join(ebin, "*.beam")),
        {:ok, {mod, [atoms: atoms]}} <- [:beam_lib.chunks(String.to_charlist(beam), [:atoms])],
        {_, atom} <- atoms,
        Regex.match?(@banned_modules, Atom.to_string(atom)) do
      "#{inspect(mod)} references banned host module #{inspect(atom)}"
    end
    |> Enum.uniq()
  end

  defp fixture_problems do
    patterns =
      @markers_file
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.map(&Regex.compile!(&1, "i"))

    for dir <- ["test", "priv"],
        file <- Path.wildcard(Path.join(dir, "**/*"), match_dot: true),
        File.regular?(file),
        file != @markers_file,
        {line, n} <- file |> File.read!() |> String.split("\n") |> Enum.with_index(1),
        re <- patterns,
        Regex.match?(re, line) do
      "#{file}:#{n} matches non-synthetic marker #{inspect(Regex.source(re))}"
    end
  end
end
