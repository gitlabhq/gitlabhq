require 'spec_helper'

describe Gitlab::Metrics::SidekiqMiddleware do
  let(:middleware) { described_class.new }
  let(:message) { { 'args' => ['test'], 'enqueued_at' => Time.new(2016, 6, 23, 6, 59).to_f } }

  def run(worker, message)
    expect(Gitlab::Metrics::BackgroundTransaction).to receive(:new)
      .with(worker.class)
      .and_call_original

    expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:set)
      .with(:sidekiq_queue_duration, instance_of(Float))

    expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:finish)

    middleware.call(worker, message, :test) { nil }
  end

  describe '#call' do
    let(:test_worker_class) { double(:class, name: 'TestWorker') }
    let(:worker) { double(:worker, class: test_worker_class) }

    it 'reports correct action based on worker class' do

    end

    it 'tracks the transaction' do
      run(worker, message)
    end

    it 'tracks the transaction (for messages without `enqueued_at`)' do
      run(worker, {})
    end

    it 'tracks any raised exceptions' do
      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:run).and_raise(RuntimeError)

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:add_event).with(:sidekiq_exception)

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:finish)

      expect { middleware.call(worker, message, :test) }
        .to raise_error(RuntimeError)
    end
  end
end
