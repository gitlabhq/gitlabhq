# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Utils::DeepSize do
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
  let(:deep_size) { described_class.new(data, max_size: max_size, max_depth: max_depth) }

  describe '#evaluate' do
    context 'when data within size and depth limits' do
      it 'returns true' do
        expect(deep_size).to be_valid
      end
    end

    context 'when data not within size limit' do
      let(:max_size) { 200.bytes }

      it 'returns false' do
        expect(deep_size).not_to be_valid
      end
    end

    context 'when data not within depth limit' do
      let(:max_depth) { 2 }

      it 'returns false' do
        expect(deep_size).not_to be_valid
      end
    end
  end

  describe '.human_default_max_size' do
    it 'returns 1 MB' do
      expect(described_class.human_default_max_size).to eq('1 MB')
    end
  end
end
