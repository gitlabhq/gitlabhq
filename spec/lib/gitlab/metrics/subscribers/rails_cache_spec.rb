# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::RailsCache do
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }
  let(:subscriber) { described_class.new }
  let(:store) { 'Gitlab::CustomStore' }
  let(:store_label) { 'CustomStore' }
  let(:event) { double(:event, duration: 15.2, payload: { key: %w[a b c], store: store }) }

  context 'when receiving multiple instrumentation hits in a transaction' do
    before do
      allow(subscriber).to receive(:current_transaction)
                             .and_return(transaction)
    end

    it 'does not raise InvalidLabelSetError error' do
      expect do
        subscriber.cache_read(event)
        subscriber.cache_read_multi(event)
        subscriber.cache_write(event)
        subscriber.cache_delete(event)
        subscriber.cache_exist?(event)
        subscriber.cache_fetch_hit(event)
        subscriber.cache_generate(event)
      end.not_to raise_error
    end
  end

  describe '#cache_read' do
    it 'increments the cache_read duration' do
      expect(subscriber).to receive(:observe)
                              .with(:read, event)

      subscriber.cache_read(event)
    end

    context 'with a transaction' do
      before do
        allow(subscriber).to receive(:current_transaction)
                               .and_return(transaction)
      end

      context 'with hit event' do
        let(:event) { double(:event, duration: 15.2, payload: { hit: true }) }

        context 'when super operation is fetch' do
          let(:event) { double(:event, duration: 15.2, payload: { hit: true, super_operation: :fetch, store: store }) }

          it 'does not increment cache read miss total' do
            expect(transaction).not_to receive(:increment)
                                         .with(:gitlab_cache_misses_total, 1, { store: store_label })

            subscriber.cache_read(event)
          end
        end
      end

      context 'with miss event' do
        let(:event) { double(:event, duration: 15.2, payload: { hit: false, store: store }) }

        it 'increments the cache_read_miss total' do
          expect(transaction).to receive(:increment)
                                   .with(:gitlab_cache_misses_total, 1, { store: store_label })
          expect(transaction).to receive(:increment)
                                   .with(any_args).at_least(1) # Other calls

          subscriber.cache_read(event)
        end

        context 'when super operation is fetch' do
          let(:event) { double(:event, duration: 15.2, payload: { hit: false, super_operation: :fetch, store: store }) }

          it 'does not increment cache read miss total' do
            expect(transaction).not_to receive(:increment)
                                         .with(:gitlab_cache_misses_total, 1, { store: store_label })

            subscriber.cache_read(event)
          end
        end
      end
    end
  end

  describe '#cache_read_multi' do
    subject { subscriber.cache_read_multi(event) }

    context 'with a transaction' do
      before do
        allow(subscriber).to receive(:current_transaction)
                               .and_return(transaction)
      end

      it 'observes multi-key count' do
        expect(transaction).to receive(:observe)
                                 .with(:gitlab_cache_read_multikey_count,
                                   event.payload[:key].size,
                                   { store: store_label })

        subject
      end
    end

    context 'with no transaction' do
      it 'does not observes multi-key count' do
        expect(transaction).not_to receive(:observe)
                                 .with(:gitlab_cache_read_multikey_count, event.payload[:key].size)

        subject
      end
    end

    it 'observes read_multi duration' do
      expect(subscriber).to receive(:observe)
                              .with(:read_multi, event)

      subject
    end
  end

  describe '#cache_write' do
    it 'observes write duration' do
      expect(subscriber).to receive(:observe)
                              .with(:write, event)

      subscriber.cache_write(event)
    end
  end

  describe '#cache_delete' do
    it 'observes delete duration' do
      expect(subscriber).to receive(:observe)
                              .with(:delete, event)

      subscriber.cache_delete(event)
    end
  end

  describe '#cache_exist?' do
    it 'observes the exists duration' do
      expect(subscriber).to receive(:observe)
                              .with(:exists, event)

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
                                 .with(:gitlab_transaction_cache_read_hit_count_total, 1, { store: store_label })

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
      before do
        allow(subscriber).to receive(:current_transaction)
                               .and_return(transaction)
      end

      it 'increments the cache_fetch_miss count and cache_read_miss total' do
        expect(transaction).to receive(:increment).with(:gitlab_cache_misses_total, 1, { store: store_label })
        expect(transaction).to receive(:increment)
                                 .with(:gitlab_transaction_cache_read_miss_count_total, 1, { store: store_label })

        subscriber.cache_generate(event)
      end
    end
  end

  describe '#observe' do
    context 'without a transaction' do
      it 'returns' do
        expect(transaction).not_to receive(:increment)

        subscriber.observe(:foo, event)
      end
    end

    context 'with a transaction' do
      before do
        allow(subscriber).to receive(:current_transaction)
                               .and_return(transaction)
      end

      it 'observes cache metric' do
        expect(subscriber.send(:metric_cache_operation_duration_seconds))
          .to receive(:observe)
          .with({ operation: :delete, store: store_label }, event.duration / 1000.0)

        subscriber.observe(:delete, event)
      end

      it 'increments the operations total' do
        expect(transaction)
          .to receive(:increment)
          .with(:gitlab_cache_operations_total, 1, { operation: :delete, store: store_label })

        subscriber.observe(:delete, event)
      end
    end
  end
end
