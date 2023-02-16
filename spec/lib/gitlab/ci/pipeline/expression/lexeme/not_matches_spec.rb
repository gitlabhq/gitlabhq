# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Lexeme::NotMatches, feature_category: :continuous_integration do
  include StubFeatureFlags

  let(:left) { double('left') }
  let(:right) { double('right') }

  describe '.build' do
    context 'with non-evaluable operands' do
      it 'creates a new instance of the token' do
        expect { described_class.build('!~', left, right) }
          .to raise_error Gitlab::Ci::Pipeline::Expression::Lexeme::Operator::OperatorError
      end
    end

    context 'with evaluable operands' do
      it 'creates a new instance of the token' do
        allow(left).to receive(:evaluate).and_return('my-string')
        allow(right).to receive(:evaluate).and_return('my-string')

        expect(described_class.build('!~', left, right))
          .to be_a(described_class)
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

    context 'when left and right do not match' do
      let(:left_value)  { 'my-string' }
      let(:right_value) { Gitlab::UntrustedRegexp.new('something') }

      it { is_expected.to eq(true) }
    end

    context 'when left and right match' do
      let(:left_value)  { 'my-awesome-string' }
      let(:right_value) { Gitlab::UntrustedRegexp.new('awesome.string$') }

      it { is_expected.to eq(false) }
    end

    context 'when left is nil' do
      let(:left_value)  { nil }
      let(:right_value) { Gitlab::UntrustedRegexp.new('pattern') }

      it { is_expected.to eq(true) }
    end

    context 'when right is nil' do
      let(:left_value)  { 'my-awesome-string' }
      let(:right_value) { nil }

      it { is_expected.to eq(true) }
    end

    context 'when left and right are nil' do
      let(:left_value)  { nil }
      let(:right_value) { nil }

      it { is_expected.to eq(true) }
    end

    context 'when left is an empty string' do
      let(:left_value)  { '' }
      let(:right_value) { Gitlab::UntrustedRegexp.new('pattern') }

      it { is_expected.to eq(true) }
    end

    context 'when left and right are empty strings' do
      let(:left_value)  { '' }
      let(:right_value) { Gitlab::UntrustedRegexp.new('') }

      it { is_expected.to eq(false) }
    end

    context 'when left is a multiline string and matches right' do
      let(:left_value) do
        <<~TEXT
          My awesome contents

          My-text-string!
        TEXT
      end

      let(:right_value) { Gitlab::UntrustedRegexp.new('text-string') }

      it { is_expected.to eq(false) }
    end

    context 'when left is a multiline string and does not match right' do
      let(:left_value) do
        <<~TEXT
          My awesome contents

          My-terrible-string!
        TEXT
      end

      let(:right_value) { Gitlab::UntrustedRegexp.new('text-string') }

      it { is_expected.to eq(true) }
    end

    context 'when a matching pattern uses regex flags' do
      let(:left_value) do
        <<~TEXT
          My AWESOME content
        TEXT
      end

      let(:right_value) { Gitlab::UntrustedRegexp.new('(?i)awesome') }

      it { is_expected.to eq(false) }
    end

    context 'when a non-matching pattern uses regex flags' do
      let(:left_value) do
        <<~TEXT
          My AWESOME content
        TEXT
      end

      let(:right_value) { Gitlab::UntrustedRegexp.new('(?i)terrible') }

      it { is_expected.to eq(true) }
    end

    context 'when right value is a regexp string' do
      let(:right_value) { '/^ab.*/' }

      context 'when matching' do
        let(:left_value) { 'abcde' }

        it { is_expected.to eq(false) }
      end

      context 'when not matching' do
        let(:left_value) { 'dfg' }

        it { is_expected.to eq(true) }
      end
    end
  end
end
