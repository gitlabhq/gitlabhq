# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateSidekiqNamespacedJobs, :migration, feature_category: :scalability do
  before do
    q1 = instance_double(Sidekiq::Queue, name: 'q1')
    q2 = instance_double(Sidekiq::Queue, name: 'q2')
    allow(Sidekiq::Queue).to receive(:all).and_return([q1, q2])

    Gitlab::Redis::Queues.with do |redis|
      (1..1000).each do |i|
        redis.zadd('resque:gitlab:schedule', [i, i])
        redis.zadd('resque:gitlab:retry', [i, i])
        redis.zadd('resque:gitlab:dead', [i, i])
      end

      Sidekiq::Queue.all.each do |queue|
        (1..1000).each do |i|
          redis.lpush("resque:gitlab:queue:#{queue.name}", i)
        end
      end
    end
  end

  after do
    Gitlab::Redis::Queues.with(&:flushdb)
  end

  it "does not creates default organization if needed" do
    reversible_migration do |migration|
      migration.before -> {
        Gitlab::Redis::Queues.with do |redis|
          expect(redis.zcard('resque:gitlab:schedule')).to eq(1000)
          expect(redis.zcard('resque:gitlab:retry')).to eq(1000)
          expect(redis.zcard('resque:gitlab:dead')).to eq(1000)
          expect(redis.zcard('schedule')).to eq(0)
          expect(redis.zcard('retry')).to eq(0)
          expect(redis.zcard('dead')).to eq(0)

          Sidekiq::Queue.all.each do |queue|
            expect(redis.llen("resque:gitlab:queue:#{queue.name}")).to eq(1000)
            expect(redis.llen("queue:#{queue.name}")).to eq(0)
          end
        end
      }

      migration.after -> {
        # no namespaced keys
        Gitlab::Redis::Queues.with do |redis|
          expect(redis.zcard('resque:gitlab:schedule')).to eq(0)
          expect(redis.zcard('resque:gitlab:retry')).to eq(0)
          expect(redis.zcard('resque:gitlab:dead')).to eq(0)
          expect(redis.zcard('schedule')).to eq(1000)
          expect(redis.zcard('retry')).to eq(1000)
          expect(redis.zcard('dead')).to eq(1000)

          Sidekiq::Queue.all.each do |queue|
            expect(redis.llen("resque:gitlab:queue:#{queue.name}")).to eq(0)
            expect(redis.llen("queue:#{queue.name}")).to eq(1000)
          end
        end
      }
    end
  end
end
