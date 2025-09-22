# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ScheduleOldPipelinesRemovalCronWorker,
  :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let(:worker) { described_class.new }
  let(:cleanup_queue) { Ci::RetentionPolicies::ProjectsCleanupQueue.instance }

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

      expect(cleanup_queue.fetch_next_project_id!).to eq(project.id)
    end

    it 'performs successfully multiple times' do
      2.times do
        expect { worker.perform }.not_to raise_error
      end
    end
  end
end
