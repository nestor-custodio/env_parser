require 'env_parser/version'
require 'active_support/all'

## The EnvParser class simplifies parsing of environment variables as different data types.
##
class EnvParser
  ## Base exception class for EnvParser.
  ##
  class Error < ::StandardError
  end

  ## Exception class used to indicate a type has already been defined.
  ##
  class TypeAlreadyDefined < Error
  end

  ## Exception class used to indicate the requested "as" type has not been defined.
  ##
  class UnknownType < Error
  end

  ## Exception class used to indicate value given is not convertible to the requested type.
  ##
  class ValueNotConvertible < Error
  end

  ## Exception class used to indicate parsed values that do not pass user-validation, either by not
  ## being part of the given "from_set" list, or by failing the "validated_by" Proc or yield-block
  ## check.
  ##
  class ValueNotAllowed < Error
  end

  class << self
    ## Defines a new type for use as the "as" option on a subsequent `.parse` or `.register` call.
    ##
    ## @param name [Symbol]
    ##   The name to assign to the type.
    ##
    ## @option options aliases [Array<Symbol>]
    ##   An array of additional names you'd like to see refer to this same type.
    ##
    ## @option options if_unset
    ##   Specifies a "sensible default" to return for this type if the value being parsed (via
    ##   `.parse` or `.register`) is either unset (`nil`) or blank (`''`). Note this may be
    ##   overridden by the user via the `.parse`/`.register` "if_unset" option.
    ##
    ## @yield
    ##   A block to act as the parser for the this type. If no block is given, an ArgumentError is
    ##   raised.
    ##
    ##   When the type defined is used via a `.parse`/`.register` call, this block is invoked with
    ##   the value to be parsed. Said value is guaranteed to be a non-empty String (the "if_unset"
    ##   check will have already run), but no other assurances as to content are given. The block
    ##   should return the final output of parsing the given String value as the type being defined.
    ##
    ##   If the value given cannot be sensibly parsed into the type defined, the block should raise
    ##   an EnvParser::ValueNotConvertible exception.
    ##
    ## @return [nil]
    ##   This generates no usable value.
    ##
    ## @raise [ArgumentError, EnvParser::TypeAlreadyDefined]
    ##
    def define_type(name, options = {}, &parser)
      raise(ArgumentError, 'no parsing block given') unless block_given?

      given_types = (Array(name) + Array(options[:aliases])).map(&:to_s).map(&:to_sym)
      given_types.each do |type|
        raise(TypeAlreadyDefined, "cannot redefine #{type.inspect}") if known_types.key?(type)

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
    ## @option options as [Symbol]
    ##   The expected return type. A best-effort attempt is made to convert the source String to the
    ##   requested type.
    ##
    ##   If no "as" option is given, an ArgumentError exception is raised. If the "as" option given
    ##   is unknown (the given type has not been previously defined), an EnvParser::UnknownType
    ##   exception is raised.
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
    ## @option options validated_by [Proc]
    ##   If given, the "validated_by" proc is called with the parsed value (after type conversion)
    ##   as its sole argument. This allows for user-defined validation of the parsed value beyond
    ##   what can be enforced by use of the "from_set" option alone. If the proc's return value is
    ##   `#blank?`, an EnvParser::ValueNotAllowed exception is raised. To accomodate your syntax of
    ##   choice, this validation proc may be given as a yield block instead.
    ##
    ##   Note that this option is intended to provide an inspection mechanism only -- no mutation
    ##   of the parsed value should occur within the given proc. To that end, the argument passed is
    ##   a *frozen* duplicate of the parsed value.
    ##
    ## @yield [value]
    ##   A block (if given) is treated exactly as the "validated_by" Proc would. Although there is
    ##   no compelling reason to provide both a "validated_by" proc *and* a validation block, there
    ##   is no technical limitation preventing this. **If both are given, both validation checks
    ##   must pass.**
    ##
    ## @raise [ArgumentError, EnvParser::UnknownType, EnvParser::ValueNotAllowed]
    ##
    def parse(value, options = {}, &validation_block)
      value = ENV[value.to_s] if value.is_a? Symbol
      value = value.to_s

      type = known_types[options[:as]]
      raise(ArgumentError, 'missing `as` parameter') unless options.key?(:as)
      raise(UnknownType, "invalid `as` parameter: #{options[:as].inspect}") unless type

      return (options.key?(:if_unset) ? options[:if_unset] : type[:if_unset]) if value.blank?

      value = type[:parser].call(value)
      check_for_set_inclusion(value, set: options[:from_set]) if options.key?(:from_set)
      check_user_defined_validations(value, proc: options[:validated_by], block: validation_block)

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
    ##     A: { from: one_hash, as: :integer }
    ##     B: { from: another_hash, as: :string, if_unset: 'none' }
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
    ##   See `.parse`.
    ##
    ## @option options if_unset
    ##   See `.parse`.
    ##
    ## @option options from_set [Array, Range]
    ##   See `.parse`.
    ##
    ## @option options validated_by [Proc]
    ##   See `.parse`.
    ##
    ## @yield [value]
    ##   A block (if given) is treated exactly as in `.parse`. Note, however, that a single yield
    ##   block cannot be used to register multiple constants simultaneously -- each value needing
    ##   validation must give its own "validated_by" proc.
    ##
    ## @raise [ArgumentError]
    ##
    def register(name, options = {}, &validation_block)
      ## We want to allow for registering multiple variables simultaneously via a single `.register`
      ## method call.
      if name.is_a? Hash
        raise(ArgumentError, 'cannot register multiple values with one yield block') if block_given?
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

      unless from.is_a?(Hash)
        raise ArgumentError, "invalid `from` parameter: #{from.class}"
      end

      unless within.is_a?(Module) || within.is_a?(Class)
        raise ArgumentError, "invalid `within` parameter: #{within.inspect}"
      end

      value = from[name]
      value = parse(value, options, &validation_block)
      within.const_set(name.upcase.to_sym, value.dup.freeze)

      value
    end

    ## Creates ENV bindings for EnvParser.parse and EnvParser.register proxy methods.
    ##
    ## The sole difference between these proxy methods and their EnvParser counterparts is that
    ## ENV.parse will interpret any value given as an ENV key (as a String), not the given value
    ## itself.  i.e. ENV.parse('XYZ', ...) is equivalent to EnvParser.parse(ENV['XYZ'], ...)
    ##
    ## @return [ENV]
    ##   This generates no usable value, so we may as well return ENV for chaining?
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
    ## @raise [ArgumentError, EnvParser::ValueNotAllowed]
    ##
    def check_for_set_inclusion(value, set: nil)
      if value.respond_to?(:each)
        raise ArgumentError, "`from_set` option is not compatible with #{value.class} values"
      end

      unless set.is_a?(Array) || set.is_a?(Range)
        raise ArgumentError, "invalid `from_set` parameter type: #{set.class}"
      end

      raise(ValueNotAllowed, 'parsed value not in allowed list/range') unless set.include?(value)

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
    ## @raise [EnvParser::ValueNotAllowed]
    ##
    def check_user_defined_validations(value, proc: nil, block: nil)
      immutable_value = value.dup.freeze
      error = 'parsed value failed user validation'
      raise(ValueNotAllowed, error) unless [proc, block].compact.all? { |i| i.call(immutable_value) }

      nil
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
      raise(ArgumentError, "invalid 'list' parameter type: #{list.class}") unless list.is_a?(Hash)

      list.to_a.each_with_object({}) do |tuple, output|
        output[tuple.first] = register(tuple.first, tuple.second)
      end
    end
  end
end

## Load predefined types.
##
require 'env_parser/types'
