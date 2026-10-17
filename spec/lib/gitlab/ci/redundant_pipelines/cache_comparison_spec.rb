# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RedundantPipelines::CacheComparison, :clean_gitlab_redis_shared_state,
  feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:older) { create(:ci_pipeline, project: project, ref: 'main') }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'main') }

  subject(:comparison) { described_class.for(pipeline) }

  def cache
    Gitlab::Ci::RedundantPipelines::CandidateCache.for(project_id: project.id, ref: 'main')
  end

  def key(pipeline)
    Gitlab::Ci::RedundantPipelines::PipelineKey.of(pipeline)
  end

  describe '#log_fields' do
    subject(:log_fields) { comparison.log_fields }

    it 'reports no difference when the search decided nothing' do
      expect(log_fields).to eq(
        cache_missed_count: 0, cache_missed_ids: [],
        cache_would_cancel_count: 0, cache_would_cancel_ids: [],
        cache_would_cancel_never_started_count: 0, cache_would_cancel_never_started_ids: [],
        cache_would_keep_count: 0, cache_would_keep_ids: []
      )
    end

    context 'when the search cancels a pipeline' do
      before do
        comparison.canceled(older)
      end

      it 'reports no miss when the cache holds it' do
        cache.register(key(older))

        expect(log_fields).to include(cache_missed_count: 0, cache_missed_ids: [])
      end

      it 'reports a miss when the cache does not hold it' do
        expect(log_fields).to include(cache_missed_count: 1, cache_missed_ids: [older.id])
      end
    end

    context 'when the search cancels a child pipeline' do
      let_it_be(:child) { create(:ci_pipeline, child_of: older) }

      it 'reports no miss, because the cache only holds parents' do
        comparison.canceled(child)

        expect(log_fields).to include(cache_missed_count: 0)
      end
    end

    context 'when the search keeps a pipeline as protected' do
      before do
        comparison.kept_as_protected(older)
      end

      it 'reports no difference when redis protects it' do
        cache.protect(key(older))

        expect(log_fields).to include(cache_would_cancel_count: 0)
      end

      it 'reports no difference when the column protects it' do
        Ci::PipelineProcessingData.protect(older)

        expect(log_fields).to include(cache_would_cancel_count: 0)
      end

      context 'when nothing protects it' do
        it 'reports that the cache path would cancel it when a non-interruptible job ran' do
          create(:ci_build, :running, pipeline: older)

          expect(log_fields).to include(
            cache_would_cancel_count: 1, cache_would_cancel_ids: [older.id],
            cache_would_cancel_never_started_count: 0, cache_would_cancel_never_started_ids: []
          )
        end

        it 'reports it as never started when a non-interruptible job failed without running' do
          create(:ci_build, :failed, started_at: nil, pipeline: older)

          expect(log_fields).to include(
            cache_would_cancel_count: 0, cache_would_cancel_ids: [],
            cache_would_cancel_never_started_count: 1, cache_would_cancel_never_started_ids: [older.id]
          )
        end

        it 'reports it as never started when no job explains the search decision' do
          expect(log_fields).to include(
            cache_would_cancel_count: 0,
            cache_would_cancel_never_started_count: 1, cache_would_cancel_never_started_ids: [older.id]
          )
        end

        it 'reports it as would cancel when a job ran, even if another failed without running' do
          create(:ci_build, :failed, started_at: nil, pipeline: older)
          create(:ci_build, :success, pipeline: older)

          expect(log_fields).to include(cache_would_cancel_count: 1, cache_would_cancel_never_started_count: 0)
        end

        it 'ignores an interruptible job that ran' do
          create(:ci_build, :interruptible, :running, pipeline: older)

          expect(log_fields).to include(cache_would_cancel_count: 0, cache_would_cancel_never_started_count: 1)
        end
      end
    end

    context 'when the cache protects a pipeline the search cancels' do
      before do
        cache.protect(key(older))
      end

      it 'reports that the cache path would keep it in conservative mode' do
        comparison.canceled_conservatively(older)

        expect(log_fields).to include(cache_would_keep_count: 1, cache_would_keep_ids: [older.id])
      end

      it 'reports no difference in interruptible mode, where protection does not count' do
        comparison.canceled(older)

        expect(log_fields).to include(cache_would_keep_count: 0)
      end
    end

    it 'lists a limited number of ids' do
      stub_const("#{described_class}::MAX_LOGGED_IDS", 1)
      other = create(:ci_pipeline, project: project, ref: 'main')

      comparison.canceled(older)
      comparison.canceled(other)

      expect(log_fields).to include(cache_missed_count: 2, cache_missed_ids: [older.id])
    end

    it 'reads redis twice and the database once' do
      Ci::PipelineProcessingData.protect(pipeline)
      comparison.canceled_conservatively(older)
      comparison.kept_as_protected(pipeline)

      redis = RedisCommands::Recorder.new(pattern: 'ci:redundant_pipelines') do
        database = ActiveRecord::QueryRecorder.new { log_fields }

        expect(database.count).to eq(1)
      end

      expect(redis.count).to eq(2)
    end

    it 'looks the column up in batches' do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      Ci::PipelineProcessingData.protect(older)
      Ci::PipelineProcessingData.protect(pipeline)
      comparison.kept_as_protected(older)
      comparison.kept_as_protected(pipeline)

      database = ActiveRecord::QueryRecorder.new { expect(log_fields).to include(cache_would_cancel_count: 0) }

      expect(database.count).to eq(2)
    end

    it 'reads the database once more when the cache leaves a kept pipeline unprotected' do
      comparison.canceled_conservatively(older)
      comparison.kept_as_protected(pipeline)

      database = ActiveRecord::QueryRecorder.new { log_fields }

      expect(database.count).to eq(2)
    end
  end
end
