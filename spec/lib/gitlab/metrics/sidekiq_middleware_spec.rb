require 'spec_helper'

describe Gitlab::Metrics::SidekiqMiddleware do
  let(:middleware) { described_class.new }

  describe '#call' do
    it 'tracks the transaction' do
      worker = Class.new.new

      expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:finish)

      middleware.call(worker, 'test', :test) { nil }
    end

    it 'does not track jobs of the MetricsWorker' do
      worker = MetricsWorker.new

      expect(Gitlab::Metrics::Transaction).to_not receive(:new)

      middleware.call(worker, 'test', :test) { nil }
    end
  end

  describe '#tag_worker' do
    it 'adds the worker class and action to the transaction' do
      trans  = Gitlab::Metrics::Transaction.new
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect(trans).to receive(:add_tag).with(:action, 'TestWorker#perform')

      middleware.tag_worker(trans, worker)
    end
  end
end
