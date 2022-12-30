RSpec.describe EnvParser::Types::InternetTypes do
  it 'can parse ipv4 addresses' do
    expect(EnvParser.parse(nil, as: :ipv4_address)).to eq(nil)
    expect(EnvParser.parse('', as: :ipv4_address)).to eq(nil)

    expect(EnvParser.parse('localhost', as: :ipv4_address)).to eq('127.0.0.1')
    expect(EnvParser.parse('192.168.000.001', as: :ipv4_address)).to eq('192.168.0.1')

    expect { EnvParser.parse('not an ip address', as: :ipv4_address) }.to raise_error(EnvParser::ValueNotConvertibleError)
  end

  it 'can parse ipv6 addresses' do
    expect(EnvParser.parse(nil, as: :ipv6_address)).to eq(nil)
    expect(EnvParser.parse('', as: :ipv6_address)).to eq(nil)

    expect(EnvParser.parse('::', as: :ipv6_address)).to eq('::')
    expect(EnvParser.parse('::1', as: :ipv6_address)).to eq('::1')
    expect(EnvParser.parse('abcd::abcd:abcd', as: :ipv6_address)).to eq('abcd::abcd:abcd')

    expect { EnvParser.parse('not an ip address', as: :ipv6_address) }.to raise_error(EnvParser::ValueNotConvertibleError)
  end

  it 'can parse network ports' do
    %i[network_port port].each do |type|
      expect(EnvParser.parse(nil, as: type)).to eq(nil)
      expect(EnvParser.parse('', as: type)).to eq(nil)

      expect(EnvParser.parse('80', as: type)).to eq(80)
      expect(EnvParser.parse('8080', as: type)).to eq(8080)

      expect { EnvParser.parse('99999999', as: type) }.to raise_error(EnvParser::ValueNotAllowedError)
      expect { EnvParser.parse('not a port number', as: type) }.to raise_error(EnvParser::ValueNotConvertibleError)
    end
  end

  it 'can parse email addresses' do
    expect(EnvParser.parse(nil, as: :email_address)).to eq(nil)
    expect(EnvParser.parse('', as: :email_address)).to eq(nil)

    expect(EnvParser.parse('email@example.com', as: :email_address)).to eq('email@example.com')
    expect(EnvParser.parse('some.user@gmail.com', as: :email_address)).to eq('some.user@gmail.com')

    expect { EnvParser.parse('not an email address', as: :email_address) }.to raise_error(EnvParser::ValueNotConvertibleError)
  end

  it 'can parse version numbers' do
    %i[version semver].each do |type|
      expect(EnvParser.parse(nil, as: type)).to eq(nil)
      expect(EnvParser.parse('', as: type)).to eq(nil)

      # Our list of valid version strings is a subset of those in the official semver.org-provided regex suite.
      # rubocop:disable Layout
      #
      valid_version_strings = {
        '0.0.4'                 => { major: '0' , minor: '0', patch: '4', prerelease: nil           , buildmetadata: nil          },
        '1.2.3'                 => { major: '1' , minor: '2', patch: '3', prerelease: nil           , buildmetadata: nil          },
        '1.1.2-prerelease+meta' => { major: '1' , minor: '1', patch: '2', prerelease: 'prerelease'  , buildmetadata: 'meta'       },
        '1.1.2+meta'            => { major: '1' , minor: '1', patch: '2', prerelease: nil           , buildmetadata: 'meta'       },
        '1.1.2+meta-valid'      => { major: '1' , minor: '1', patch: '2', prerelease: nil           , buildmetadata: 'meta-valid' },
        '1.0.0-alpha'           => { major: '1' , minor: '0', patch: '0', prerelease: 'alpha'       , buildmetadata: nil          },
        '1.0.0-beta'            => { major: '1' , minor: '0', patch: '0', prerelease: 'beta'        , buildmetadata: nil          },
        '1.0.0-alpha.beta'      => { major: '1' , minor: '0', patch: '0', prerelease: 'alpha.beta'  , buildmetadata: nil          },
        '1.0.0-alpha.beta.1'    => { major: '1' , minor: '0', patch: '0', prerelease: 'alpha.beta.1', buildmetadata: nil          },
        '1.0.0-alpha.1'         => { major: '1' , minor: '0', patch: '0', prerelease: 'alpha.1'     , buildmetadata: nil          },
        '1.0.0-alpha0.valid'    => { major: '1' , minor: '0', patch: '0', prerelease: 'alpha0.valid', buildmetadata: nil          },
        '1.0.0-alpha.0valid'    => { major: '1' , minor: '0', patch: '0', prerelease: 'alpha.0valid', buildmetadata: nil          },
        '1.0.0-rc.1+build.1'    => { major: '1' , minor: '0', patch: '0', prerelease: 'rc.1'        , buildmetadata: 'build.1'    },
        '2.0.0-rc.1+build.123'  => { major: '2' , minor: '0', patch: '0', prerelease: 'rc.1'        , buildmetadata: 'build.123'  },
        '1.2.3-beta'            => { major: '1' , minor: '2', patch: '3', prerelease: 'beta'        , buildmetadata: nil          },
        '10.2.3-DEV-SNAPSHOT'   => { major: '10', minor: '2', patch: '3', prerelease: 'DEV-SNAPSHOT', buildmetadata: nil          },
        '1.2.3-SNAPSHOT-123'    => { major: '1' , minor: '2', patch: '3', prerelease: 'SNAPSHOT-123', buildmetadata: nil          },
        '2.0.0+build.1848'      => { major: '2' , minor: '0', patch: '0', prerelease: nil           , buildmetadata: 'build.1848' },
        '2.0.1-alpha.1227'      => { major: '2' , minor: '0', patch: '1', prerelease: 'alpha.1227'  , buildmetadata: nil          },
        '1.0.0-alpha+beta'      => { major: '1' , minor: '0', patch: '0', prerelease: 'alpha'       , buildmetadata: 'beta'       },
        '1.0.0-0A.is.legal'     => { major: '1' , minor: '0', patch: '0', prerelease: '0A.is.legal' , buildmetadata: nil          }
      }
      # rubocop:enable Layout

      valid_version_strings.each do |version, expected_matches|
        parsed_value = EnvParser.parse(version, as: type)

        expect(parsed_value).to_not eq(nil)
        expected_matches.each { |match_name, expected_value| expect(parsed_value[match_name]).to eq(expected_value) }
      end

      # Our list of invalid version strings is a subset of those in the official semver.org-provided regex suite.
      #
      invalid_version_strings = ['1', '1.2', '1.2.3-0123', '1.2.3-0123.0123', '1.1.2+.123', '+invalid', '-invalid', '-invalid+invalid',
                                 '-invalid.01', 'alpha', 'alpha.1', 'alpha+beta', '1.0.0-alpha..', '1.0.0-alpha..1', '01.1.1', '1.01.1',
                                 '1.1.01', '1.2.3.DEV', '1.2-SNAPSHOT', '+justmeta', '9.8.7+meta+meta', '9.8.7-whatever+meta+meta']

      invalid_version_strings.each { |version| expect { EnvParser.parse(version, as: type) }.to raise_error(EnvParser::ValueNotConvertibleError) }
    end
  end
end
