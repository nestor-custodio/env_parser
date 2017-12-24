require 'env_parser'

EnvParser.define_type(:string, if_unset: '') do |value|
  value
end

EnvParser.define_type(:symbol, if_unset: :'', &:to_sym)

EnvParser.define_type(:boolean, if_unset: false) do |value|
  case value
  when '', '0', 'f', 'false' then false
  else true
  end
end

EnvParser.define_type(:integer, aliases: %i[int], if_unset: 0, &:to_i)

EnvParser.define_type(:float, aliases: %i[decimal number], if_unset: 0.0, &:to_f)

EnvParser.define_type(:json, if_unset: nil) do |value|
  require 'json'

  decoded_json = JSON.parse(value, quirks_mode: true)
  { decoded_json: decoded_json }.with_indifferent_access[:decoded_json]
end

EnvParser.define_type(:array, if_unset: []) do |value|
  decoded_json = EnvParser.parse(value, as: :json)
  raise(ArgumentError, 'non-array value') unless decoded_json.is_a? Array

  decoded_json
end

EnvParser.define_type(:hash, if_unset: {}) do |value|
  decoded_json = EnvParser.parse(value, as: :json)
  raise(ArgumentError, 'non-hash value') unless decoded_json.is_a? Hash

  decoded_json
end
