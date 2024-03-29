type Runners::Schema::Types::source_full = {
  head: String,
  head_key: String?,
  base: String?,
  base_key: String?
}

type Runners::Schema::Types::source_head_only = {
  head: String,
  head_key: String?,
}

type Runners::Schema::Types::source = source_full | source_head_only

class Runners::Schema::Types::Options < StrongJSON
  def source: -> StrongJSON::Type::Enum<source>
  def outputs: -> StrongJSON::Type::Array<String>?
  def ssh_key: -> String?
end

Runners::Schema::Options: Runners::Schema::Types::Options
