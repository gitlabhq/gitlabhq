require 'spec_helper'

describe GeoDynamicBackoff do
  class TestWorkerBackOff
    include Sidekiq::Worker
    include GeoDynamicBackoff

    def perform(options)
      false
    end
  end

  let(:worker) do
    TestWorkerBackOff
  end

  context 'retry strategy' do
    it 'sets a custom strategy for retrying' do
      expect(worker.sidekiq_retry_in_block).to be_a(Proc)
    end

    it 'when retry_count is in 1..30, retries with linear_backoff_strategy' do
      expect(worker).to receive(:linear_backoff_strategy)
      worker.sidekiq_retry_in_block.call(1)

      expect(worker).to receive(:linear_backoff_strategy)
      worker.sidekiq_retry_in_block.call(30)
    end

    it 'when retry_count is > 30, retries with geometric_backoff_strategy' do
      expect(worker).to receive(:geometric_backoff_strategy)
      worker.sidekiq_retry_in_block.call(31)
    end
  end

  context '.linear_backoff_strategy' do
    it 'returns rand + retry_count' do
      allow(worker).to receive(:rand).and_return(1)
      expect(worker.sidekiq_retry_in_block.call(1)).to eq(2)
    end
  end

  context '.geometric_backoff_strategy' do
    it 'when retry_count is 31 for a fixed rand()=1 returns 18' do
      allow(worker).to receive(:rand).and_return(1)
      expect(worker.sidekiq_retry_in_block.call(31)).to eq(18)
    end

    it 'when retry_count is 32 for a fixed rand()=1 returns 18' do
      allow(worker).to receive(:rand).and_return(1)
      expect(worker.sidekiq_retry_in_block.call(32)).to eq(34)
    end
  end
end
