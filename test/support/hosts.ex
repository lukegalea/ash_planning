defmodule AshPlanning.Test.Domain do
  @moduledoc false
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource AshPlanning.Test.ModelVersion
    resource AshPlanning.Test.Binding
    resource AshPlanning.Test.Run
    resource AshPlanning.Test.Candidate
    resource AshPlanning.Test.CheckResult
  end
end

defmodule AshPlanning.Test.ModelVersion do
  @moduledoc false
  use Ash.Resource,
    domain: AshPlanning.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    fragments: [AshPlanning.Fragment.ModelVersion]
end

defmodule AshPlanning.Test.Binding do
  @moduledoc false
  use Ash.Resource,
    domain: AshPlanning.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    fragments: [AshPlanning.Fragment.Binding]
end

defmodule AshPlanning.Test.Run do
  @moduledoc false
  use Ash.Resource,
    domain: AshPlanning.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    fragments: [AshPlanning.Fragment.Run]
end

defmodule AshPlanning.Test.Candidate do
  @moduledoc false
  use Ash.Resource,
    domain: AshPlanning.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    fragments: [AshPlanning.Fragment.Candidate]
end

defmodule AshPlanning.Test.CheckResult do
  @moduledoc false
  use Ash.Resource,
    domain: AshPlanning.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    fragments: [AshPlanning.Fragment.CheckResult]
end
