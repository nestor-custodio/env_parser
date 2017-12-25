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
end
