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

    shared_examples 'destroys old pipelines' do
      it 'destroys the configured amount of pipelines' do
        stub_const("#{described_class.name}::LIMIT", 1)

        expect(worker).to receive(:log_extra_metadata_on_done).with(:removed_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:project, project.full_path)

        expect { perform }.to change { project.all_pipelines.count }.by(-1)
        expect(new_pipeline.reload).to be_present
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

    it_behaves_like 'destroys old pipelines'

    context 'with feature flag :ci_improved_destroy_old_pipelines_worker disabled' do
      before do
        stub_feature_flags(ci_improved_destroy_old_pipelines_worker: false)
      end

      it_behaves_like 'destroys old pipelines'
    end
  end

  describe '#remaining_work_count' do
    subject(:remaining_work_count) { described_class.new.remaining_work_count }

    it { is_expected.to eq(1) }
  end
end
