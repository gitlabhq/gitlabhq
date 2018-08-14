require 'fast_spec_helper'
require_dependency 're2'

describe Gitlab::Ci::Pipeline::Expression::Lexeme::Matches do
  let(:left) { double('left') }
  let(:right) { double('right') }

  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('=~', left, right))
        .to be_a(described_class)
    end
  end

  describe '.type' do
    it 'is an operator' do
      expect(described_class.type).to eq :operator
    end
  end

  describe '#evaluate' do
    it 'returns false when left and right do not match' do
      allow(left).to receive(:evaluate).and_return('my-string')
      allow(right).to receive(:evaluate)
        .and_return(Gitlab::UntrustedRegexp.new('something'))

      operator = described_class.new(left, right)

      expect(operator.evaluate).to eq false
    end

    it 'returns true when left and right match' do
      allow(left).to receive(:evaluate).and_return('my-awesome-string')
      allow(right).to receive(:evaluate)
        .and_return(Gitlab::UntrustedRegexp.new('awesome.string$'))

      operator = described_class.new(left, right)

      expect(operator.evaluate).to eq true
    end

    it 'supports matching against a nil value' do
      allow(left).to receive(:evaluate).and_return(nil)
      allow(right).to receive(:evaluate)
        .and_return(Gitlab::UntrustedRegexp.new('pattern'))

      operator = described_class.new(left, right)

      expect(operator.evaluate).to eq false
    end

    it 'supports multiline strings' do
      allow(left).to receive(:evaluate).and_return <<~TEXT
        My awesome contents

        My-text-string!
      TEXT

      allow(right).to receive(:evaluate)
        .and_return(Gitlab::UntrustedRegexp.new('text-string'))

      operator = described_class.new(left, right)

      expect(operator.evaluate).to eq true
    end

    it 'supports regexp flags' do
      allow(left).to receive(:evaluate).and_return <<~TEXT
        My AWESOME content
      TEXT

      allow(right).to receive(:evaluate)
        .and_return(Gitlab::UntrustedRegexp.new('(?i)awesome'))

      operator = described_class.new(left, right)

      expect(operator.evaluate).to eq true
    end
  end
end
