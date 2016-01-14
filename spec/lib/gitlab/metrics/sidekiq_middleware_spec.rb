require 'spec_helper'

describe Gitlab::Metrics::SidekiqMiddleware do
  let(:middleware) { described_class.new }

  describe '#call' do
    it 'tracks the transaction' do
      worker = double(:worker, class: double(:class, name: 'TestWorker'))

      expect(Gitlab::Metrics::Transaction).to receive(:new).
        with('TestWorker#perform').
        and_call_original

      expect_any_instance_of(Gitlab::Metrics::Transaction).to receive(:finish)

      middleware.call(worker, 'test', :test) { nil }
    end
  end
end
