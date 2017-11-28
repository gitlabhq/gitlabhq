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

      version 2
    end
  end

  before do
    allow(Gitlab::SidekiqConfig).to receive(:workers).and_return([foo_worker, bar_worker])
    allow(Gitlab::SidekiqConfig).to receive(:worker_queues).and_return([foo_worker.queue, bar_worker.queue])
    allow(Gitlab::SidekiqConfig).to receive(:workers_by_queue).and_return({ 'foo' => foo_worker, 'bar' => bar_worker })
    allow(Gitlab::SidekiqConfig).to receive(:redis_queues).and_return(%w[foo foo:v1 bar:v1 bar:v3 bar:v])
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
      expect(queues).to include('foo:v0')
      expect(queues).to include('bar')
      expect(queues).to include('bar:v2')
    end
  end

  describe '.queues_with_versions' do
    it 'returns versionless and versioned queues for the queues in question' do
      expect(described_class.queues_with_versions(%w[foo bar baz])).to match_array(%w[foo foo:v0 bar bar:v1 bar:v2 baz])
    end
  end

  describe '.queue_versions' do
    it 'returns versions for the queue in question' do
      expect(described_class.queue_versions('bar')).to match_array([1, 3])
    end
  end
end
