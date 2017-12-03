require 'env_parser/version'
require 'active_support/all'

## The EnvParser class simplifies parsing of environment variables as different data types.
##
class EnvParser
  ## Exception class used to indicate parsed values not allowed per a "from_set" option.
  ##
  class ValueNotAllowed < StandardError
  end

  class << self
    ## Interprets the given value as the specified type.
    ##
    ## @param value [String, Symbol]
    ##   The value to parse/interpret. If a String is given, the value will be used as-is. If a
    ##   Symbol is given, the ENV value for the matching string key will be used.
    ##
    ## @option options as [Symbol]
    ##   The expected return type. A best-effort attempt is made to convert the source String to the
    ##   requested type. Valid "as" types are:
    ##
    ##   - `:string`
    ##   - `:symbol`
    ##   - `:boolean`
    ##   - `:int` / `:integer`
    ##   - `:float` / `:decimal` / `:number`
    ##   - `:json`
    ##   - `:array`
    ##   - `:hash`
    ##
    ##   If no "as" option is given (or the "as" value given is not on the above list), an
    ##   ArgumentError exception is raised.
    ##
    ## @option options if_unset
    ##   Specifies the default value to return if the given "value" is either unset (`nil`) or blank
    ##   (`''`). Any "if_unset" value given will be returned as-is, with no type conversion or other
    ##   change having been made.  If unspecified, the "default" value for `nil`/`''` input will
    ##   depend on the "as" type.
    ##
    ## @option options from_set [Array, Range]
    ##   Gives a limited set of allowed values (after type conversion). If, after parsing, the final
    ##   value is not included in the "from_set" list/range, an EnvParser::ValueNotAllowed exception
    ##   is raised.
    ##
    ##   Note that if the "if_unset" option is given and the value to parse is `nil`/`''`, the
    ##   "if_unset" value will be returned, even if it is not part of the "from_set" list/range.
    ##
    ##   Also note that, due to the nature of the lookup, the "from_set" option is only available
    ##   for scalar values (i.e. not arrays, hashes, or other enumerables). An attempt to use the
    ##   "from_set" option with a non-scalar value will raise an ArgumentError exception.
    ##
    ## @raise [ArgumentError, EnvParser::ValueNotAllowed]
    ##
    def parse(value, options = {})
      value = ENV[value.to_s] if value.is_a? Symbol
      value = value.to_s

      return options[:if_unset] if value.blank? && options.key?(:if_unset)

      value = case options[:as]
              when :string then parse_string(value)
              when :symbol then parse_symbol(value)
              when :boolean then parse_boolean(value)
              when :int, :integer then parse_integer(value)
              when :float, :decimal, :number then parse_float(value)
              when :json then parse_json(value)
              when :array then parse_array(value)
              when :hash then parse_hash(value)
              else raise ArgumentError, "invalid `as` parameter: #{options[:as].inspect}"
              end

      check_for_set_inclusion(value, set: options[:from_set]) if options.key?(:from_set)
      value
    end

    ## Parses the referenced value and creates a matching constant in the requested context.
    ##
    ## Multiple calls to "register" may be shortcutted by passing in a Hash with the same keys as
    ## those in the "from" Hash and each value being the "register" options set for each variable's
    ## "register" call.
    ##
    ## <pre>
    ##   ## Example shortcut usage:
    ##
    ##   EnvParser.register :A, from: one_hash, as: :integer
    ##   EnvParser.register :B, from: another_hash, as: :string, if_unset: 'none'
    ##
    ##   ## ... is equivalent to ...
    ##
    ##   EnvParser.register(
    ##     A: { from: ENV, as: :integer }
    ##     B: { from: other_hash, as: :string, if_unset: 'none' }
    ##   )
    ## </pre>
    ##
    ## @param name
    ##   The name of the value to parse/interpret from the "from" Hash. If the "from" value is ENV,
    ##   you may give a Symbol and the corresponding String key will be used instead.
    ##
    ## @option options from [Hash]
    ##   The source Hash from which to pull the value referenced by the "name" key. Defaults to ENV.
    ##
    ## @option options within [Module, Class]
    ##   The module or class in which the constant should be created. Defaults to Kernel (making it
    ##   a global constant).
    ##
    ## @option options as [Symbol]
    ##   (See `.parse`)
    ##
    ## @option options if_unset
    ##   (See `.parse`)
    ##
    ## @option options from_set [Array, Range]
    ##   (See `.parse`)
    ##
    ## @raise [ArgumentError]
    ##
    def register(name, options = {})
      ## We want to allow for registering multiple variables simultaneously via a single `.register`
      ## method call.
      return register_all(name) if name.is_a? Hash

      from = options.fetch(:from, ENV)
      within = options.fetch(:within, Kernel)

      ## ENV *seems* like a Hash and it does *some* Hash-y things, but it is NOT a Hash and that can
      ## bite you in some cases. Making sure we're working with a straight-up Hash saves a lot of
      ## sanity checks later on. This is also a good place to make sure we're working with a String
      ## key.
      if from == ENV
        from = from.to_h
        name = name.to_s
      end

      unless from.is_a?(Hash)
        raise ArgumentError, "invalid `from` parameter: #{from.class}"
      end

      unless within.is_a?(Module) || within.is_a?(Class)
        raise ArgumentError, "invalid `within` parameter: #{within.inspect}"
      end

      value = from[name]
      value = parse(value, options)
      within.const_set(name.upcase.to_sym, value.dup.freeze)

      value
    end

    private

    def parse_string(value)
      value
    end

    def parse_symbol(value)
      value.to_sym
    end

    def parse_boolean(value)
      case value
      when '', '0', 'f', 'false' then false
      else true
      end
    end

    def parse_integer(value)
      value.to_i
    end

    def parse_float(value)
      value.to_f
    end

    def parse_json(value)
      require 'json'

      return nil if value.blank?

      decoded_json = JSON.parse(value, quirks_mode: true)
      { decoded_json: decoded_json }.with_indifferent_access[:decoded_json]
    end

    def parse_array(value)
      return [] if value.blank?

      decoded_json = parse_json(value)
      raise(ArgumentError, 'non-array value') unless decoded_json.is_a? Array

      decoded_json
    end

    def parse_hash(value)
      return {} if value.blank?

      decoded_json = parse_json(value)
      raise(ArgumentError, 'non-hash value') unless decoded_json.is_a? Hash

      decoded_json
    end

    ## Verifies that the given "value" is included in the "set".
    ##
    ## @param value
    ##
    ## @param set [Array, Range]
    ##
    ## @raise [ArgumentError, EnvParser::ValueNotAllowed]
    ##
    def check_for_set_inclusion(value, set: nil)
      if value.respond_to?(:each)
        raise ArgumentError, "`from_set` option is not compatible with #{value.class} values"
      end

      unless set.is_a?(Array) || set.is_a?(Range)
        raise ArgumentError, "invalid `from_set` parameter type: #{set.class}"
      end

      raise ValueNotAllowed, 'parsed value not in allowed list/range' unless set.include?(value)
    end

    ## Receives a list of "register" calls to make, as a Hash keyed with variable names and the
    ## values being each "register" call's option set.
    ##
    ## @param list [Hash]
    ##
    ## @return [Hash]
    ##
    ## @raise [ArgumentError]
    ##
    def register_all(list)
      raise ArgumentError, "invalid 'list' parameter type: #{list.class}" unless list.is_a?(Hash)

      list.to_a.each_with_object({}) do |tuple, output|
        output[tuple.first] = register(tuple.first, tuple.second)
      end
    end
  end
end
