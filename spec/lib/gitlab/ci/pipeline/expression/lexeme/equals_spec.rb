require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Lexeme::Equals do
  let(:left) { double('left') }
  let(:right) { double('right') }

  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('==', left, right))
        .to be_a(described_class)
    end
  end

  describe '.type' do
    it 'is an operator' do
      expect(described_class.type).to eq :operator
    end
  end

  describe '#evaluate' do
    it 'returns false when left and right are not equal' do
      allow(left).to receive(:evaluate).and_return(1)
      allow(right).to receive(:evaluate).and_return(2)

      operator = described_class.new(left, right)

      expect(operator.evaluate(VARIABLE: 3)).to eq false
    end

    it 'returns true when left and right are equal' do
      allow(left).to receive(:evaluate).and_return(1)
      allow(right).to receive(:evaluate).and_return(1)

      operator = described_class.new(left, right)

      expect(operator.evaluate(VARIABLE: 3)).to eq true
    end
  end
end
