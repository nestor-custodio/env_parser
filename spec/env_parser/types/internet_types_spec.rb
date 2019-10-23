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
end
