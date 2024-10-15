# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDanglingCronWorker, :migration, feature_category: :scalability do
  let(:job_message) do
    { "retry" => 3,
      "queue" => "default",
      "version" => 0,
      "queue_namespace" => "cronjob",
      "class" => "Placeholder",
      "args" => [] }
  end

  def hash_name(worker)
    "cron_job:#{worker}"
  end

  def zset_name(worker)
    "#{hash_name(worker)}:enqueued"
  end

  def cron_args(worker)
    [
      "symbolize_args", "0", "date_as_argument", "false",
      "name", worker,
      "queue_name_prefix", "",
      "cron", "0 5 * * 1,2,3,4,5",
      "last_enqueue_time", "2024-04-30,05:00:01,+0000",
      "status", "enabled",
      "klass", "Placehlder",
      "message", Sidekiq.dump_json(job_message)
    ]
  end

  context 'when cron job exists' do
    before do
      Gitlab::Redis::Queues.with do |redis|
        described_class::WORKER_CLASSES.each do |wc|
          redis.hset(hash_name(wc), *cron_args(wc))
          redis.zadd(zset_name(wc), 1714626000, "2024-05-02T05:00:00Z")
        end
      end
    end

    after do
      Gitlab::Redis::Queues.with(&:flushdb)
    end

    it "deletes the cron job and enqueued jobs" do
      migrate!

      Gitlab::Redis::Queues.with do |redis|
        described_class::WORKER_CLASSES.each do |wc|
          expect(redis.exists(hash_name(wc))).to eq(0)
          expect(redis.exists(zset_name(wc))).to eq(0)
        end
      end
    end
  end

  context 'when cron job does not exist' do
    it "no-ops" do
      expect { migrate! }.not_to raise_error
    end
  end
end
