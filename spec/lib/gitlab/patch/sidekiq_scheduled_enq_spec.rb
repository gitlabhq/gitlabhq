# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::SidekiqScheduledEnq, :clean_gitlab_redis_queues, feature_category: :scalability do
  describe '#enqueue_jobs' do
    let_it_be(:payload) { {} }

    before do
      allow(Sidekiq).to receive(:load_json).and_return(payload)

      # stub data in both namespaces
      Sidekiq.redis { |c| c.zadd('schedule', 100, 'dummy') }
      Gitlab::Redis::Queues.with { |c| c.zadd('schedule', 100, 'dummy') }
    end

    subject { Sidekiq::Scheduled::Enq.new.enqueue_jobs }

    it 'only polls with Sidekiq.redis' do
      expect(Sidekiq::Client).to receive(:push).with(payload).once

      subject

      Sidekiq.redis do |conn|
        expect(conn.zcard('schedule')).to eq(0)
      end

      Gitlab::Redis::Queues.with do |conn|
        expect(conn.zcard('schedule')).to eq(1)
      end
    end

    context 'when SIDEKIQ_POLL_NON_NAMESPACED is enabled' do
      before do
        stub_env('SIDEKIQ_POLL_NON_NAMESPACED', 'true')
      end

      it 'polls both sets' do
        expect(Sidekiq::Client).to receive(:push).with(payload).twice

        subject

        Sidekiq.redis do |conn|
          expect(conn.zcard('schedule')).to eq(0)
        end

        Gitlab::Redis::Queues.with do |conn|
          expect(conn.zcard('schedule')).to eq(0)
        end
      end
    end

    context 'when both envvar are enabled' do
      around do |example|
        # runs the zadd to ensure it goes into namespaced set
        Sidekiq.redis { |c| c.zadd('schedule', 100, 'dummy') }

        holder = Sidekiq.redis_pool

        # forcibly replace Sidekiq.redis since this is set in config/initializer/sidekiq.rb
        Sidekiq.redis = Gitlab::Redis::Queues.pool

        example.run

      ensure
        Sidekiq.redis = holder
      end

      before do
        stub_env('SIDEKIQ_ENQUEUE_NON_NAMESPACED', 'true')
        stub_env('SIDEKIQ_POLL_NON_NAMESPACED', 'true')
      end

      it 'polls both sets' do
        expect(Sidekiq::Client).to receive(:push).with(payload).twice

        subject

        Sidekiq.redis do |conn|
          expect(conn.zcard('schedule')).to eq(0)
        end

        Gitlab::Redis::Queues.with do |conn|
          expect(conn.zcard('schedule')).to eq(0)
        end
      end
    end
  end
end
