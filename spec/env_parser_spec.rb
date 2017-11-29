require 'json'

RSpec.describe EnvParser do
  it 'has a version number' do
    expect(EnvParser::VERSION).not_to be nil
  end

  it 'responds to `.parse`' do
    expect(EnvParser).to respond_to(:parse)
  end

  describe 'EnvParser.parse' do
    it 'can parse strings' do
      expect(EnvParser.parse(nil, as: :string)).to eq('')
      expect(EnvParser.parse('', as: :string)).to eq('')

      expect(EnvParser.parse('value', as: :string)).to eq('value')
    end

    it 'can parse symbols' do
      expect(EnvParser.parse(nil, as: :symbol)).to eq(:'')
      expect(EnvParser.parse('', as: :symbol)).to eq(:'')

      expect(EnvParser.parse('value', as: :symbol)).to eq(:value)
    end

    it 'can parse booleans' do
      expect(EnvParser.parse(nil, as: :boolean)).to eq(false)
      expect(EnvParser.parse('', as: :boolean)).to eq(false)

      expect(EnvParser.parse('0', as: :boolean)).to eq(false)
      expect(EnvParser.parse('f', as: :boolean)).to eq(false)
      expect(EnvParser.parse('false', as: :boolean)).to eq(false)

      expect(EnvParser.parse('1', as: :boolean)).to eq(true)
      expect(EnvParser.parse('t', as: :boolean)).to eq(true)
      expect(EnvParser.parse('true', as: :boolean)).to eq(true)
    end

    it 'can parse integers' do
      %i[int integer].each do |type|
        expect(EnvParser.parse(nil, as: type)).to eq(0)
        expect(EnvParser.parse('', as: type)).to eq(0)

        expect(EnvParser.parse('-1.9', as: type)).to eq(-1)
        expect(EnvParser.parse('-1.1', as: type)).to eq(-1)
        expect(EnvParser.parse('-1', as: type)).to eq(-1)
        expect(EnvParser.parse('0', as: type)).to eq(0)
        expect(EnvParser.parse('1', as: type)).to eq(1)
        expect(EnvParser.parse('1.1', as: type)).to eq(1)
        expect(EnvParser.parse('1.9', as: type)).to eq(1)

        expect(EnvParser.parse('non-numeric', as: type)).to eq(0)
      end
    end

    it 'can parse floats' do
      %i[float decimal number].each do |type|
        expect(EnvParser.parse(nil, as: type)).to eq(0.0)
        expect(EnvParser.parse('', as: type)).to eq(0.0)

        expect(EnvParser.parse('-1.9', as: type)).to eq(-1.9)
        expect(EnvParser.parse('-1.1', as: type)).to eq(-1.1)
        expect(EnvParser.parse('-1', as: type)).to eq(-1.0)
        expect(EnvParser.parse('0', as: type)).to eq(0.0)
        expect(EnvParser.parse('1', as: type)).to eq(1.0)
        expect(EnvParser.parse('1.1', as: type)).to eq(1.1)
        expect(EnvParser.parse('1.9', as: type)).to eq(1.9)

        expect(EnvParser.parse('non-numeric', as: type)).to eq(0.0)
      end
    end

    it 'can parse json' do
      expect(EnvParser.parse(nil, as: :json)).to eq(nil)
      expect(EnvParser.parse('', as: :json)).to eq(nil)

      expect { EnvParser.parse('non-json-parseable string', as: :json) }.to raise_exception(JSON::ParserError)

      expect(EnvParser.parse('null', as: :json)).to eq(nil)
      expect(EnvParser.parse('true', as: :json)).to eq(true)
      expect(EnvParser.parse('false', as: :json)).to eq(false)
      expect(EnvParser.parse('1', as: :json)).to eq(1)
      expect(EnvParser.parse('1.1', as: :json)).to eq(1.1)
      expect(EnvParser.parse('"some string"', as: :json)).to eq('some string')
      expect(EnvParser.parse('["one", 2, "three"]', as: :json)).to eq(['one', 2, 'three'])
      expect(EnvParser.parse('{ "one": 1, "two": 2, "three": "three" }', as: :json)).to eq('one' => 1, 'two' => 2, 'three' => 'three')
    end

    it 'can parse arrays' do
      expect(EnvParser.parse(nil, as: :array)).to eq([])
      expect(EnvParser.parse('', as: :array)).to eq([])

      expect { EnvParser.parse('non-json-parseable string', as: :array) }.to raise_exception(JSON::ParserError)
      expect { EnvParser.parse('"parseable json, but not an array"', as: :array) }.to raise_exception(ArgumentError)

      expect(EnvParser.parse('["one", 2, "three"]', as: :array)).to eq(['one', 2, 'three'])
    end

    it 'can parse hashes' do
      expect(EnvParser.parse(nil, as: :hash)).to eq({})
      expect(EnvParser.parse('', as: :hash)).to eq({})

      expect { EnvParser.parse('non-json-parseable string', as: :hash) }.to raise_exception(JSON::ParserError)
      expect { EnvParser.parse('"parseable json, but not a hash"', as: :hash) }.to raise_exception(ArgumentError)

      expect(EnvParser.parse('{ "one": 1, "two": 2, "three": "three" }', as: :hash)).to eq('one' => 1, 'two' => 2, 'three' => 'three')
    end

    it 'returns the requested default when necessary' do
      expect(EnvParser.parse(nil, as: :integer, if_unset: 25)).to eq(25)
      expect(EnvParser.parse('', as: :integer, if_unset: 25)).to eq(25)

      expect(EnvParser.parse('99', as: :float, if_unset: 25.0)).to eq(99.0)
    end

    it 'only allows values from a limited set' do
      expect(EnvParser.parse('25', as: :integer, from_set: [20, 25, 30])).to eq(25)
      expect { EnvParser.parse('25', as: :integer, from_set: [1, 2, 3]) }.to raise_exception(EnvParser::ValueNotAllowed)

      expect(EnvParser.parse(nil, as: :integer, if_unset: 9, from_set: [1, 2, 3])).to eq(9)
    end
  end
end
