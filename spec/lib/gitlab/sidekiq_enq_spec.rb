# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqEnq, :clean_gitlab_redis_queues do
  let(:retry_set) { Sidekiq::Scheduled::SETS.first }
  let(:schedule_set) { Sidekiq::Scheduled::SETS.last }

  around do |example|
    freeze_time { example.run }
  end

  shared_examples 'finds jobs that are due and enqueues them' do
    before do
      Sidekiq.redis do |redis|
        redis.zadd(retry_set, (Time.current - 1.day).to_f.to_s, '{"jid": 1}')
        redis.zadd(retry_set, Time.current.to_f.to_s, '{"jid": 2}')
        redis.zadd(retry_set, (Time.current + 1.day).to_f.to_s, '{"jid": 3}')

        redis.zadd(schedule_set, (Time.current - 1.day).to_f.to_s, '{"jid": 4}')
        redis.zadd(schedule_set, Time.current.to_f.to_s, '{"jid": 5}')
        redis.zadd(schedule_set, (Time.current + 1.day).to_f.to_s, '{"jid": 6}')
      end
    end

    it 'enqueues jobs that are due' do
      expect(Sidekiq::Client).to receive(:push).with({ 'jid' => 1 })
      expect(Sidekiq::Client).to receive(:push).with({ 'jid' => 2 })
      expect(Sidekiq::Client).to receive(:push).with({ 'jid' => 4 })
      expect(Sidekiq::Client).to receive(:push).with({ 'jid' => 5 })

      Gitlab::SidekiqEnq.new.enqueue_jobs

      Sidekiq.redis do |redis|
        expect(redis.zscan_each(retry_set).map(&:first)).to contain_exactly('{"jid": 3}')
        expect(redis.zscan_each(schedule_set).map(&:first)).to contain_exactly('{"jid": 6}')
      end
    end
  end

  context 'when atomic_sidekiq_scheduler is disabled' do
    before do
      stub_feature_flags(atomic_sidekiq_scheduler: false)
    end

    it_behaves_like 'finds jobs that are due and enqueues them'

    context 'when ZRANGEBYSCORE returns a job that is already removed by another process' do
      before do
        Sidekiq.redis do |redis|
          redis.zadd(schedule_set, Time.current.to_f.to_s, '{"jid": 1}')

          allow(redis).to receive(:zrangebyscore).and_wrap_original do |m, *args, **kwargs|
            m.call(*args, **kwargs).tap do |jobs|
              redis.zrem(schedule_set, jobs.first) if args[0] == schedule_set && jobs.first
            end
          end
        end
      end

      it 'calls ZREM but does not enqueue the job' do
        Sidekiq.redis do |redis|
          expect(redis).to receive(:zrem).with(schedule_set, '{"jid": 1}').twice.and_call_original
        end
        expect(Sidekiq::Client).not_to receive(:push)

        Gitlab::SidekiqEnq.new.enqueue_jobs
      end
    end
  end

  context 'when atomic_sidekiq_scheduler is enabled' do
    before do
      stub_feature_flags(atomic_sidekiq_scheduler: true)
    end

    context 'when Lua script is not yet loaded' do
      before do
        Gitlab::Redis::Queues.with { |redis| redis.script(:flush) }
      end

      it_behaves_like 'finds jobs that are due and enqueues them'
    end

    context 'when Lua script is already loaded' do
      before do
        Gitlab::SidekiqEnq.new.enqueue_jobs
      end

      it_behaves_like 'finds jobs that are due and enqueues them'
    end
  end
end
