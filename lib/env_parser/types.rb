# Load all files listed in "/lib/env_parser/types".
#
Dir.glob(File.join(__dir__, 'types', '*.rb')).each { |filename| require_relative filename }
