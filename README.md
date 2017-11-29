# EnvParser

If your code uses environment variables, you know that `ENV` will always surface these as strings. Interpreting these strings as the value you *actually* want to see/use takes some additional effort, however.

If you want a number, you need to cast: `#to_i`/`#to_f`. If you want a boolean, you need to check for a specific value: `ENV['SOME_VAR'] == 'true'`. Maybe you want to set non-trivial defaults (something other than `0` or `''`)? Maybe you only want to allow values from a limited set.

Things can get out of control pretty fast, especially as the number of environment variables in play grows. EnvParser aims to help keep things simple.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'env_parser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install env_parser


## Usage

Basic EnvParser usage:
```ruby
## Returns ENV['TIMEOUT_MS'] as an Integer.
## Yields 0 if ENV['TIMEOUT_MS'] is unset or nil.
##
timeout_ms = EnvParser.parse ENV['TIMEOUT_MS'], as: :integer

## LESS TYPING, PLZ!  :(
## If you pass in a Symbol instead of a String, EnvParser
## will use the value behind the matching String key in ENV.
## (i.e. passing in `ENV['X']` is equivalent to passing in `:X`)
##
timeout_ms = EnvParser.parse :TIMEOUT_MS, as: :integer

## If the ENV variable you want is unset (`nil`) or blank (`''`),
## the return value is a sensible default for the given "as" type.
## Sometimes you want a non-trivial default (not just 0, '', etc), however.
##
EnvParser.parse :MISSING_ENV_VARIABLE, as: :integer ## => 0
EnvParser.parse :MISSING_ENV_VARIABLE, as: :integer, if_unset: 250 ## => 250

## Note that "if_unset" values are used as-is, with no type conversion.
##
EnvParser.parse :MISSING_ENV_VARIABLE, as: :integer, if_unset: 'oof!' ## => 'oof!'
```

---

The named `:as` value is required. Allowed values are:

| `:as` value                 | type returned                   |
|-----------------------------|---------------------------------|
| :string                     | String                          |
| :symbol                     | Symbol                          |
| :boolean                    | TrueValue / FalseValue          |
| :int / :integer             | Integer                         |
| :float / :decimal / :number | Float                           |
| :json                       | &lt; depends on JSON given &gt; |
| :array                      | Array                           |
| :hash                       | Hash                            |

Note JSON is parsed using *quirks-mode* (meaning 'true', '25', and 'null' are all considered valid, parseable JSON).

---

[Consult the repo docs](https://github.com/nestor-custodio/env_parser/blob/master/docs/index.html) for the full EnvParser documentation.


## Feature Roadmap / Future Development

Additional features/options coming in the future:
- A `:from_set` option to restrict acceptable values to those on a given list.
- An `EnvParser.load` method that will not only parse the given value, but will set a constant, easily converting environment variables into constants in your code.
- An `EnvParser.load_all` method to shortcut multiple `.load` calls.
- A means to **optionally** bind `#parse`, `#load`, and `#load_all` methods onto `ENV` itself (not all hashes!). Because `ENV.parse ...` reads better than `EnvParser.parse ...`.
- ... ?


## Contribution / Development

Bug reports and pull requests are welcome on GitHub at https://github.com/nestor-custodio/env_parser.

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Linting is courtesy of [Rubocop](https://github.com/bbatsov/rubocop) and documentation is built using [Yard](https://yardoc.org/). Neither is included in the Gemspec; you'll need to install these locally to take advantage.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
