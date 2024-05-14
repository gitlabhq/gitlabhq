# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveCreateEmptyEmbeddingsRecordsWorker, :migration, feature_category: :scalability do
  let(:hash_name) { 'cron_job:llm_embedding_gitlab_documentation_create_empty_embeddings_records_worker' }
  let(:zset_name) { 'cron_job:llm_embedding_gitlab_documentation_create_empty_embeddings_records_worker:enqueued' }
  let(:job_message) do
    { "retry" => 3,
      "queue" => "default",
      "version" => 0,
      "queue_namespace" => "cronjob",
      "class" => "Llm::Embedding::GitlabDocumentation::CreateEmptyEmbeddingsRecordsWorker",
      "args" => [] }
  end

  let(:cron_args) do
    [
      "symbolize_args", "0", "date_as_argument", "false",
      "name", "llm_embedding_gitlab_documentation_create_empty_embeddings_records_worker",
      "queue_name_prefix", "",
      "cron", "0 5 * * 1,2,3,4,5",
      "last_enqueue_time", "2024-04-30,05:00:01,+0000",
      "status", "enabled",
      "klass", "Llm::Embedding::GitlabDocumentation::CreateEmptyEmbeddingsRecordsWorker",
      "message", Sidekiq.dump_json(job_message)
    ]
  end

  context 'when cron job exists' do
    before do
      Gitlab::Redis::Queues.with do |redis|
        redis.hset(hash_name, *cron_args)
        redis.zadd(zset_name, 1714626000, "2024-05-02T05:00:00Z")
      end
    end

    after do
      Gitlab::Redis::Queues.with(&:flushdb)
    end

    it "deletes the cron job and enqueued jobs" do
      migrate!

      Gitlab::Redis::Queues.with do |redis|
        expect(redis.exists(hash_name)).to eq(0)
        expect(redis.exists(zset_name)).to eq(0)
      end
    end
  end

  context 'when cron job does not exist' do
    it "no-ops" do
      expect { migrate! }.not_to raise_error
    end
  end
end
