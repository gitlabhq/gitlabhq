# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DestroyOldPipelinesWorker, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }
  let_it_be(:ancient_pipeline) { create(:ci_pipeline, project: project, created_at: 1.year.ago, locked: :unlocked) }
  let_it_be(:old_pipeline) { create(:ci_pipeline, project: project, created_at: 1.month.ago, locked: :unlocked) }
  let_it_be(:new_pipeline) { create(:ci_pipeline, project: project, created_at: 1.week.ago, locked: :unlocked) }

  let(:cleanup_queue) { Ci::RetentionPolicies::ProjectsCleanupQueue.instance }

  before do
    cleanup_queue.enqueue!(project)
  end

  describe '#perform' do
    let(:worker) { described_class.new }

    subject(:perform) { worker.perform_work }

    context 'when ci_optimized_old_pipelines_query FF is disabled' do
      before do
        # This context tests the legacy pipeline query behavior
        stub_feature_flags(ci_optimized_old_pipelines_query: false)
        stub_const("#{described_class.name}::LIMIT", 1)
      end

      it 'destroys the configured amount of pipelines' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:removed_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:project, project.full_path)

        expect { perform }.to change { project.all_pipelines.count }.by(-1)
        expect(new_pipeline.reload).to be_present
      end
    end

    it 'loops thought the available pipelines' do
      stub_const("#{described_class.name}::LIMIT", 3)

      expect { perform }.to change { project.all_pipelines.count }.by(-2)
      expect(new_pipeline.reload).to be_present
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id] }

      it 'executes the service' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when protected pipelines are configured' do
      let_it_be(:old_protected_pipeline) do
        create(:ci_pipeline, project: project, created_at: 1.month.ago, protected: true)
      end

      it 'keeps protected pipelines' do
        expect { perform }.to change { project.all_pipelines.count }.by(-2)
        expect(old_protected_pipeline.reload).to be_present
      end
    end

    context 'when artifacts of pipeline are locked' do
      let_it_be(:pipeline_with_locked_artifact) do
        create(:ci_pipeline, project: project, created_at: 1.month.ago, locked: :artifacts_locked)
      end

      it 'keeps pipelines with :artifacts_locked' do
        expect { perform }.to change { project.all_pipelines.count }.by(-2)
        expect(pipeline_with_locked_artifact.reload).to be_present
      end

      context 'with feature flag :ci_skip_locked_pipelines disabled' do
        before do
          stub_feature_flags(ci_skip_locked_pipelines: false)
        end

        it 'does not keep pipelines with :artifacts_locked' do
          expect { perform }.to change { project.all_pipelines.count }.by(-3)
          expect { pipeline_with_locked_artifact.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end
  end

  describe '#remaining_work_count' do
    subject(:remaining_work_count) { described_class.new.remaining_work_count }

    it { is_expected.to eq(1) }
  end

  describe 're-enqueuing with optimized pipeline query' do
    let(:worker) { described_class.new }
    let(:service) { instance_double(Ci::Pipelines::AutoCleanupService) }

    before do
      allow(Ci::Pipelines::AutoCleanupService).to receive(:new).with(project: project).and_return(service)
      allow(service).to receive(:execute).and_return(
        ServiceResponse.success(payload: { destroyed_pipelines_size: destroyed_count,
                                           skipped_pipelines_size: skipped_count })
      )
    end

    subject(:perform) { worker.perform_work }

    shared_examples 'logs metadata' do
      it 'logs the correct metadata' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:removed_count, destroyed_count)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:skipped_count, skipped_count)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:project, project.full_path)

        perform
      end
    end

    shared_examples 're-enqueues the project' do
      include_examples 'logs metadata'

      it 're-enqueues the project' do
        expect { perform }.not_to change { cleanup_queue.size }
      end
    end

    shared_examples 'does not re-enqueue the project' do
      include_examples 'logs metadata'

      it 'does not re-enqueue the project' do
        expect { perform }.to change { cleanup_queue.size }.by(-1)
      end
    end

    context 'when destroyed_pipelines_size is greater than RE_ENQUEUE_THRESHOLD' do
      let(:destroyed_count) { 150 }
      let(:skipped_count) { 50 }

      include_examples 're-enqueues the project'
    end

    context 'when skipped_pipelines_size is greater than RE_ENQUEUE_THRESHOLD' do
      let(:destroyed_count) { 50 }
      let(:skipped_count) { 150 }

      include_examples 're-enqueues the project'
    end

    context 'when both destroyed_pipelines_size and skipped_pipelines_size are greater than RE_ENQUEUE_THRESHOLD' do
      let(:destroyed_count) { 120 }
      let(:skipped_count) { 110 }

      include_examples 're-enqueues the project'
    end

    context 'when both destroyed_pipelines_size and skipped_pipelines_size are
            less than or equal to RE_ENQUEUE_THRESHOLD' do
      let(:destroyed_count) { 100 }
      let(:skipped_count) { 100 }

      include_examples 'does not re-enqueue the project'
    end

    context 'when destroyed_pipelines_size is 0 and skipped_pipelines_size is 0' do
      let(:destroyed_count) { 0 }
      let(:skipped_count) { 0 }

      include_examples 'does not re-enqueue the project'
    end
  end
end
