require 'env_parser/errors'
require 'env_parser/version'
require 'active_support/all'
require 'psych'

## The EnvParser class simplifies parsing of environment variables as different data types.
##
class EnvParser
  class << self
    ## Defines a new type for use as the "as" option on a subsequent {.parse} or {.register} call.
    ##
    ## @param name [Symbol]
    ##   The name to assign to the type.
    ##
    ## @option options [Array<Symbol>] aliases
    ##   An array of additional names you'd like to see refer to this same type.
    ##
    ## @option options if_unset (nil)
    ##   Specifies a "sensible default" to return for this type if the value being parsed (via
    ##   {.parse} or {.register}) is either unset (`nil`) or blank (`''`). Note this may be
    ##   overridden by the user via the {.parse}/{.register} "if_unset" option.
    ##
    ## @yield [value]
    ##   A block to act as the parser for the this type. If no block is given, an ArgumentError is
    ##   raised.
    ##
    ##   When the type defined is used via a {.parse}/{.register} call, this block is invoked with
    ##   the value to be parsed. Said value is guaranteed to be a non-empty String (the "if_unset"
    ##   check will have already run), but no other assurances as to content are given. The block
    ##   should return the final output of parsing the given String value as the type being defined.
    ##
    ##   If the value given cannot be sensibly parsed into the type defined, the block should raise
    ##   an {EnvParser::ValueNotConvertibleError}.
    ##
    ## @return [nil]
    ##   This generates no usable value.
    ##
    ## @raise [ArgumentError, EnvParser::TypeAlreadyDefinedError]
    ##
    def define_type(name, options = {}, &parser)
      raise(ArgumentError, 'no parsing block given') unless block_given?

      given_types = (Array(name) + Array(options[:aliases])).map(&:to_s).map(&:to_sym)
      given_types.each do |type|
        raise(TypeAlreadyDefinedError, "cannot redefine #{type.inspect}") if known_types.key?(type)

        known_types[type] = {
          parser: parser,
          if_unset: options[:if_unset]
        }
      end

      nil
    end

    ## Interprets the given value as the specified type.
    ##
    ## @param value [String, Symbol]
    ##   The value to parse/interpret. If a String is given, the value will be used as-is. If a
    ##   Symbol is given, the ENV value for the matching string key will be used.
    ##
    ## @option options [Symbol] as
    ##   The expected return type. A best-effort attempt is made to convert the source String to the
    ##   requested type.
    ##
    ##   If no "as" option is given, an ArgumentError is raised. If the "as" option given is unknown
    ##   (the given type has not been previously defined via {.define_type}), an
    ##   {EnvParser::UnknownTypeError} is raised.
    ##
    ## @option options if_unset
    ##   Specifies the default value to return if the given "value" is either unset (`nil`) or blank
    ##   (`''`). Any "if_unset" value given will be returned as-is, with no type conversion or other
    ##   change having been made.  If unspecified, the "default" value for `nil`/`''` input will
    ##   depend on the "as" type.
    ##
    ## @option options [Array, Range] from_set
    ##   Gives a limited set of allowed values (after type conversion). If, after parsing, the final
    ##   value is not included in the "from_set" list/range, an {EnvParser::ValueNotAllowedError} is
    ##   raised.
    ##
    ##   Note that if the "if_unset" option is given and the value to parse is `nil`/`''`, the
    ##   "if_unset" value will be returned, even if it is not part of the "from_set" list/range.
    ##
    ##   Also note that, due to the nature of the lookup, the "from_set" option is only available
    ##   for scalar values (i.e. not arrays, hashes, or other enumerables). An attempt to use the
    ##   "from_set" option with a non-scalar value will raise an ArgumentError.
    ##
    ## @option options [Proc] validated_by
    ##   If given, the "validated_by" Proc is called with the parsed value (after type conversion)
    ##   as its sole argument. This allows for user-defined validation of the parsed value beyond
    ##   what can be enforced by use of the "from_set" option alone. If the Proc's return value is
    ##   `#blank?`, an {EnvParser::ValueNotAllowedError} is raised. To accomodate your syntax of
    ##   choice, this validation Proc may be given as a block instead.
    ##
    ##   Note that this option is intended to provide an inspection mechanism only -- no mutation
    ##   of the parsed value should occur within the given Proc. To that end, the argument passed is
    ##   a *frozen* duplicate of the parsed value.
    ##
    ## @yield [value]
    ##   A block (if given) is treated exactly as the "validated_by" Proc would.
    ##
    ##   Although there is no compelling reason to provide both a "validated_by" Proc *and* a
    ##   validation block, there is no technical limitation preventing this. **If both are given,
    ##   both validation checks must pass.**
    ##
    ## @raise [ArgumentError, EnvParser::UnknownTypeError, EnvParser::ValueNotAllowedError]
    ##
    def parse(value, options = {}, &validation_block)
      value = ENV[value.to_s] if value.is_a? Symbol
      value = value.to_s

      type = known_types[options[:as]]
      raise(ArgumentError, 'missing `as` parameter') unless options.key?(:as)
      raise(UnknownTypeError, "invalid `as` parameter: #{options[:as].inspect}") unless type

      return (options.key?(:if_unset) ? options[:if_unset] : type[:if_unset]) if value.blank?

      value = type[:parser].call(value)
      check_for_set_inclusion(value, set: options[:from_set]) if options.key?(:from_set)
      check_user_defined_validations(value, proc: options[:validated_by], block: validation_block)

      value
    end

    ## Parses the referenced value and creates a matching constant in the requested context.
    ##
    ## Multiple calls to {.register} may be shortcutted by passing in a Hash whose keys are the
    ## variable names and whose values are the options set for each variable's {.register} call.
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
    ##     A: { from: one_hash, as: :integer }
    ##     B: { from: another_hash, as: :string, if_unset: 'none' }
    ##   )
    ## </pre>
    ##
    ## @param name
    ##   The name of the value to parse/interpret from the "from" Hash. If the "from" value is
    ##   `ENV`, you may give a Symbol and the corresponding String key will be used instead.
    ##
    ## @option options [Hash] from (ENV)
    ##   The source Hash from which to pull the value referenced by the "name" key.
    ##
    ## @option options [Module, Class] within (Kernel)
    ##   The module or class in which the constant should be created. Creates global constants by
    ##   default.
    ##
    ## @option options [Symbol] as
    ##   See {.parse}.
    ##
    ## @option options if_unset
    ##   See {.parse}.
    ##
    ## @option options [Array, Range] from_set
    ##   See {.parse}.
    ##
    ## @option options [Proc] validated_by
    ##   See {.parse}.
    ##
    ## @yield [value]
    ##   A block (if given) is treated exactly as in {.parse}. Note, however, that a single block
    ##   cannot be used to register multiple constants simultaneously -- each value needing
    ##   validation must give its own "validated_by" Proc.
    ##
    ## @raise [ArgumentError]
    ##
    def register(name, options = {}, &validation_block)
      ## Allow for registering multiple variables simultaneously via a single call.
      if name.is_a? Hash
        raise(ArgumentError, 'cannot register multiple values with one block') if block_given?
        return register_all(name)
      end

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

      raise ArgumentError, "invalid `from` parameter: #{from.class}" unless from.is_a? Hash

      unless within.is_a?(Module) || within.is_a?(Class)
        raise ArgumentError, "invalid `within` parameter: #{within.inspect}"
      end

      value = from[name]
      value = parse(value, options, &validation_block)
      within.const_set(name.upcase.to_sym, value.dup.freeze)

      value
    end

    ## Creates ENV bindings for {.parse} and {.register} proxy methods.
    ##
    ## The sole difference between these proxy methods and their EnvParser counterparts is that
    ## ENV.parse will interpret any value given as an ENV key (as a String), not the given value
    ## itself.  i.e. ENV.parse('XYZ', ...) is equivalent to EnvParser.parse(ENV['XYZ'], ...)
    ##
    ## @return [ENV]
    ##   This generates no usable value.
    ##
    def add_env_bindings
      ENV.instance_eval do
        def parse(name, options = {}, &validation_block)
          EnvParser.parse(self[name.to_s], options, &validation_block)
        end

        def register(*args)
          EnvParser.register(*args)
        end
      end

      ENV
    end

    def autoregister
      EnvParser::AUTOREGISTER_FILE = '.env_parser.yml'.freeze

      autoregister_spec = Psych.load_file(EnvParser::AUTOREGISTER_FILE)

      autoregister_spec.deep_symbolize_keys!
      autoregister_spec.transform_values! do |spec|
        spec.slice(:as, :if_unset, :from_set).merge as: spec[:as]&.to_sym
      end

      register_all autoregister_spec

    ## Psych raises an Errno::ENOENT on file-not-found.
    ##
    rescue Errno::ENOENT
      raise EnvParser::AutoregisterFileNotFound, %(file not found: "#{EnvParser::AUTOREGISTER_FILE}")

    ## Psych raises a Psych::SyntaxError on unparseable YAML.
    ##
    rescue Psych::SyntaxError => e
      raise EnvParser::UnparseableAutoregisterSpec, "malformed YAML in spec file: #{e.message}"
    end

    private

    ## Class instance variable for storing known type data.
    ##
    def known_types
      @known_types ||= {}
    end

    ## Verifies that the given "value" is included in the "set".
    ##
    ## @param value
    ## @param set [Array, Range]
    ##
    ## @return [nil]
    ##   This generates no usable value.
    ##
    ## @raise [ArgumentError, EnvParser::ValueNotAllowedError]
    ##
    def check_for_set_inclusion(value, set: nil)
      if value.respond_to?(:each)
        raise ArgumentError, "`from_set` option is not compatible with #{value.class} values"
      end

      unless set.is_a?(Array) || set.is_a?(Range)
        raise ArgumentError, "invalid `from_set` parameter type: #{set.class}"
      end

      raise(ValueNotAllowedError, 'parsed value not in allowed set') unless set.include?(value)

      nil
    end

    ## Verifies that the given "value" passes both the "proc" and "block" validations.
    ##
    ## @param value
    ## @param proc [Proc, nil]
    ## @param block [Proc, nil]
    ##
    ## @return [nil]
    ##   This generates no usable value.
    ##
    ## @raise [EnvParser::ValueNotAllowedError]
    ##
    def check_user_defined_validations(value, proc: nil, block: nil)
      immutable_value = value.dup.freeze
      all_tests_passed = [proc, block].compact.all? { |i| i.call(immutable_value) }
      raise(ValueNotAllowedError, 'parsed value failed user validation') unless all_tests_passed

      nil
    end

    ## Receives a list of {.register} calls to make, as a Hash keyed with variable names and the
    ## values being each {.register} call's option set.
    ##
    ## @param list [Hash]
    ##
    ## @return [Hash]
    ##
    ## @raise [ArgumentError]
    ##
    def register_all(list)
      raise(ArgumentError, "invalid 'list' parameter type: #{list.class}") unless list.is_a? Hash

      list.to_a.each_with_object({}) do |tuple, output|
        output[tuple.first] = register(tuple.first, tuple.second)
      end
    end
  end
end

## Load predefined types.
##
require 'env_parser/types'
