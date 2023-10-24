# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::SidekiqScheduledEnq, :clean_gitlab_redis_queues, feature_category: :scalability do
  describe '#enqueue_jobs' do
    let_it_be(:payload) { {} }

    before do
      allow(Sidekiq).to receive(:load_json).and_return(payload)

      # stub data in both namespaces
      Gitlab::Redis::Queues.with { |c| c.zadd('resque:gitlab:schedule', 100, 'dummy') }
      Gitlab::Redis::Queues.with { |c| c.zadd('schedule', 100, 'dummy') }
    end

    subject { Sidekiq::Scheduled::Enq.new.enqueue_jobs }

    it 'polls both namespaces by default' do
      expect(Sidekiq::Client).to receive(:push).with(payload).twice

      subject

      Sidekiq.redis do |conn|
        expect(conn.zcard('schedule')).to eq(0)
      end

      Gitlab::Redis::Queues.with do |conn|
        expect(conn.zcard('resque:gitlab:schedule')).to eq(0)
      end
    end

    context 'when SIDEKIQ_ENABLE_DUAL_NAMESPACE_POLLING is disabled' do
      before do
        stub_env('SIDEKIQ_ENABLE_DUAL_NAMESPACE_POLLING', 'false')
      end

      it 'polls via Sidekiq.redis only' do
        expect(Sidekiq::Client).to receive(:push).with(payload).once

        subject

        Sidekiq.redis do |conn|
          expect(conn.zcard('schedule')).to eq(0)
        end

        Gitlab::Redis::Queues.with do |conn|
          expect(conn.zcard('resque:gitlab:schedule')).to eq(1)
        end
      end
    end

    context 'when SIDEKIQ_ENABLE_DUAL_NAMESPACE_POLLING is enabled' do
      before do
        stub_env('SIDEKIQ_ENABLE_DUAL_NAMESPACE_POLLING', 'true')
      end

      it 'polls both sets' do
        expect(Sidekiq::Client).to receive(:push).with(payload).twice

        subject

        Sidekiq.redis do |conn|
          expect(conn.zcard('schedule')).to eq(0)
        end

        Gitlab::Redis::Queues.with do |conn|
          expect(conn.zcard('resque:gitlab:schedule')).to eq(0)
        end
      end
    end
  end
end
