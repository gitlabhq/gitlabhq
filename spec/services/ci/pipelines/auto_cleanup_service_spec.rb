# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::AutoCleanupService, :freeze_time, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  subject(:execute_service) { service.execute }

  let(:retention_period) { 2.weeks }
  let(:cut_off_date) { retention_period }
  let(:oldest_pipeline_created_at) { 1.year.ago }
  let(:status_group_keys) { %w[success failed canceled skipped manual other] }

  let(:service) { described_class.new(project: project) }

  # Project with 2-week retention period
  let_it_be_with_reload(:project) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }

  # Pipelines created 1 year ago (should be deleted)
  let_it_be(:ancient_pipelines) do
    Ci::HasStatus::AVAILABLE_STATUSES.map do |status|
      create(:ci_pipeline, project: project, created_at: 1.year.ago, locked: :unlocked, status: status)
    end
  end

  # Pipelines created 1 month ago (should be deleted)
  let_it_be(:old_pipelines) do
    Ci::HasStatus::AVAILABLE_STATUSES.map do |status|
      create(:ci_pipeline, project: project, created_at: 1.month.ago, locked: :unlocked, status: status)
    end
  end

  # Pipelines created 1 week ago (should be kept)
  let_it_be(:new_pipelines) do
    Ci::HasStatus::AVAILABLE_STATUSES.map do |status|
      create(:ci_pipeline, project: project, created_at: 1.week.ago, locked: :unlocked, status: status)
    end
  end

  describe '#execute' do
    let(:expected_deletion_count) { 2 * Ci::HasStatus::AVAILABLE_STATUSES.count }

    it 'deletes all pipelines older than the configured retention period' do
      expect { execute_service }.to change { project.all_pipelines.count }.by(-expected_deletion_count)
    end

    it 'returns a success service response with destroyed and skipped counts' do
      result = execute_service

      expect(result).to be_success
      expect(result.payload[:destroyed_pipelines_size]).to eq(expected_deletion_count)
      expect(result.payload[:skipped_pipelines_size]).to eq(0)
    end

    it 'updates cache with the timestamp of the last processed pipeline' do
      execute_service

      cache = read_cache(project)

      expect(cache.values).to all(be_like_time(old_pipelines.last.created_at).or(be > old_pipelines.last.created_at))
    end

    context 'when cache has not been initialized' do
      it 'starts with an empty cache hash' do
        expect(read_cache(project)).to eq({})
      end

      it 'deletes all pipelines older than the configured retention period on first run' do
        expect { execute_service }.to change { project.all_pipelines.count }.by(-expected_deletion_count)
      end

      it 'initializes cache with timestamps for all status groups after first run' do
        execute_service

        cache = read_cache(project)

        expect(cache.keys).to match_array(%w[success failed canceled skipped manual other])
        expect(cache.values).to all(be_present)
      end

      it 'processes pipelines starting from the oldest pipeline for each status group' do
        execute_service

        # Verify that both ancient (1-year-old) and old (1-month-old) pipelines were deleted
        expect(project.all_pipelines.where(id: (ancient_pipelines + old_pipelines).map(&:id))).not_to exist
        # Verify that new pipelines (1-week-old) were kept
        expect(project.all_pipelines.where(id: new_pipelines.map(&:id))).to exist
      end
    end

    context 'when cache contains previously processed timestamps' do
      let(:cache_value) { status_group_keys.index_with { oldest_pipeline_created_at - 1.day } }

      before do
        write_cache(project, cache_value)
      end

      it 'uses cached timestamps to continue processing from where it left off' do
        expect { execute_service }.to change { project.all_pipelines.count }.by(-expected_deletion_count)
      end

      context 'when all cached timestamps are at or beyond the retention cutoff time' do
        let(:cache_value) { status_group_keys.index_with { cut_off_date.ago + 1.day } }

        it 'does not delete any pipelines since processing is complete' do
          expect { execute_service }.not_to change { project.all_pipelines.count }
        end

        it 'updates cache to deletion_cutoff_time when no pipelines are found' do
          execute_service

          cache = read_cache(project)

          expect(cache.values).to all(be >= retention_period.ago)
        end
      end

      context 'when some status groups have completed processing while others have not' do
        let(:cache_value) do
          status_group_keys.index_with do |key|
            key == 'success' ? cut_off_date.ago + 1.day : oldest_pipeline_created_at - 1.day
          end
        end

        it 'deletes pipelines only for status groups that have not reached cutoff' do
          ancient_success = ancient_pipelines.find { |p| p.status == 'success' }
          old_success = old_pipelines.find { |p| p.status == 'success' }

          expect { execute_service }
            .to change { project.all_pipelines.count }
            .by(-(expected_deletion_count - 2))
            .and not_change { Ci::Pipeline.exists?(ancient_success.id) }
            .and not_change { Ci::Pipeline.exists?(old_success.id) }
        end
      end
    end

    context 'with protected pipelines' do
      let(:old_pipelines_to_protect) { ancient_pipelines + old_pipelines }

      before do
        protect_pipelines(old_pipelines_to_protect)
      end

      context 'when ci_skip_old_protected_pipelines feature flag is disabled' do
        before do
          stub_feature_flags(ci_skip_old_protected_pipelines: false)
        end

        it 'includes protected pipelines in the deletion' do
          expect { execute_service }.to change { project.all_pipelines.count }.by(-expected_deletion_count)
        end
      end

      context 'when ci_skip_old_protected_pipelines feature flag is enabled' do
        before do
          stub_feature_flags(ci_skip_old_protected_pipelines: true)
        end

        it 'skips protected pipelines from deletion' do
          result = execute_service

          expect(result).to be_success
          expect(result.payload[:destroyed_pipelines_size]).to eq(0)
          expect(result.payload[:skipped_pipelines_size]).to eq(expected_deletion_count)
        end
      end
    end

    context 'with locked pipelines' do
      let(:old_pipelines_to_lock) { ancient_pipelines + old_pipelines }

      before do
        lock_pipelines(old_pipelines_to_lock)
      end

      context 'when ci_skip_locked_pipelines feature flag is disabled' do
        before do
          stub_feature_flags(ci_skip_locked_pipelines: false)
        end

        it 'includes locked pipelines in the deletion' do
          expect { execute_service }.to change { project.all_pipelines.count }.by(-expected_deletion_count)
        end
      end

      context 'when ci_skip_locked_pipelines feature flag is enabled' do
        before do
          stub_feature_flags(ci_skip_locked_pipelines: true)
        end

        it 'skips locked pipelines from deletion' do
          result = execute_service

          expect(result).to be_success
          expect(result.payload[:destroyed_pipelines_size]).to eq(0)
          expect(result.payload[:skipped_pipelines_size]).to eq(expected_deletion_count)
        end
      end
    end

    context 'with both protected and locked pipelines' do
      let(:old_pipelines_to_protect_and_lock) { ancient_pipelines + old_pipelines }

      before do
        protect_and_lock_pipelines(old_pipelines_to_protect_and_lock)
      end

      context 'when both feature flags are disabled' do
        before do
          stub_feature_flags(ci_skip_old_protected_pipelines: false)
          stub_feature_flags(ci_skip_locked_pipelines: false)
        end

        it 'includes both locked and protected pipelines in the deletion' do
          expect { execute_service }.to change { project.all_pipelines.count }.by(-expected_deletion_count)
        end
      end

      context 'when both feature flags are enabled' do
        before do
          stub_feature_flags(ci_skip_old_protected_pipelines: true)
          stub_feature_flags(ci_skip_locked_pipelines: true)
        end

        it 'skips both locked and protected pipelines from deletion' do
          result = execute_service

          expect(result).to be_success
          expect(result.payload[:destroyed_pipelines_size]).to eq(0)
          expect(result.payload[:skipped_pipelines_size]).to eq(expected_deletion_count)
        end
      end
    end

    context 'with batch processing' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
      end

      it 'processes pipelines in batches per status group' do
        completed_statuses_count = Ci::HasStatus::COMPLETED_WITH_MANUAL_STATUSES.count
        # Each status group processes 2 pipelines per batch
        # +2 is for 'other' status group (non-completed statuses)
        expected_batch_deletion = (completed_statuses_count * 2) + 2

        expect { execute_service }.to change { project.all_pipelines.count }.by(-expected_batch_deletion)

        cache = read_cache(project)

        expect(cache.keys).to match_array(%w[success failed canceled skipped manual other])
      end

      context 'when locked pipelines are encountered in batch' do
        before do
          lock_pipelines(ancient_pipelines)
        end

        it 'skips locked pipelines and processes unlocked ones in the batch' do
          result = execute_service

          expect(result).to be_success
          # 5 completed statuses + 2 non-completed statuses (other)
          expect(result.payload[:skipped_pipelines_size]).to eq(7)
          expect(result.payload[:destroyed_pipelines_size]).to eq(5)
          expect(project.all_pipelines.where(id: ancient_pipelines.map(&:id))).to exist
        end
      end

      context 'when all pipelines in batch are filtered out' do
        before do
          lock_pipelines(ancient_pipelines + old_pipelines)
        end

        it 'returns zero destroyed pipelines' do
          result = execute_service

          expect(result).to be_success
          expect(result.payload[:destroyed_pipelines_size]).to eq(0)
        end
      end
    end

    context 'when no pipelines exist older than the retention period' do
      before do
        Ci::Pipeline.where(id: (ancient_pipelines + old_pipelines).map(&:id)).delete_all
      end

      it 'deletes no pipelines and sets cache to deletion_cutoff_time' do
        expect { execute_service }.not_to change { project.all_pipelines.count }

        cache = read_cache(project)

        expect(cache.values).to all(be_like_time(retention_period.ago))
      end
    end

    context 'when batch returns empty but processing is not complete' do
      let(:cache_value) { status_group_keys.index_with { oldest_pipeline_created_at } }

      before do
        write_cache(project, cache_value)
        # Delete all old pipelines so the batch query returns empty
        Ci::Pipeline.where(id: (ancient_pipelines + old_pipelines).map(&:id)).delete_all
      end

      it 'sets cache to deletion_cutoff_time when no pipelines are found in batch' do
        execute_service

        cache = read_cache(project)

        # When pipelines.last is nil, it should use deletion_cutoff_time
        expect(cache.values).to all(be_like_time(retention_period.ago))
      end
    end

    context 'when all old pipelines are protected' do
      before do
        protect_pipelines(ancient_pipelines + old_pipelines)
      end

      it 'skips all protected pipelines' do
        result = execute_service

        expect(result).to be_success
        expect(result.payload[:destroyed_pipelines_size]).to eq(0)
        expect(result.payload[:skipped_pipelines_size]).to eq(expected_deletion_count)
      end
    end

    context 'when pipelines are eligible for destruction' do
      it 'invokes the destroy service with correct parameters' do
        expect_next_instance_of(Ci::DestroyPipelineService) do |instance|
          expect(instance).to receive(:unsafe_execute) do |pipelines, options|
            expect(pipelines.size).to eq(expected_deletion_count)
            expect(options).to eq(skip_cancel: true)
          end.and_call_original
        end

        execute_service
      end
    end
  end

  def read_cache(project)
    Ci::RetentionPolicies::PipelineDeletionCutoffCache.new(project: project).read
  end

  def write_cache(project, values)
    Ci::RetentionPolicies::PipelineDeletionCutoffCache.new(project: project).write(values)
  end

  def lock_pipelines(pipelines)
    Ci::Pipeline.where(id: pipelines.map(&:id)).update_all(locked: :artifacts_locked)
  end

  def protect_pipelines(pipelines)
    Ci::Pipeline.where(id: pipelines.map(&:id)).update_all(protected: true)
  end

  def protect_and_lock_pipelines(pipelines)
    Ci::Pipeline.where(id: pipelines.map(&:id)).update_all(protected: true, locked: :artifacts_locked)
  end
end
