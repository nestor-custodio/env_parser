[![Gem Version](https://img.shields.io/github/v/release/nestor-custodio/env_parser?color=green&label=gem%20version)](https://rubygems.org/gems/env_parser)
[![MIT License](https://img.shields.io/github/license/nestor-custodio/env_parser)](https://github.com/nestor-custodio/env_parser/blob/main/LICENSE.txt)


# EnvParser

If your code uses environment variables, you know that `ENV` will always surface these as strings. Interpreting these strings as the value you *actually* want to see/use takes some work, however: for numbers you need to cast with `to_i` or `to_f` ... for booleans you need to check for a specific value (`ENV['SOME_VAR'] == 'true'`) ... maybe you want to set non-trivial defaults (something other than `0` or `''`)? ... maybe you only want to allow values from a limited set? ...

Things can get out of control pretty fast, especially as the number of environment variables in play grows. Tools like [dotenv](https://github.com/bkeepers/dotenv) help to make sure you're loading the correct **set** of variables, but [EnvParser](https://github.com/nestor-custodio/env_parser) makes **the values themselves** usable with a minimum of effort.

[Full documentation is available here](http://nestor-custodio.github.io/env_parser/EnvParser.html), but do read below for a crash course on availble featues!


## Installation

- If your project uses [Bundler](https://github.com/bundler/bundler):
  - Add one of the following to your application's Gemfile:
    ```ruby
    # For on-demand usage ...
    #
    gem 'env_parser'

    # To automatically register ENV
    # constants per ".env_parser.yml" ...
    #
    gem 'env_parser', require: 'env_parser/autoregister'
    ```
  - And then run a:
    ```shell
    $ bundle install
    ```

- Or, you can keep things simple with a manual install:
  ```shell
  $ gem install env_parser
  ```


## Syntax Cheat Sheet

```ruby
# Returns an ENV value parsed "as" a specific type:
#
EnvParser.parse env_key_as_a_symbol
                as: …                          # ➜ required
                if_unset: …                    # ➜ optional; default value
                from_set: …                    # ➜ optional; an Array or Range
                validated_by: ->(value) { … }  # ➜ optional; may also be given as a block

# Parse an ENV value and register it as a constant:
#
EnvParser.register env_key_as_a_symbol
                   as: …                          # ➜ required
                   within: …                      # ➜ optional; Class or Module
                   if_unset: …                    # ➜ optional; default value
                   from_set: …                    # ➜ optional; an Array or Range
                   validated_by: ->(value) { … }  # ➜ optional; may also be given as a block

# Registers all ENV variables as spec'ed in ".env_parser.yml":
#
EnvParser.autoregister  # Note this is automatically called if your
                        # Gemfile included the "env_parser" gem with
                        # the "require: 'env_parser/autoregister'" option.

# Lets you call "parse" and "register" on ENV itself:
#
EnvParser.add_env_bindings  # ENV.parse will now be a proxy for EnvParser.parse
                            # and ENV.register will now be a proxy for EnvParser.register
```


## Extended How-To-Use

#### Basic Usage

- **Parsing `ENV` Values**

  At its core, EnvParser is a straight-forward parser for string values (since that's all `ENV` ever gives you), allowing you to read a given string **_as_** a variety of types.

  ```ruby
  # Returns ENV['TIMEOUT_MS'] as an Integer,
  # or a sensible default (0) if ENV['TIMEOUT_MS'] is unset.
  #
  timeout_ms = EnvParser.parse ENV['TIMEOUT_MS'], as: :integer
  ```

  You can check the full documentation for [a list of all **_as_** types available right out of the box](http://nestor-custodio.github.io/env_parser/EnvParser/Types.html).

- **How About Less Typing?**

  EnvParser is all about ~~simplification~~ ~~less typing~~ *laziness*. If you pass in a symbol instead of a string, EnvParser will look to `ENV` and use the value from the corresponding (string) key.

  ```ruby
  # YAY, LESS TYPING!  😃
  # These two are the same:
  #
  more_typing = EnvParser.parse ENV['TIMEOUT_MS'], as: :integer
  less_typing = EnvParser.parse :TIMEOUT_MS, as: :integer
  ```

- **Registering Constants From `ENV` Values**

  The `EnvParser.register` method lets you "promote" `ENV` variables into their own constants, already parsed into the correct type.

  ```ruby
  ENV['API_KEY']  # => 'unbreakable p4$$w0rd'

  EnvParser.register :API_KEY, as: :string
  API_KEY  # => 'unbreakable p4$$w0rd'
  ```

  By default, `EnvParser.register` will create the requested constant within the Kernel module (making it available everywhere), but you can specify any class or module you like.

  ```ruby
  ENV['BEST_VIDEO']  # => 'https://youtu.be/L_jWHffIx5E'

  EnvParser.register :BEST_VIDEO, as: :string, within: URI
  URI::BEST_VIDEO  # => 'https://youtu.be/L_jWHffIx5E'
  BEST_VIDEO  # => raises NameError
  ```

  You can also register multiple constants with a single call, which is a bit cleaner.

  ```ruby
  EnvParser.register :USERNAME, as: :string
  EnvParser.register :PASSWORD, as: :string
  EnvParser.register :MOCK_API, as: :boolean, within: MyClassOrModule }

  # ... is equivalent to ... #

  EnvParser.register USERNAME: { as: :string                           },
                     PASSWORD: { as: :string                           },
                     MOCK_API: { as: :boolean, within: MyClassOrModule }
  ```

- **Okay, But... How About Even Less Typing?**

  Calling `EnvParser.add_env_bindings` binds proxy `parse` and `register` methods onto `ENV`. With these bindings in place, you can call `parse` or `register` on `ENV` itself, which is more legible and feels more straight-forward.

  ```ruby
  ENV['SHORT_PI']  # => '3.1415926'
  ENV['BETTER_PI']  # => '["flaky crust", "strawberry filling"]'

  # Bind the proxy methods.
  #
  EnvParser.add_env_bindings

  ENV.parse :SHORT_PI, as: :float  # => 3.1415926
  ENV.register :BETTER_PI, as: :array  # Your constant is set!
  ```

  Note that the proxy `ENV.parse` method will (naturally) *always* interpret the value given as an `ENV` key (converting it to a string, if necessary), which is slightly different from the original `EnvParser.parse` method.

  ```ruby
  ENV['SHORT_PI']  # => '3.1415926'

  EnvParser.parse 'SHORT_PI', as: :float  # => 'SHORT_PI' as a float: 0.0
  EnvParser.parse :SHORT_PI , as: :float  # => ENV['SHORT_PI'] as a float: 3.1415926

  # Bind the proxy methods.
  #
  EnvParser.add_env_bindings

  ENV.parse 'SHORT_PI', as: :float  # => ENV['SHORT_PI'] as a float: 3.1415926
  ENV.parse :SHORT_PI , as: :float  # => ENV['SHORT_PI'] as a float: 3.1415926
  ```

  Note also that the `ENV.parse` and `ENV.register` binding is done safely and without polluting the method space for other objects.

  **All additional examples below will assume that `ENV` bindings are already in place, for brevity's sake.**


#### Ensuring Usable Values

- **Sensible Defaults**

  If the `ENV` variable you want is unset (`nil`) or blank (`''`), the return value is a sensible default for the given **_as_** type: 0 or 0.0 for numbers, an empty string/array/hash, etc. Sometimes you want a non-trivial default, however. The **_if_unset_** option lets you specify a default that better meets your needs.

  ```ruby
  ENV.parse :MISSING_VAR, as: :integer  # => 0
  ENV.parse :MISSING_VAR, as: :integer, if_unset: 250  # => 250
  ```

  Note these default values are used as-is with no type conversion, so exercise caution.

  ```ruby
  ENV.parse :MISSING_VAR, as: :integer, if_unset: 'Careful!'  # => 'Careful!' (NOT AN INTEGER)
  ```

- **Selecting From A Set**

  Sometimes setting the **_as_** type is a bit too open-ended. The **_from_set_** option lets you restrict the domain of allowed values.

  ```ruby
  ENV.parse :API_TO_USE, as: :symbol, from_set: %i[internal external]
  ENV.parse :NETWORK_PORT, as: :integer, from_set: (1..65535), if_unset: 80

  # And if the value is not in the allowed set ...
  #
  ENV.parse :TWELVE, as: :integer, from_set: (1..5)  # => raises EnvParser::ValueNotAllowedError
  ```

- **Custom Validation Of Parsed Values**

  You can write your own, more complex validations by passing in a **_validated_by_** lambda or an equivalent block. The lambda/block should take one value and return true if the given value passes the custom validation.

  ```ruby
  # Via a "validated_by" lambda ...
  #
  ENV.parse :MUST_BE_LOWERCASE, as: :string, validated_by: ->(value) { value == value.downcase }

  # ... or with a block!
  #
  ENV.parse(:MUST_BE_LOWERCASE, as: :string) { |value| value == value.downcase }
  ENV.parse(:CONNECTION_RETRIES, as: :integer, &:positive?)
  ```

- **Defining Your Own EnvParser "*as*" Types**

  If you use a particular validation many times or are often manipulating values in the same way after EnvParser has done its thing, you may want to register a new type altogether. Defining a new type makes your code both more maintainable (all the logic for your special type is only defined once) and more readable (your `parse` calls aren't littered with type-checking cruft).

  Something as repetitive as:

  ```ruby
  a = ENV.parse :A, as: :int, if_unset: 6
  raise unless passes_all_my_checks?(a)

  b = ENV.parse :B, as: :int, if_unset: 6
  raise unless passes_all_my_checks?(b)
  ```

  ... is perhaps best handled by defining a new type:

  ```ruby
  EnvParser.define_type(:my_special_type_of_number, if_unset: 6) do |value|
    value = value.to_i
    unless passes_all_my_checks?(value)
      raise(EnvParser::ValueNotConvertibleError, 'cannot parse as a "special type number"')
    end

    value
  end

  a = ENV.parse :A, as: :my_special_type_of_number
  b = ENV.parse :B, as: :my_special_type_of_number
  ```


#### Auto-Registering Constants

- **The `autoregister` Call**

  Consolidating all of your `EnvParser.register` calls into a single place only makes sense. A single `EnvParser.autoregister` call take a filename to read and process as a series of constant registration requests. If no filename is given, the default `".env_parser.yml"` is assumed.

  You'll normally want to call `EnvParser.autoregister` as early in your application as possible. For Rails applications (and other frameworks that call `require 'bundler/setup'`), requiring the EnvParser gem via ...

  ```ruby
  gem 'env_parser', require: 'env_parser/autoregister'
  ```

  ... will automatically make the autoregistration call for you as soon as the gem is loaded (which should be early enough for most uses). If this is *still* not early enough for your needs, you can always `require 'env_parser/autoregister'` yourself even before `bundler/setup` is invoked.

- **The ".env_parser.yml" File**

  If you recall, multiple constants can be registered via a single `EnvParser.register` call:

  ```ruby
  EnvParser.register :USERNAME, as: :string
  EnvParser.register :PASSWORD, as: :string
  EnvParser.register :MOCK_API, as: :boolean, within: MyClassOrModule }

  # ... is equivalent to ... #

  EnvParser.register USERNAME: { as: :string                           },
                     PASSWORD: { as: :string                           },
                     MOCK_API: { as: :boolean, within: MyClassOrModule }
  ```

  The autoregistraton file is intended to read as a YAML version of what you'd pass to the single-call version of `EnvParser.register`: a single hash with keys for each of the constants you'd like to register, with each value being the set of options to parse that constant.

  The equivalent autoregistration file for the above would be:

  ```yaml
  USERNAME:
    as: :string

  PASSWORD:
    as: :string

  MOCK_API:
    as: :boolean
    within: MyClassOrModule
  ```

  Because no Ruby *statements* can be safely represented via YAML, the set of `EnvParser.register` options available via autoregistration is limited to **_as_**, **_within_**, **_if_unset_**, and **_from_set_**. As an additional restriction, **_from_set_** (if given) must be an array, as ranges cannot be represented in YAML.


## Feature Roadmap / Future Development

Additional features coming in the future:

- Continue to round out the **_as_** type selection as ideas come to mind, suggestions are made, and pull requests are submitted.


## Contribution / Development

Bug reports and pull requests are welcome at: [https://github.com/nestor-custodio/env_parser](https://github.com/nestor-custodio/env_parser)

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Linting is courtesy of [Rubocop](https://docs.rubocop.org/) (`bundle exec rubocop`) and documentation is built using [Yard](https://yardoc.org/) (`bundle exec yard`). Please ensure you have a clean bill of health from Rubocop and that any new features and/or changes to behaviour are reflected in the documentation before submitting a pull request.


## License

EnvParser is available as open source under the terms of the [MIT License](https://tldrlegal.com/license/mit-license).
