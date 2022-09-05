# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::DeepSize do
  let(:data) do
    {
      a: [1, 2, 3],
      b: {
        c: [4, 5],
        d: [
          { e: [[6], [7]] }
        ]
      }
    }
  end

  let(:max_size) { 1.kilobyte }
  let(:max_depth) { 10 }

  subject(:deep_size) { described_class.new(data, max_size: max_size, max_depth: max_depth) }

  it { expect(described_class::DEFAULT_MAX_SIZE).to eq(1.megabyte) }
  it { expect(described_class::DEFAULT_MAX_DEPTH).to eq(100) }

  describe '#initialize' do
    context 'when max_size is nil' do
      let(:max_size) { nil }

      it 'sets max_size to DEFAULT_MAX_SIZE' do
        expect(subject.instance_variable_get(:@max_size)).to eq(described_class::DEFAULT_MAX_SIZE)
      end
    end

    context 'when max_depth is nil' do
      let(:max_depth) { nil }

      it 'sets max_depth to DEFAULT_MAX_DEPTH' do
        expect(subject.instance_variable_get(:@max_depth)).to eq(described_class::DEFAULT_MAX_DEPTH)
      end
    end
  end

  describe '#valid?' do
    context 'when data within size and depth limits' do
      it { is_expected.to be_valid }
    end

    context 'when data not within size limit' do
      let(:max_size) { 200.bytes }

      it { is_expected.not_to be_valid }
    end

    context 'when data not within depth limit' do
      let(:max_depth) { 2 }

      it { is_expected.not_to be_valid }
    end
  end
end
