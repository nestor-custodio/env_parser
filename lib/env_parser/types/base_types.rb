require 'env_parser'

## The parent module for all EnvParser type definition modules.
## Exists only for documentation's sake.
##
module EnvParserTypes
  ## Defines types for primitive classes, adding the following:
  ##
  ## <table>
  ##   <tbody>
  ##     <tr>
  ##       <th><code>:as</code> value</th>
  ##       <th>type returned</th>
  ##     </tr>
  ##   </tbody>
  ##   <tbody>
  ##     <tr>
  ##       <td>:string</td>
  ##       <td>String</td>
  ##     </tr>
  ##     <tr>
  ##       <td>:symbol</td>
  ##       <td>Symbol</td>
  ##     </tr>
  ##     <tr>
  ##       <td>:boolean</td>
  ##       <td>TrueValue / FalseValue</td>
  ##     </tr>
  ##     <tr>
  ##       <td>:int / :integer</td>
  ##       <td>Integer</td>
  ##     </tr>
  ##     <tr>
  ##       <td>:float / :decimal / :number</td>
  ##       <td>Float</td>
  ##     </tr>
  ##     <tr>
  ##       <td>:json</td>
  ##       <td>&lt; depends on JSON given &gt;</td>
  ##     </tr>
  ##     <tr>
  ##       <td>:array</td>
  ##       <td>Array</td>
  ##     </tr>
  ##     <tr>
  ##       <td>:hash</td>
  ##       <td>Hash</td>
  ##     </tr>
  ##   </tbody>
  ## </table>
  ##
  ## Note JSON is parsed using *quirks-mode* (meaning 'true', '25', and 'null' are all considered valid, parseable JSON).
  ##
  module BaseTypes
    EnvParser.define_type(:string, if_unset: '') do |value|
      value
    end

    EnvParser.define_type(:symbol, if_unset: :'', &:to_sym)

    EnvParser.define_type(:boolean, if_unset: false) do |value|
      case value
      when '', '0', 'f', 'false' then false
      else true
      end
    end

    EnvParser.define_type(:integer, aliases: %i[int], if_unset: 0, &:to_i)

    EnvParser.define_type(:float, aliases: %i[decimal number], if_unset: 0.0, &:to_f)

    EnvParser.define_type(:json, if_unset: nil) do |value|
      require 'json'

      decoded_json = JSON.parse(value, quirks_mode: true)
      { decoded_json: decoded_json }.with_indifferent_access[:decoded_json]
    end

    EnvParser.define_type(:array, if_unset: []) do |value|
      decoded_json = EnvParser.parse(value, as: :json)
      raise(EnvParser::ValueNotConvertibleError, 'non-array value') unless decoded_json.is_a? Array

      decoded_json
    end

    EnvParser.define_type(:hash, if_unset: {}) do |value|
      decoded_json = EnvParser.parse(value, as: :json)
      raise(EnvParser::ValueNotConvertibleError, 'non-hash value') unless decoded_json.is_a? Hash

      decoded_json
    end
  end
end
