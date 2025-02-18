# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ScheduleOldPipelinesRemovalCronWorker,
  :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let(:worker) { described_class.new }

  let_it_be(:project) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }

  it { is_expected.to include_module(CronjobQueue) }
  it { expect(described_class.idempotent?).to be_truthy }

  describe '#perform' do
    it 'enqueues DestroyOldPipelinesWorker jobs' do
      expect(Ci::DestroyOldPipelinesWorker).to receive(:perform_with_capacity)

      worker.perform
    end

    it 'enqueues projects to be processed' do
      worker.perform

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.lpop(described_class::QUEUE_KEY).to_i).to eq(project.id)
      end
    end

    context 'when the worker reaches the maximum number of records per execution' do
      before do
        stub_const("#{described_class}::PROJECTS_LIMIT", 1)
      end

      it 'sets the last processed record id in Redis cache' do
        worker.perform

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.get(described_class::LAST_PROCESSED_REDIS_KEY).to_i).to eq(project.id)
        end
      end
    end

    context 'when the worker continues processing from previous execution' do
      let_it_be(:other_project) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }

      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class::LAST_PROCESSED_REDIS_KEY, other_project.id)
        end
      end

      it 'enqueues projects to be processed' do
        worker.perform

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.lpop(described_class::QUEUE_KEY).to_i).to eq(other_project.id)
        end
      end

      it 'enqueues DestroyOldPipelinesWorker jobs' do
        expect(Ci::DestroyOldPipelinesWorker).to receive(:perform_with_capacity)

        worker.perform
      end

      it 'performs successfully multiple times' do
        2.times do
          expect { worker.perform }.not_to raise_error
        end
      end
    end

    context 'when the worker finishes processing before running out of batches' do
      before do
        stub_const("#{described_class}::PROJECTS_LIMIT", 2)

        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class::LAST_PROCESSED_REDIS_KEY, 0)
        end
      end

      it 'clears the last processed record id in Redis cache' do
        worker.perform

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.get(described_class::LAST_PROCESSED_REDIS_KEY)).to be_nil
        end
      end

      it 'enqueues projects to be processed' do
        worker.perform

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.lpop(described_class::QUEUE_KEY).to_i).to eq(project.id)
        end
      end
    end
  end
end
