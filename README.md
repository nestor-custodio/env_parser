# EnvParser  [![Gem Version](https://badge.fury.io/rb/env_parser.svg)](https://badge.fury.io/rb/env_parser)

If your code uses environment variables, you know that `ENV` will always surface these as strings. Interpreting these strings as the value you *actually* want to see/use takes some work, however: for numbers you need to cast with `to_i` or `to_f` ... for booleans you need to check for a specific value (`ENV['SOME_VAR'] == 'true'`) ... maybe you want to set non-trivial defaults (something other than `0` or `''`)? ... maybe you only want to allow values from a limited set? ...

Things can get out of control pretty fast, especially as the number of environment variables in play grows. Tools like [dotenv](https://github.com/bkeepers/dotenv) help to make sure you're loading the correct **set** of variables, but [EnvParser](https://github.com/nestor-custodio/env_parser) makes ***the values themselves*** usable with a minimum of effort.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'env_parser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install env_parser


## Using EnvParser

### Basic Usage

#### Parsing ENV Values

```ruby
## Returns ENV['TIMEOUT_MS'] as an Integer,
## or 0 if ENV['TIMEOUT_MS'] is unset or nil.

timeout_ms = EnvParser.parse ENV['TIMEOUT_MS'], as: :integer


## LESS TYPING, PLZ!  :(
## If you pass in a Symbol instead of a String, EnvParser
## will use the value behind the matching String key in ENV.
## (i.e. passing in ENV['X'] is equivalent to passing in :X)

timeout_ms = EnvParser.parse :TIMEOUT_MS, as: :integer
```

For a full list of all "as" types available out-of-the-box, [see the documentation for modules listed under EnvParserTypes](http://nestor-custodio.github.io/env_parser/EnvParserTypes.html).

---

#### Setting Non-Trivial Defaults

```ruby
## If the ENV variable you want is unset (nil) or blank (''),
## the return value is a sensible default for the given "as" type
## (0 or 0.0 for numbers, an empty tring, an empty Array or Hash, etc).
## Sometimes you want a non-trivial default, however.

EnvParser.parse :MISSING_ENV_VARIABLE, as: :integer  ## => 0
EnvParser.parse :MISSING_ENV_VARIABLE, as: :integer, if_unset: 250  ## => 250


## Note that "if_unset" values are used as-is, with no type conversion.

EnvParser.parse :MISSING_ENV_VARIABLE, as: :integer, if_unset: 'Careful!'  ## => 'Careful!'
```

---

#### Setting Constants From ENV Values

```ruby
## Global constants...

ENV['API_KEY']  ## => 'unbreakable p4$$w0rd'

EnvParser.register :API_KEY, as: :string
API_KEY  ## => 'unbreakable p4$$w0rd' (registered within the Kernel module, so it's available everywhere)


## ... and class/module-level constants!

ENV['ULTIMATE_LINK']  ## => 'https://youtu.be/L_jWHffIx5E'

EnvParser.register :ULTIMATE_LINK, as: :string, within: URI
URI::ULTIMATE_LINK  ## => 'https://youtu.be/L_jWHffIx5E'

ULTIMATE_LINK  ## => raises NameError (the un-namespaced constant is only in scope within the URI module)




## You can also set multiple constants in one call, which is considerably cleaner to read:

EnvParser.register :A, as: :string
EnvParser.register :B, as: :integer, if_unset: 25
EnvParser.register :C, as: :boolean, if_unset: true


## ... is equivalent to ...

EnvParser.register(
  A: { as: :string },
  B: { as: :integer, if_unset: 25 },
  C: { as: :boolean, if_unset: true }
)
```

---

#### Binding EnvParser Proxies Onto ENV

```ruby
## You can bind proxy "parse" and "register" methods onto ENV.
## This is done without polluting the method space for other objects.

EnvParser.add_env_bindings  ## Sets up the proxy methods.


## Now you can call "parse" and "register" on ENV itself,
## which is more legible and feels more straight-forward.

ENV['SHORT_PI']  ## => '3.1415926'

ENV.parse :SHORT_PI, as: :float  ## => 3.1415926
ENV.register :SHORT_PI, as: :float  ## Your constant is set, my man!


## Note that ENV's proxy "parse" method will *always* interpret the
## value given as an ENV key (converting to a String, if necessary).
## This is different from the non-proxy "parse" method, which will use
## String values as-is and only looks up ENV values when given a Symbol.
```


### Advanced Usage

#### Custom Validation Of Parsed Values

```ruby
## Sometimes setting the type alone is a bit too open-ended.
## The "from_set" option lets you restrict the set of allowed values.

EnvParser.parse :API_TO_USE, as: :symbol, from_set: %i[internal external]
EnvParser.parse :SOME_CUSTOM_NETWORK_PORT, as: :integer, from_set: (1..65535), if_unset: 80


## And if the value is not allowed...

EnvParser.parse :NEGATIVE_NUMBER, as: :integer, from_set: (1..5)  ## => raises EnvParser::ValueNotAllowed




## The "validated_by" option allows for more complex validation.

EnvParser.parse :MUST_BE_LOWERCASE, as: :string, validated_by: ->(value) { value == value.downcase }


## ... but a block will also do the trick!

EnvParser.parse(:MUST_BE_LOWERCASE, as: :string) { |value| value == value.downcase }
EnvParser.parse(:CONNECTION_RETRIES, as: :integer, &:nonzero?)
```

---

#### Defining Your Own EnvParser "as" Types

```ruby
## If you use a particular validation many times,
## or are often manipulating values in the same way
## after EnvParser has done its thing, you may want
## to register a new type altogether.

a = EnvParser.parse :A, as: :int, if_unset: nil
raise unless passes_all_my_checks?(a)

b = EnvParser.parse :B, as: :int, if_unset: nil
raise unless passes_all_my_checks?(b)


## ... is perhaps best handled by defining a new type:

EnvParser.define_type(:my_special_type_of_number, if_unset: nil) do |value|
  value = value.to_i
  unless passes_all_my_checks?(value)
    raise(EnvParser::ValueNotConvertibleError, 'cannot parse as a "special type number"')
  end

  value
end

a = EnvParser.parse :A, as: :my_special_type_of_number
b = EnvParser.parse :B, as: :my_special_type_of_number


## Defining a new type makes your code both more maintainable
## (all the logic for your special type is only defined once)
## and more readable (your "parse" calls aren't littered with
## type-checking cruft).
```

---

[Consult the repo docs for the full EnvParser documentation.](http://nestor-custodio.github.io/env_parser/EnvParser.html)


## Feature Roadmap / Future Development

Additional features/options coming in the future:

- Continue to round out the "as" type selection as ideas come to mind, suggestions are made, and pull requests are submitted.


## Contribution / Development

Bug reports and pull requests are welcome on GitHub at https://github.com/nestor-custodio/env_parser.

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Linting is courtesy of [Rubocop](https://github.com/bbatsov/rubocop) and documentation is built using [Yard](https://yardoc.org/). Neither is included in the Gemspec; you'll need to install these locally to take advantage.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
