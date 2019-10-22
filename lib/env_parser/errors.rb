class EnvParser
  ## Base error class for EnvParser.
  ##
  class Error < ::StandardError
  end

  ## Error class used to indicate a type has already been defined.
  ##
  class TypeAlreadyDefinedError < Error
  end

  ## Error class used to indicate the requested "as" type has not been defined.
  ##
  class UnknownTypeError < Error
  end

  ## Error class used to indicate value given is not convertible to the requested type.
  ##
  class ValueNotConvertibleError < Error
  end

  ## Error class used to indicate parsed values that do not pass user-validation, either by not
  ## being part of the given "from_set" list, or by failing the "validated_by" Proc or yield-block
  ## check.
  ##
  class ValueNotAllowedError < Error
  end

  ## Error class used to indicate a missing auto-registration spec file (used by the "auto-register"
  ## feature).
  ##
  class AutoRegisterFileNotFound < Error
  end

  ## Error class used to indicate an unparseable auto-registration spec (used by the "auto-register"
  ## feature).
  ##
  class UnparseableAutoRegisterSpec < Error
  end
end
