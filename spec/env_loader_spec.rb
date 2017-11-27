require 'json'

RSpec.describe EnvLoader do
  it 'has a version number' do
    expect(EnvLoader::VERSION).not_to be nil
  end

  it 'responds to `.parse`' do
    expect(EnvLoader).to respond_to(:parse)
  end

  describe 'EnvLoader.parse' do
    it 'can parse strings' do
      expect(EnvLoader.parse(nil, as: :string)).to eq('')
      expect(EnvLoader.parse('', as: :string)).to eq('')

      expect(EnvLoader.parse('value', as: :string)).to eq('value')
    end

    it 'can parse symbols' do
      expect(EnvLoader.parse(nil, as: :symbol)).to eq(:'')
      expect(EnvLoader.parse('', as: :symbol)).to eq(:'')

      expect(EnvLoader.parse('value', as: :symbol)).to eq(:value)
    end

    it 'can parse booleans' do
      expect(EnvLoader.parse(nil, as: :boolean)).to eq(false)
      expect(EnvLoader.parse('', as: :boolean)).to eq(false)

      expect(EnvLoader.parse('0', as: :boolean)).to eq(false)
      expect(EnvLoader.parse('f', as: :boolean)).to eq(false)
      expect(EnvLoader.parse('false', as: :boolean)).to eq(false)

      expect(EnvLoader.parse('1', as: :boolean)).to eq(true)
      expect(EnvLoader.parse('t', as: :boolean)).to eq(true)
      expect(EnvLoader.parse('true', as: :boolean)).to eq(true)
    end

    it 'can parse integers' do
      %i[int integer].each do |type|
        expect(EnvLoader.parse(nil, as: type)).to eq(0)
        expect(EnvLoader.parse('', as: type)).to eq(0)

        expect(EnvLoader.parse('-1.9', as: type)).to eq(-1)
        expect(EnvLoader.parse('-1.1', as: type)).to eq(-1)
        expect(EnvLoader.parse('-1', as: type)).to eq(-1)
        expect(EnvLoader.parse('0', as: type)).to eq(0)
        expect(EnvLoader.parse('1', as: type)).to eq(1)
        expect(EnvLoader.parse('1.1', as: type)).to eq(1)
        expect(EnvLoader.parse('1.9', as: type)).to eq(1)

        expect(EnvLoader.parse('non-numeric', as: type)).to eq(0)
      end
    end

    it 'can parse floats' do
      %i[float decimal number].each do |type|
        expect(EnvLoader.parse(nil, as: type)).to eq(0.0)
        expect(EnvLoader.parse('', as: type)).to eq(0.0)

        expect(EnvLoader.parse('-1.9', as: type)).to eq(-1.9)
        expect(EnvLoader.parse('-1.1', as: type)).to eq(-1.1)
        expect(EnvLoader.parse('-1', as: type)).to eq(-1.0)
        expect(EnvLoader.parse('0', as: type)).to eq(0.0)
        expect(EnvLoader.parse('1', as: type)).to eq(1.0)
        expect(EnvLoader.parse('1.1', as: type)).to eq(1.1)
        expect(EnvLoader.parse('1.9', as: type)).to eq(1.9)

        expect(EnvLoader.parse('non-numeric', as: type)).to eq(0.0)
      end
    end

    it 'can parse json' do
      expect(EnvLoader.parse(nil, as: :json)).to eq(nil)
      expect(EnvLoader.parse('', as: :json)).to eq(nil)

      expect { EnvLoader.parse('non-json-parseable string', as: :json) }.to raise_exception(JSON::ParserError)

      expect(EnvLoader.parse('null', as: :json)).to eq(nil)
      expect(EnvLoader.parse('true', as: :json)).to eq(true)
      expect(EnvLoader.parse('false', as: :json)).to eq(false)
      expect(EnvLoader.parse('1', as: :json)).to eq(1)
      expect(EnvLoader.parse('1.1', as: :json)).to eq(1.1)
      expect(EnvLoader.parse('"some string"', as: :json)).to eq('some string')
      expect(EnvLoader.parse('["one", 2, "three"]', as: :json)).to eq(['one', 2, 'three'])
      expect(EnvLoader.parse('{ "one": 1, "two": 2, "three": "three" }', as: :json)).to eq('one' => 1, 'two' => 2, 'three' => 'three')
    end

    it 'can parse arrays' do
      expect(EnvLoader.parse(nil, as: :array)).to eq([])
      expect(EnvLoader.parse('', as: :array)).to eq([])

      expect { EnvLoader.parse('non-json-parseable string', as: :array) }.to raise_exception(JSON::ParserError)
      expect { EnvLoader.parse('"parseable json, but not an array"', as: :array) }.to raise_exception(ArgumentError)

      expect(EnvLoader.parse('["one", 2, "three"]', as: :array)).to eq(['one', 2, 'three'])
    end

    it 'can parse hashes' do
      expect(EnvLoader.parse(nil, as: :hash)).to eq({})
      expect(EnvLoader.parse('', as: :hash)).to eq({})

      expect { EnvLoader.parse('non-json-parseable string', as: :hash) }.to raise_exception(JSON::ParserError)
      expect { EnvLoader.parse('"parseable json, but not a hash"', as: :hash) }.to raise_exception(ArgumentError)

      expect(EnvLoader.parse('{ "one": 1, "two": 2, "three": "three" }', as: :hash)).to eq('one' => 1, 'two' => 2, 'three' => 'three')
    end
  end
end
