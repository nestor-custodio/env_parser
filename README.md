# EnvLoader

If your code uses environment variables, you know that `ENV` will always surface these as strings. Interpreting these strings as the value you *actually* want to see/use takes some additional effort, however.

If you want a number, you need to cast: `#to_i`/`#to_f`. If you want a boolean, you need to check for a specific value: `ENV['SOME_VAR'] == 'true'`. Maybe you want to set non-trivial defaults (something other than `0` or `''`)? Maybe you only want to allow values from a limited set.

Things can get out of control pretty fast, especially as the number of environment variables in play grows. EnvLoader aims to help keep things simple.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'env_loader'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install env_loader

## Usage

TODO: Write usage instructions here

## Contribution / Development

Bug reports and pull requests are welcome on GitHub at https://github.com/nestor-custodio/env_loader.

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Linting is courtesy of [Rubocop](https://github.com/bbatsov/rubocop) and documentation is built using [Yard](https://yardoc.org/). Neither is included in the Gemspec; you'll need to install these locally to take advantage.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
