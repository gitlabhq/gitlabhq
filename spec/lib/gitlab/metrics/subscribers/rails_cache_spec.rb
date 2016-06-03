require 'spec_helper'

describe Gitlab::Metrics::Subscribers::RailsCache do
  let(:transaction) { Gitlab::Metrics::Transaction.new }
  let(:subscriber) { described_class.new }

  let(:event) { double(:event, duration: 15.2) }

  describe '#cache_read' do
    it 'increments the cache_read duration' do
      expect(subscriber).to receive(:increment).
        with(:cache_read_duration, event.duration)

      subscriber.cache_read(event)
    end
  end

  describe '#cache_write' do
    it 'increments the cache_write duration' do
      expect(subscriber).to receive(:increment).
        with(:cache_write_duration, event.duration)

      subscriber.cache_write(event)
    end
  end

  describe '#cache_delete' do
    it 'increments the cache_delete duration' do
      expect(subscriber).to receive(:increment).
        with(:cache_delete_duration, event.duration)

      subscriber.cache_delete(event)
    end
  end

  describe '#cache_exist?' do
    it 'increments the cache_exists duration' do
      expect(subscriber).to receive(:increment).
        with(:cache_exists_duration, event.duration)

      subscriber.cache_exist?(event)
    end
  end

  describe '#increment' do
    context 'without a transaction' do
      it 'returns' do
        expect(transaction).not_to receive(:increment)

        subscriber.increment(:foo, 15.2)
      end
    end

    context 'with a transaction' do
      before do
        allow(subscriber).to receive(:current_transaction).
          and_return(transaction)
      end

      it 'increments the total and specific cache duration' do
        expect(transaction).to receive(:increment).
          with(:cache_duration, event.duration)

        expect(transaction).to receive(:increment).
          with(:cache_delete_duration, event.duration)

        subscriber.increment(:cache_delete_duration, event.duration)
      end
    end
  end
end
