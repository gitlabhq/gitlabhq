require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Lexeme::Pattern do
  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('/.*/'))
        .to be_a(described_class)
    end

    it 'raises an error if pattern is invalid' do
      expect { described_class.build('/ some ( thin/i') }
        .to raise_error(Gitlab::Ci::Pipeline::Expression::Lexer::SyntaxError)
    end
  end

  describe '.type' do
    it 'is a value lexeme' do
      expect(described_class.type).to eq :value
    end
  end

  describe '.scan' do
    it 'correctly identifies a pattern token' do
      scanner = StringScanner.new('/pattern/')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('pattern')
    end

    it 'does not allow to use an empty pattern' do
      scanner = StringScanner.new(%(//))

      token = described_class.scan(scanner)

      expect(token).to be_nil
    end

    it 'support single flag' do
      scanner = StringScanner.new('/pattern/i')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('(?i)pattern')
    end

    it 'support multiple flags' do
      scanner = StringScanner.new('/pattern/im')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('(?im)pattern')
    end

    it 'ignores unsupported flags' do
      scanner = StringScanner.new('/pattern/x')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('pattern')
    end

    it 'is a eager scanner for regexp boundaries' do
      scanner = StringScanner.new('/some .* / pattern/')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('some .* ')
    end

    it 'does not match on escaped regexp boundaries' do
      scanner = StringScanner.new('/some .* \/ pattern/')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('some .* / pattern')
    end

    it 'recognizes \ as an escape character for /' do
      scanner = StringScanner.new('/some numeric \/$ pattern/')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('some numeric /$ pattern')
    end

    it 'does not recognize \ as an escape character for $' do
      scanner = StringScanner.new('/some numeric \$ pattern/')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('some numeric \$ pattern')
    end
  end

  describe '#evaluate' do
    it 'returns a regular expression' do
      regexp = described_class.new('/abc/')

      expect(regexp.evaluate).to eq Gitlab::UntrustedRegexp.new('abc')
    end

    it 'raises error if evaluated regexp is not valid' do
      allow(Gitlab::UntrustedRegexp::RubySyntax).to receive(:valid?).and_return(true)

      regexp = described_class.new('/invalid ( .*/')

      expect { regexp.evaluate }
        .to raise_error(Gitlab::Ci::Pipeline::Expression::RuntimeError)
    end
  end
end
