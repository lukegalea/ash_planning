import Config

# Host-owned Ash setting the fragments' string constraints need; the package's own
# test hosts set it like any host must.
config :ash,
  default_string_length_count: :codepoints,
  include_embedded_source_by_default?: false,
  known_types: []

config :ash, :validate_domain_config_inclusion?, false
