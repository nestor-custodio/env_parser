require 'env_parser'
require 'psych'

EnvParser::AUTOREGISTER_FILE = '.env_parser.yml'.freeze

begin
  autoregister_spec = Psych.load_file(EnvParser::AUTOREGISTER_FILE)

  autoregister_spec.deep_symbolize_keys!
  autoregister_spec.transform_values! do |spec|
    spec.slice(:as, :if_unset, :from_set).merge as: spec[:as]&.to_sym
  end

  EnvParser.register autoregister_spec

## Psych raises an Errno::ENOENT on file-not-found.
##
rescue Errno::ENOENT
  raise EnvParser::AutoRegisterFileNotFound, %(file not found: "#{EnvParser::AUTOREGISTER_FILE}")

## Psych raises a Psych::SyntaxError on unparseable YAML.
##
rescue Psych::SyntaxError => e
  raise EnvParser::UnparseableAutoRegisterSpec, "malformed YAML in spec file: #{e.message}"
end
