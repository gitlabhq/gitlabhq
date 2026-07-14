# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Functions::Split, feature_category: :pipeline_composition do
  describe '.matches?' do
    it 'matches split with a single-quoted separator argument', :aggregate_failures do
      expect(described_class.matches?("split(',')")).to be_truthy
      expect(described_class.matches?("split(';')")).to be_truthy
      expect(described_class.matches?("split(':')")).to be_truthy
      expect(described_class.matches?("split(' ')")).to be_truthy
      expect(described_class.matches?("split('')")).to be_truthy
    end

    it 'does not match invalid expressions', :aggregate_failures do
      expect(described_class.matches?('split')).to be_falsey
      expect(described_class.matches?('split(",")')).to be_falsey
      expect(described_class.matches?('split(,)')).to be_falsey
      expect(described_class.matches?('unknown')).to be_falsey
    end
  end

  describe '#execute' do
    subject(:execute) { function.execute(input_value) }

    let(:function) { described_class.new("split(',')", nil) }

    context 'with a comma-separated string' do
      let(:input_value) { 'a,b,c,d,e' }

      it 'splits into an array', :aggregate_failures do
        expect(execute).to eq(%w[a b c d e])
        expect(function).to be_valid
      end
    end

    context 'with surrounding whitespace around elements' do
      let(:input_value) { 'a, b, c' }

      it 'strips whitespace from each element', :aggregate_failures do
        expect(execute).to eq(%w[a b c])
        expect(function).to be_valid
      end
    end

    context 'with empty segments' do
      let(:input_value) { 'a,,b' }

      it 'rejects empty elements', :aggregate_failures do
        expect(execute).to eq(%w[a b])
        expect(function).to be_valid
      end
    end

    context 'with a custom separator' do
      let(:function) { described_class.new("split(';')", nil) }
      let(:input_value) { 'a;b;c' }

      it 'splits on the custom separator', :aggregate_failures do
        expect(execute).to eq(%w[a b c])
        expect(function).to be_valid
      end
    end

    context 'with a single value (no separator in string)' do
      let(:input_value) { 'only-one' }

      it 'returns a one-element array', :aggregate_failures do
        expect(execute).to eq(['only-one'])
        expect(function).to be_valid
      end
    end

    context 'when the input is not a string' do
      let(:input_value) { 100 }

      it 'returns an error', :aggregate_failures do
        expect(execute).to be_nil
        expect(function).not_to be_valid
        expect(function.errors).to contain_exactly(
          'error in `split` function: invalid input type: split can only be used with string inputs'
        )
      end
    end

    context 'when the input is nil' do
      let(:input_value) { nil }

      it 'returns an error', :aggregate_failures do
        expect(execute).to be_nil
        expect(function).not_to be_valid
        expect(function.errors).to contain_exactly(
          'error in `split` function: invalid input type: split can only be used with string inputs'
        )
      end
    end

    context 'with an empty string input' do
      let(:input_value) { '' }

      it 'returns an empty array', :aggregate_failures do
        expect(execute).to eq([])
        expect(function).to be_valid
      end
    end

    context 'with an empty separator' do
      let(:function) { described_class.new("split('')", nil) }
      let(:input_value) { 'abc' }

      it 'returns an error', :aggregate_failures do
        expect(execute).to be_nil
        expect(function).not_to be_valid
        expect(function.errors).to contain_exactly(
          'error in `split` function: invalid argument: separator cannot be empty'
        )
      end
    end
  end
end
