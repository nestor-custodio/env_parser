require 'env_parser'

## The parent module for all EnvParser type definition modules.
## Exists only for documentation's sake.
##
module EnvParser::Types
  ## Defines types for date/time-related values, adding the following:
  ##
  ## <table>
  ##   <tbody>
  ##     <tr>
  ##       <th><code>:as</code> value</th>
  ##       <th>type returned</th>
  ##       <th>default</th>
  ##       <th>notes</th>
  ##     </tr>
  ##   </tbody>
  ##   <tbody>
  ##     <tr>
  ##       <td>:date</td>
  ##       <td>Date</td>
  ##       <td><code>nil</code></td>
  ##       <td>
  ##         A natural language or ISO8601-parseable date.
  ##         <br />
  ##         Actual interpretation of the value is handled by the *chronic* gem.
  ##       </td>
  ##     </tr>
  ##     <tr>
  ##       <td>:time / :datetime</td>
  ##       <td>Time</td>
  ##       <td><code>nil</code></td>
  ##       <td>
  ##         A natural language or ISO8601-parseable date and time.
  ##         <br />
  ##         Actual interpretation of the value is handled by the *chronic* gem.
  ##       </td>
  ##     </tr>
  ##     <tr>
  ##       <td>:duration</td>
  ##       <td>Numeric</td>
  ##       <td><code>nil</code></td>
  ##       <td>
  ##         A natural language or ISO8601-parseable period.
  ##         <br />
  ##         Value returned is the number of seconds in the given period.
  ##         <br />
  ##         Actual interpretation of the value is handled by the *chronic_duration* gem.
  ##       </td>
  ##     </tr>
  ##   </tbody>
  ## </table>
  ##
  module ChronologyTypes
    EnvParser.define_type(:date, if_unset: nil) do |value|
      require 'chronic'

      begin
        value = Chronic.parse value, guess: :begin
        raise StandardError unless value.is_a? Time
      rescue StandardError
        raise EnvParser::ValueNotConvertibleError, 'non-date value'
      end

      value.to_date
    end

    EnvParser.define_type(:time, aliases: :datetime, if_unset: nil) do |value|
      require 'chronic'

      begin
        value = Chronic.parse value, guess: :begin
        raise StandardError unless value.is_a? Time
      rescue StandardError
        raise EnvParser::ValueNotConvertibleError, 'non-time value'
      end

      value
    end

    EnvParser.define_type(:duration, if_unset: nil) do |value|
      require 'chronic_duration'

      begin
        original_raise_setting = ChronicDuration.raise_exceptions
        ChronicDuration.raise_exceptions = true

        ## With `raise_exceptions` set, ChronicDuration will fail on the "P" and "T" in ISO8601
        ## periods, so we have to check for and remove them.
        ##
        iso_period = %r{^\s*P(?:[0-9.]Y)?(?:[0-9.]M)?(?:[0-9.]W)?(?:[0-9.]D)?(?:T(?:[0-9.]H)?(?:[0-9.]M)?(?:[0-9.]S)?)?\s*$} ## rubocop:disable Layout/LineLength
        value = value.delete 'PT' if value =~ iso_period

        value = ChronicDuration.parse value, keep_zero: true
      rescue StandardError
        raise EnvParser::ValueNotConvertibleError, 'non-duration value'
      ensure
        ChronicDuration.raise_exceptions = original_raise_setting
      end

      value
    end
  end
end
