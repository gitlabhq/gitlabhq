require 'spec_helper'

describe Gitlab::Metrics::SidekiqMiddleware do
  let(:middleware) { described_class.new }
  let(:message) { { 'args' => ['test'], 'enqueued_at' => Time.new(2016, 6, 23, 6, 59).to_f } }

  def run(worker, message)
    expect(Gitlab::Metrics::Transaction).to receive(:new)
      .with('TestWorker#perform')
      .and_call_original

    expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:set)
      .with(:sidekiq_queue_duration, instance_of(Float))

    expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:finish)

    middleware.call(worker, message, :test) { nil }
  end

  describe '#call' do
    it 'tracks the transaction' do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      run(worker, message)
    end

    it 'tracks the transaction (for messages without `enqueued_at`)' do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      run(worker, {})
    end

    it 'tracks any raised exceptions' do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:run).and_raise(RuntimeError)

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:add_event).with(:sidekiq_exception)

      expect_any_instance_of(Gitlab::Metrics::Transaction)
        .to receive(:finish)

      expect { middleware.call(worker, message, :test) }
        .to raise_error(RuntimeError)
    end

    it 'tags the metrics accordingly' do
      tags = { one: 1, two: 2 }
      worker = double(:worker, class: double(:class, name: 'TestWorker'))
      allow(worker).to receive(:metrics_tags).and_return(tags)

      tags.each do |tag, value|
        expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:add_tag)
          .with(tag, value)
      end

      run(worker, message)
    end
  end
end
