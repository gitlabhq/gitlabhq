# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::PrimaryKeyBatchingStrategy, '#next_batch' do
  let(:batching_strategy) { described_class.new }

  let_it_be(:event1) { create(:event) }
  let_it_be(:event2) { create(:event) }
  let_it_be(:event3) { create(:event) }
  let_it_be(:event4) { create(:event) }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:events, :id, batch_min_value: event1.id, batch_size: 3)

      expect(batch_bounds).to eq([event1.id, event3.id])
    end
  end

  context 'when additional batches remain' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:events, :id, batch_min_value: event2.id, batch_size: 3)

      expect(batch_bounds).to eq([event2.id, event4.id])
    end
  end

  context 'when on the final batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(:events, :id, batch_min_value: event4.id, batch_size: 3)

      expect(batch_bounds).to eq([event4.id, event4.id])
    end
  end

  context 'when no additional batches remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(:events, :id, batch_min_value: event4.id + 1, batch_size: 1)

      expect(batch_bounds).to be_nil
    end
  end
end
