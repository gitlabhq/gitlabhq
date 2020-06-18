# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::SidekiqMiddleware do
  let(:middleware) { described_class.new }
  let(:message) { { 'args' => ['test'], 'enqueued_at' => Time.new(2016, 6, 23, 6, 59).to_f } }

  describe '#call' do
    it 'tracks the transaction' do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect_next_instance_of(Gitlab::Metrics::BackgroundTransaction) do |transaction|
        expect(transaction).to receive(:set).with(:sidekiq_queue_duration, instance_of(Float))
        expect(transaction).to receive(:increment).with(:db_count, 1)
      end

      middleware.call(worker, message, :test) do
        ActiveRecord::Base.connection.execute('SELECT pg_sleep(0.1);')
      end

      expect(message).to include(:db_count, :db_write_count, :db_cached_count)
    end

    it 'tracks the transaction (for messages without `enqueued_at`)', :aggregate_failures do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect(Gitlab::Metrics::BackgroundTransaction).to receive(:new)
        .with(worker.class)
        .and_call_original

      expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:set)
        .with(:sidekiq_queue_duration, instance_of(Float))

      middleware.call(worker, {}, :test) { nil }
    end

    it 'tracks any raised exceptions', :aggregate_failures do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:run).and_raise(RuntimeError)

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:add_event).with(:sidekiq_exception)

      expect { middleware.call(worker, message, :test) }
        .to raise_error(RuntimeError)

      expect(message).to include(:db_count, :db_write_count, :db_cached_count)
    end
  end
end
