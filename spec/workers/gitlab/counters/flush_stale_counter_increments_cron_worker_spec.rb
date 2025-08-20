# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Counters::FlushStaleCounterIncrementsCronWorker, feature_category: :continuous_integration do
  describe '#perform' do
    subject(:worker) { described_class.new }

    context 'when we are on gitlab.com' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it 'calls FlushStaleCounterIncrementsWorker.perform_with_capacity' do
        # Since we are in the removal process of the worker, we'll use this not here
        # to satisfy undercoverage
        expect(::Gitlab::Counters::FlushStaleCounterIncrementsWorker).not_to receive(:perform_with_capacity)
        worker.perform
      end
    end

    context 'when we are not on gitlab.com' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      end

      it 'does not call FlushStaleCounterIncrementsWorker.perform_with_capacity' do
        expect(::Gitlab::Counters::FlushStaleCounterIncrementsWorker).not_to receive(:perform_with_capacity)
        worker.perform
      end
    end
  end
end
