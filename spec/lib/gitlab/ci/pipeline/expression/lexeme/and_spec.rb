# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Lexeme::And do
  let(:left) { double('left', evaluate: nil) }
  let(:right) { double('right', evaluate: nil) }

  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('&&', left, right)).to be_a(described_class)
    end

    context 'with non-evaluable operands' do
      let(:left)  { double('left') }
      let(:right) { double('right') }

      it 'raises an operator error' do
        expect { described_class.build('&&', left, right) }.to raise_error Gitlab::Ci::Pipeline::Expression::Lexeme::Operator::OperatorError
      end
    end
  end

  describe '.type' do
    it 'is an operator' do
      expect(described_class.type).to eq :logical_operator
    end
  end

  describe '.precedence' do
    it 'has a precedence' do
      expect(described_class.precedence).to be_an Integer
    end
  end

  describe '#evaluate' do
    let(:operator) { described_class.new(left, right) }

    subject { operator.evaluate }

    before do
      allow(left).to receive(:evaluate).and_return(left_value)
      allow(right).to receive(:evaluate).and_return(right_value)
    end

    context 'when left and right are truthy' do
      where(:left_value, :right_value) do
        [true, 1, 'a'].permutation(2).to_a
      end

      with_them do
        it { is_expected.to be_truthy }
        it { is_expected.to eq(right_value) }
      end
    end

    context 'when left or right is falsey' do
      where(:left_value, :right_value) do
        [true, false, nil].permutation(2).to_a
      end

      with_them do
        it { is_expected.to be_falsey }
      end
    end

    context 'when left and right are falsey' do
      where(:left_value, :right_value) do
        [false, nil].permutation(2).to_a
      end

      with_them do
        it { is_expected.to be_falsey }
        it { is_expected.to eq(left_value) }
      end
    end
  end
end
