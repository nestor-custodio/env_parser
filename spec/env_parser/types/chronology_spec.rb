RSpec.describe EnvParser do
  describe 'chronology types' do
    it 'can parse dates' do
      expect(EnvParser.parse(nil, as: :date)).to eq(nil)
      expect(EnvParser.parse('', as: :date)).to eq(nil)

      expect(EnvParser.parse('11/05/1955 06:00', as: :date)).to eq(Date.new(1955, 11, 5))
      expect(EnvParser.parse('11/12/1955 22:04', as: :date)).to eq(Date.new(1955, 11, 12))
      expect(EnvParser.parse('1885-09-02 08:00', as: :date)).to eq(Date.new(1885, 9, 2))
      expect(EnvParser.parse('1885-09-07', as: :date)).to eq(Date.new(1885, 9, 7))

      expect(EnvParser.parse('tomorrow', as: :date)).to eq(Date.today + 1.day)

      expect { EnvParser.parse('not a date', as: :date) }.to raise_error(EnvParser::ValueNotConvertibleError)
      expect { EnvParser.parse('2018-02-29', as: :date) }.to raise_error(EnvParser::ValueNotConvertibleError)
    end

    it 'can parse times' do
      %i[time datetime].each do |type|
        expect(EnvParser.parse(nil, as: type)).to eq(nil)
        expect(EnvParser.parse('', as: type)).to eq(nil)

        expect(EnvParser.parse('11/05/1955 06:00', as: type)).to eq(Time.new(1955, 11, 5, 6, 0))
        expect(EnvParser.parse('11/12/1955 22:04', as: type)).to eq(Time.new(1955, 11, 12, 22, 4))
        expect(EnvParser.parse('1885-09-02 08:00', as: type)).to eq(Time.new(1885, 9, 2, 8, 0))
        expect(EnvParser.parse('1885-09-07', as: type)).to eq(Time.new(1885, 9, 7))

        expect(EnvParser.parse('today at 07:15', as: type)).to eq(Date.today + 7.hours + 15.minutes)

        expect { EnvParser.parse('not a date/time', as: type) }.to raise_error(EnvParser::ValueNotConvertibleError)
        expect { EnvParser.parse('today at 33:25', as: type) }.to raise_error(EnvParser::ValueNotConvertibleError)
      end
    end

    it 'can parse durations' do
      expect(EnvParser.parse(nil, as: :duration)).to eq(nil)
      expect(EnvParser.parse('', as: :duration)).to eq(nil)

      expect(EnvParser.parse('12 seconds', as: :duration)).to eq(12)
      expect(EnvParser.parse('5 minutes', as: :duration)).to eq(5 * 60)
      expect(EnvParser.parse('24 hours', as: :duration)).to eq(24 * 60 * 60)
      expect(EnvParser.parse('1.5 days', as: :duration)).to eq(1.5 * 24 * 60 * 60)
      expect(EnvParser.parse('1 day', as: :duration)).to eq(24 * 60 * 60)
      expect(EnvParser.parse('2 weeks, 1 day', as: :duration)).to eq((2 * 7 * 24 * 60 * 60) + (24 * 60 * 60))
      expect(EnvParser.parse('P2W1DT3H', as: :duration)).to eq((2 * 7 * 24 * 60 * 60) + (24 * 60 * 60) + (3 * 60 * 60))

      expect { EnvParser.parse('not a duration', as: :duration) }.to raise_error(EnvParser::ValueNotConvertibleError)
      expect { EnvParser.parse('37 dinglebops', as: :duration) }.to raise_error(EnvParser::ValueNotConvertibleError)
    end
  end
end
