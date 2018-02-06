require 'spec_helper'

describe Gitlab::SidekiqVersioning, :sidekiq, :redis do
  let(:foo_worker) do
    Class.new do
      def self.name
        'FooWorker'
      end

      include ApplicationWorker
    end
  end

  let(:bar_worker) do
    Class.new do
      def self.name
        'BarWorker'
      end

      include ApplicationWorker
    end
  end

  before do
    allow(Gitlab::SidekiqConfig).to receive(:workers).and_return([foo_worker, bar_worker])
    allow(Gitlab::SidekiqConfig).to receive(:worker_queues).and_return([foo_worker.queue, bar_worker.queue])
  end

  describe '.install!' do
    it 'prepends SidekiqVersioning::Manager into Sidekiq::Manager' do
      described_class.install!

      expect(Sidekiq::Manager).to include(Gitlab::SidekiqVersioning::Manager)
    end

    it 'registers all versionless and versioned queues with Redis' do
      described_class.install!

      queues = Sidekiq::Queue.all.map(&:name)
      expect(queues).to include('foo')
      expect(queues).to include('bar')
    end
  end
end
