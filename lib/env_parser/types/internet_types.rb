require 'env_parser'

# The parent module for all EnvParser type definition modules.
# Exists only for documentation's sake.
#
module EnvParser::Types
  # Defines types for internet-related values, adding the following:
  #
  # <table>
  #   <tbody>
  #     <tr>
  #       <th><code>:as</code> value</th>
  #       <th>type returned</th>
  #       <th>default</th>
  #       <th>notes</th>
  #     </tr>
  #   </tbody>
  #   <tbody>
  #     <tr>
  #       <td>:ipv4_address</td>
  #       <td>String</td>
  #       <td><code>nil</code></td>
  #       <td>
  #         An IPv4 address in 4-octet dot-decimal notation,
  #         <br />
  #         with no CIDR or subnet suffix (e.g. <code>'192.168.0.1'</code>).
  #       </td>
  #     </tr>
  #     <tr>
  #       <td>:ipv6_address</td>
  #       <td>String</td>
  #       <td><code>nil</code></td>
  #       <td>An IPv6 address, in RFC5952 format.</td>
  #     </tr>
  #     <tr>
  #       <td>:network_port / :port</td>
  #       <td>Integer</td>
  #       <td><code>nil</code></td>
  #       <td></td>
  #     </tr>
  #     <tr>
  #       <td>:email_address</td>
  #       <td>String</td>
  #       <td><code>nil</code></td>
  #       <td>
  #         A "simple" email address, containing only a username and a domain.
  #         <br />
  #         Note this does not guarantee RFC5322-conformity.
  #       </td>
  #     </tr>
  #     <tr>
  #       <td>:version / :semver</td>
  #       <td>MatchData</td>
  #       <td><code>nil</code></td>
  #       <td>
  #         The resulting MatchData has named captures for "major", "minor", "patch", "prerelease", and "buildmetadata".
  #         <br />
  #         The Regex used for generating this MatchData is available at: https://regex101.com/r/Ly7O1x/3/
  #         <br />
  #         See https://semver.org for additional info.
  #       </td>
  #     </tr>
  #   </tbody>
  # </table>
  #
  module InternetTypes
    EnvParser.define_type(:ipv4_address, if_unset: nil) do |value|
      begin
        require 'socket'
        address = Addrinfo.getaddrinfo(value, nil, Socket::AF_INET, nil, Socket::IPPROTO_TCP).first
        raise StandardError unless address.ipv4?
      rescue StandardError
        raise EnvParser::ValueNotConvertibleError, 'non-ip value'
      end

      address.ip_address
    end

    EnvParser.define_type(:ipv6_address, if_unset: nil) do |value|
      begin
        require 'socket'
        address = Addrinfo.getaddrinfo(value, nil, Socket::AF_INET6, nil, Socket::IPPROTO_TCP).first
        raise StandardError unless address.ipv6?
      rescue StandardError
        raise EnvParser::ValueNotConvertibleError, 'non-ip value'
      end

      address.ip_address
    end

    EnvParser.define_type(:network_port, aliases: :port, if_unset: nil) do |value|
      begin
        Integer(value)
      rescue ArgumentError
        raise(EnvParser::ValueNotConvertibleError, 'non-numeric value')
      end

      value = value.to_i
      raise(EnvParser::ValueNotAllowedError, 'value out of range') unless (0..65535).cover?(value)

      value
    end

    EnvParser.define_type(:email_address, if_unset: nil) do |value|
      simple_email = %r[^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$]i ## rubocop:disable Layout/LineLength
      raise(EnvParser::ValueNotConvertibleError, 'not an email') unless value.match?(simple_email)

      value
    end

    EnvParser.define_type(:version, aliases: :semver, if_unset: nil) do |value|
      # We're using the official semver.org-provided regex.
      semver = %r{^(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$} ## rubocop:disable Layout/LineLength

      match_data = value.match(semver)
      raise(EnvParser::ValueNotConvertibleError, 'not a semver-compliant value') unless match_data

      match_data
    end
  end
end
