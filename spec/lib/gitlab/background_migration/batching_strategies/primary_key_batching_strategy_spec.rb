# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy, '#next_batch' do
  let(:batching_strategy) { described_class.new }
  let(:namespaces) { table(:namespaces) }

  let!(:namespace1) { namespaces.create!(name: 'batchtest1', path: 'batch-test1') }
  let!(:namespace2) { namespaces.create!(name: 'batchtest2', path: 'batch-test2') }
  let!(:namespace3) { namespaces.create!(name: 'batchtest3', path: 'batch-test3') }
  let!(:namespace4) { namespaces.create!(name: 'batchtest4', path: 'batch-test4') }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace1.id, batch_size: 3)

      expect(batch_bounds).to eq([namespace1.id, namespace3.id])
    end
  end

  context 'when additional batches remain' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace2.id, batch_size: 3)

      expect(batch_bounds).to eq([namespace2.id, namespace4.id])
    end
  end

  context 'when on the final batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace4.id, batch_size: 3)

      expect(batch_bounds).to eq([namespace4.id, namespace4.id])
    end
  end

  context 'when no additional batches remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(:namespaces, :id, batch_min_value: namespace4.id + 1, batch_size: 1)

      expect(batch_bounds).to be_nil
    end
  end
end
