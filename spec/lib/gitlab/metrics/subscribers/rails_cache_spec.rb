require 'spec_helper'

describe Gitlab::Metrics::Subscribers::RailsCache do
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }
  let(:subscriber) { described_class.new }

  let(:event) { double(:event, duration: 15.2) }

  describe '#cache_read' do
    it 'increments the cache_read duration' do
      expect(subscriber).to receive(:observe)
                              .with(:read, event.duration)

      subscriber.cache_read(event)
    end

    context 'with a transaction' do
      before do
        allow(subscriber).to receive(:current_transaction)
                               .and_return(transaction)
      end

      context 'with hit event' do
        let(:event) { double(:event, duration: 15.2, payload: { hit: true }) }

        it 'increments the cache_read_hit count' do
          expect(transaction).to receive(:increment)
                                   .with(:cache_read_hit_count, 1, false)
          expect(transaction).to receive(:increment)
                                   .with(any_args).at_least(1) # Other calls

          subscriber.cache_read(event)
        end

        context 'when super operation is fetch' do
          let(:event) { double(:event, duration: 15.2, payload: { hit: true, super_operation: :fetch }) }

          it 'does not increment cache read miss' do
            expect(transaction).not_to receive(:increment)
                                         .with(:cache_read_hit_count, 1)

            subscriber.cache_read(event)
          end
        end
      end

      context 'with miss event' do
        let(:event) { double(:event, duration: 15.2, payload: { hit: false }) }

        it 'increments the cache_read_miss count' do
          expect(transaction).to receive(:increment)
                                   .with(:cache_read_miss_count, 1, false)
          expect(transaction).to receive(:increment)
                                   .with(any_args).at_least(1) # Other calls

          subscriber.cache_read(event)
        end

        it 'increments the cache_read_miss total' do
          expect(subscriber.send(:metric_cache_misses_total)).to receive(:increment).with({})

          subscriber.cache_read(event)
        end

        context 'when super operation is fetch' do
          let(:event) { double(:event, duration: 15.2, payload: { hit: false, super_operation: :fetch }) }

          it 'does not increment cache read miss' do
            expect(transaction).not_to receive(:increment)
                                         .with(:cache_read_miss_count, 1)

            subscriber.cache_read(event)
          end

          it 'does not increment cache_read_miss total' do
            expect(subscriber.send(:metric_cache_misses_total)).not_to receive(:increment).with({})

            subscriber.cache_read(event)
          end
        end
      end
    end
  end

  describe '#cache_write' do
    it 'observes write duration' do
      expect(subscriber).to receive(:observe)
                              .with(:write, event.duration)

      subscriber.cache_write(event)
    end
  end

  describe '#cache_delete' do
    it 'observes delete duration' do
      expect(subscriber).to receive(:observe)
                              .with(:delete, event.duration)

      subscriber.cache_delete(event)
    end
  end

  describe '#cache_exist?' do
    it 'observes the exists duration' do
      expect(subscriber).to receive(:observe)
                              .with(:exists, event.duration)

      subscriber.cache_exist?(event)
    end
  end

  describe '#cache_fetch_hit' do
    context 'without a transaction' do
      it 'returns' do
        expect(transaction).not_to receive(:increment)

        subscriber.cache_fetch_hit(event)
      end
    end

    context 'with a transaction' do
      before do
        allow(subscriber).to receive(:current_transaction)
                               .and_return(transaction)
      end

      it 'increments the cache_read_hit count' do
        expect(transaction).to receive(:increment)
                                 .with(:cache_read_hit_count, 1)

        subscriber.cache_fetch_hit(event)
      end
    end
  end

  describe '#cache_generate' do
    context 'without a transaction' do
      it 'returns' do
        expect(transaction).not_to receive(:increment)

        subscriber.cache_generate(event)
      end
    end

    context 'with a transaction' do
      let(:metric_cache_misses_total) { double('metric_cache_misses_total', increment: nil) }

      before do
        allow(subscriber).to receive(:metric_cache_misses_total).and_return(metric_cache_misses_total)
        allow(subscriber).to receive(:current_transaction)
                               .and_return(transaction)
      end

      it 'increments the cache_fetch_miss count' do
        expect(transaction).to receive(:increment)
                                 .with(:cache_read_miss_count, 1)

        subscriber.cache_generate(event)
      end

      it 'increments the cache_read_miss total' do
        subscriber.cache_generate(event)

        expect(metric_cache_misses_total).to have_received(:increment).with({})
      end
    end
  end

  describe '#observe' do
    context 'without a transaction' do
      it 'returns' do
        expect(transaction).not_to receive(:increment)

        subscriber.observe(:foo, 15.2)
      end
    end

    context 'with a transaction' do
      before do
        allow(subscriber).to receive(:current_transaction)
                               .and_return(transaction)
      end

      it 'increments the total and specific cache duration' do
        expect(transaction).to receive(:increment)
                                 .with(:cache_duration, event.duration, false)

        expect(transaction).to receive(:increment)
                                 .with(:cache_count, 1, false)

        expect(transaction).to receive(:increment)
                                 .with(:cache_delete_duration, event.duration, false)

        expect(transaction).to receive(:increment)
                                 .with(:cache_delete_count, 1, false)

        subscriber.observe(:delete, event.duration)
      end

      it 'observes cache metric' do
        expect(subscriber.send(:metric_cache_operation_duration_seconds))
          .to receive(:observe)
                .with(transaction.labels.merge(operation: :delete), event.duration / 1000.0)

        subscriber.observe(:delete, event.duration)
      end
    end
  end
end
