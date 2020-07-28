# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::SidekiqMiddleware do
  let(:middleware) { described_class.new }
  let(:message) { { 'args' => ['test'], 'enqueued_at' => Time.new(2016, 6, 23, 6, 59).to_f } }

  describe '#call' do
    it 'tracks the transaction' do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect_next_instance_of(Gitlab::Metrics::BackgroundTransaction) do |transaction|
        expect(transaction).to receive(:set).with(:gitlab_transaction_sidekiq_queue_duration_total, instance_of(Float))
        expect(transaction).to receive(:increment).with(:gitlab_transaction_db_count_total, 1)
      end

      middleware.call(worker, message, :test) do
        ActiveRecord::Base.connection.execute('SELECT pg_sleep(0.1);')
      end
    end

    it 'prevents database counters from leaking to the next transaction' do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      2.times do
        Gitlab::WithRequestStore.with_request_store do
          middleware.call(worker, message, :test) do
            ActiveRecord::Base.connection.execute('SELECT pg_sleep(0.1);')
          end
        end
      end

      expect(message).to include(db_count: 1, db_write_count: 0, db_cached_count: 0)
    end

    it 'tracks the transaction (for messages without `enqueued_at`)', :aggregate_failures do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect(Gitlab::Metrics::BackgroundTransaction).to receive(:new)
        .with(worker.class)
        .and_call_original

      expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:set)
        .with(:gitlab_transaction_sidekiq_queue_duration_total, instance_of(Float))

      middleware.call(worker, {}, :test) { nil }
    end

    it 'tracks any raised exceptions', :aggregate_failures, :request_store do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:add_event).with(:sidekiq_exception)

      expect do
        middleware.call(worker, message, :test) do
          ActiveRecord::Base.connection.execute('SELECT pg_sleep(0.1);')
          raise RuntimeError
        end
      end.to raise_error(RuntimeError)

      expect(message).to include(db_count: 1, db_write_count: 0, db_cached_count: 0)
    end
  end
end
