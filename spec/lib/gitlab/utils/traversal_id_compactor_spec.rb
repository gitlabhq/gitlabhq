# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::TraversalIdCompactor, feature_category: :secrets_management do
  let(:traversal_ids) do
    [
      [1, 21],
      [1, 2, 3],
      [1, 2, 4],
      [1, 2, 5],
      [1, 2, 12, 13],
      [1, 6, 7],
      [1, 6, 8],
      [9, 10, 11]
    ]
  end

  let(:compactor) { described_class }

  describe '#compact' do
    it 'compacts the array of traversal_ids using compact_once two times until the limit is reached' do
      expect(compactor).to receive(:compact_once).twice.and_call_original

      result = compactor.compact(traversal_ids, 4)

      expect(result).to eq([
        [1, 21],
        [1, 2],
        [1, 6],
        [9, 10, 11]
      ])
    end

    it 'compacts the array of traversal_ids using compact_once three times until the limit is reached' do
      expect(compactor).to receive(:compact_once).exactly(3).times.and_call_original

      result = compactor.compact(traversal_ids, 3)

      expect(result).to eq([
        [1],
        [9, 10, 11]
      ])
    end

    it 'compacts the array of traversal_ids using compact_once one time to reach the limit' do
      traversal_ids = [
        [1, 2],
        [1, 3],
        [1, 4],
        [5, 6],
        [6, 7]
      ]

      expect(compactor).to receive(:compact_once).once.and_call_original

      result = compactor.compact(traversal_ids, 3)

      expect(result).to eq([
        [1],
        [5, 6],
        [6, 7]
      ])
    end

    it 'raises when the compaction limit can not be achieved' do
      expect do
        compactor.compact(traversal_ids, 1)
      end.to raise_error(described_class::CompactionLimitCannotBeAchievedError)
    end
  end

  describe '#compact_once' do
    it 'compacts the one most common namespace path and returns the newly compacted array of traversal_ids' do
      result = compactor.compact_once(traversal_ids)

      expect(result).to eq([
        [1, 21],
        [1, 2],
        [1, 6, 7],
        [1, 6, 8],
        [9, 10, 11]
      ])
    end
  end

  describe '#validate!' do
    it 'returns true when the compacted results are valid' do
      result = compactor.compact(traversal_ids, 4)
      expect(compactor.validate!(traversal_ids, result)).to be true
    end

    it 'raises a RedundantCompactionEntry error when redundant entries are found' do
      result = compactor.compact(traversal_ids, 4)
      result << [1, 2, 3]
      expect do
        compactor.validate!(traversal_ids, result)
      end.to raise_error(described_class::RedundantCompactionEntry)
    end

    it 'raises an UnexpectedCompactionEntry error when an unexpected entry is found' do
      result = compactor.compact(traversal_ids, 4)
      result << [1, 3, 4]
      expect do
        compactor.validate!(traversal_ids, result)
      end.to raise_error(described_class::UnexpectedCompactionEntry)
    end
  end
end
