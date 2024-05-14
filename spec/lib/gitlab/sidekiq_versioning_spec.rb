# frozen_string_literal: true

require 'spec_helper'

# allow_unrouted_sidekiq_calls as this is run on every startup, so shard awareness is not needed
RSpec.describe Gitlab::SidekiqVersioning, :clean_gitlab_redis_queues, :allow_unrouted_sidekiq_calls do
  before do
    allow(Gitlab::SidekiqConfig).to receive(:routing_queues).and_return(%w[foo bar])
  end

  subject(:queues) { Sidekiq::Queue.all.map(&:name) }

  describe '.install!' do
    it 'registers all versionless and versioned queues with Redis' do
      described_class.install!

      expect(queues).to include('foo')
      expect(queues).to include('bar')
    end

    context 'when some queues outside routing rules were already registered' do
      before do
        Sidekiq.redis do |conn|
          conn.sadd('queues', 'a', 'b', 'c', 'foo')
        end
      end

      it 'removes the queues outside routing rules' do
        described_class.install!

        expect(queues).not_to include('a')
        expect(queues).not_to include('b')
        expect(queues).not_to include('c')
      end

      it 'registers all queues in routing rules' do
        described_class.install!

        expect(queues).to include('foo')
        expect(queues).to include('bar')
      end
    end
  end
end
