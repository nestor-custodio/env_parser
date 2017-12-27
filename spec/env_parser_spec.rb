RSpec.describe EnvParser do
  it 'has a version number' do
    expect(EnvParser::VERSION).not_to be nil
  end

  it 'responds to `.define_type`' do
    expect(EnvParser).to respond_to(:define_type)
  end

  describe 'EnvParser.define_type' do
    it 'can register new types' do
      EnvParser.define_type(:thirty) { |_| 30 }
      expect(EnvParser.parse('dummy value', as: :thirty)).to eq(30)
    end
  end

  it 'responds to `.parse`' do
    expect(EnvParser).to respond_to(:parse)
  end

  describe 'EnvParser.parse' do
    it 'returns the requested default when necessary' do
      expect(EnvParser.parse(nil, as: :integer, if_unset: 25)).to eq(25)
      expect(EnvParser.parse('', as: :integer, if_unset: 25)).to eq(25)

      expect(EnvParser.parse('99', as: :float, if_unset: 25.0)).to eq(99.0)
    end

    it 'only allows values from a limited set' do
      expect(EnvParser.parse('25', as: :integer, from_set: [20, 25, 30])).to eq(25)
      expect { EnvParser.parse('25', as: :integer, from_set: [1, 2, 3]) }.to raise_error(EnvParser::ValueNotAllowedError)

      expect(EnvParser.parse(nil, as: :integer, if_unset: 9, from_set: [1, 2, 3])).to eq(9)
    end

    it 'only allows values that pass user-defined validation' do
      expect(EnvParser.parse('abc', as: :string)).to eq('abc')
      expect(EnvParser.parse('abc', as: :string) { |_| true }).to eq('abc')
      expect { EnvParser.parse('abc', as: :string) { |_| false } }.to raise_error(EnvParser::ValueNotAllowedError)

      expect(EnvParser.parse('abc', as: :string)).to eq('abc')
      expect(EnvParser.parse('abc', as: :string, validated_by: ->(_) { true })).to eq('abc')
      expect { EnvParser.parse('abc', as: :string, validated_by: ->(_) { false }) }.to raise_error(EnvParser::ValueNotAllowedError)
    end
  end

  it 'responds to `.register`' do
    expect(EnvParser).to respond_to(:register)
  end

  describe 'EnvParse.register' do
    it 'ceates global constants' do
      source_hash = { ABC: '123' }
      EnvParser.register(:ABC, from: source_hash, as: :integer)
      expect(ABC).to eq(123)
    end

    it 'creates module constants' do
      module Sample
      end

      source_hash = { XYZ: '456' }
      EnvParser.register(:XYZ, from: source_hash, as: :integer, within: Sample)
      expect(Sample::XYZ).to eq(456)
    end

    it 'will accept a hash keyed by variable names' do
      source_hash = { FIRST: 'first', SECOND: '99', THIRD: 'third' }
      EnvParser.register(
        FIRST: { from: source_hash, as: :string, if_unset: 'no first' },
        SECOND: { from: source_hash, as: :integer, if_unset: 'no second' },
        THIRD: { from: source_hash, as: :string, if_unset: 'no third' },
        FOURTH: { from: source_hash, as: :boolean, if_unset: 'no fourth' }
      )

      expect(FIRST).to eq('first')
      expect(SECOND).to eq(99)
      expect(THIRD).to eq('third')
      expect(FOURTH).to eq('no fourth')
    end
  end

  it 'responds to `.add_env_bindings`' do
    expect(EnvParser).to respond_to(:add_env_bindings)
  end

  describe 'EnvParser.add_env_bindings' do
    before(:context) { EnvParser.add_env_bindings }

    it 'lets ENV respond to `.parse`' do
      expect(ENV).to respond_to(:parse)
    end

    describe 'ENV.parse' do
      it 'interprets input values as ENV keys' do
        ENV['ABC'] = '123'
        expect(ENV.parse('ABC', as: :integer)).to eq(123)
        expect(ENV.parse(:ABC, as: :integer)).to eq(123)
      end
    end

    it 'lets ENV respond to `.register`' do
      expect(ENV).to respond_to(:register)
    end

    describe 'ENV.register' do
      it 'ceates global constants' do
        ENV['ABCD'] = '1234'
        ENV.register(:ABCD, as: :integer)
        expect(ABCD).to eq(1234)
      end

      it 'creates module constants' do
        module Sample
        end

        ENV['WXYZ'] = '5678'
        ENV.register(:WXYZ, as: :integer, within: Sample)
        expect(Sample::WXYZ).to eq(5678)
      end

      it 'will accept a hash keyed by variable names' do
        ENV['FIFTH'] = 'fifth'
        ENV['SIXTH'] = '99'
        ENV['SEVENTH'] = 'seventh'

        ENV.register(
          FIFTH: { as: :string, if_unset: 'no fifth' },
          SIXTH: { as: :integer, if_unset: 'no sixth' },
          SEVENTH: { as: :string, if_unset: 'no seventh' },
          EIGHTH: { as: :boolean, if_unset: 'no eighth' }
        )

        expect(FIFTH).to eq('fifth')
        expect(SIXTH).to eq(99)
        expect(SEVENTH).to eq('seventh')
        expect(EIGHTH).to eq('no eighth')
      end
    end
  end
end
