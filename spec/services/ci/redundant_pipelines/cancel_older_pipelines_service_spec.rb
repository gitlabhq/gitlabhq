# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RedundantPipelines::CancelOlderPipelinesService, :clean_gitlab_redis_shared_state,
  feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project) }

  let!(:previous) { create(:ci_pipeline, :running, project: project, ref: 'main') }
  let!(:others) { [] }
  let!(:pipeline) { create(:ci_pipeline, :running, project: project, ref: 'main', sha: 'newer-sha') }

  subject(:execute) { described_class.for(pipeline).execute }

  def cache
    Gitlab::Ci::RedundantPipelines::CandidateCache.for(project_id: project.id, ref: 'main')
  end

  def register(pipeline)
    Ci::RedundantPipelines::RegisterCandidateService.for(pipeline).execute
  end

  describe '#execute' do
    let!(:job) { create(:ci_build, :interruptible, :running, pipeline: previous) }

    context 'when an older pipeline was registered' do
      before do
        register(previous)
      end

      it 'cancels it' do
        expect(execute).to be_success
        expect(execute.payload[:canceled_count]).to eq(1)

        expect(job.reload).to be_canceled
      end

      it 'leaves it out of the cache' do
        execute

        expect(cache.size).to eq(0)
      end

      it 'cancels it only once' do
        execute

        expect(described_class.for(pipeline).execute.payload[:canceled_count]).to eq(0)
      end

      it 'does not search p_ci_pipelines for the pipelines to cancel' do
        recorder = ActiveRecord::QueryRecorder.new { execute }

        expect(recorder.log.grep(/FROM "p_ci_pipelines".*"ref" =/)).to be_empty
      end

      it 'does not ask p_ci_pipelines which pipelines have no started non-interruptible build' do
        recorder = ActiveRecord::QueryRecorder.new { execute }

        expect(recorder.log.grep(/FROM "p_ci_pipelines".*NOT EXISTS/)).to be_empty
      end
    end

    context 'when several pipelines are taken' do
      let!(:others) do
        Array.new(2) do
          create(:ci_pipeline, :running, project: project, ref: 'main').tap do |older|
            create(:ci_build, :interruptible, :running, pipeline: older)
            register(older)
          end
        end
      end

      before do
        register(previous)
      end

      it 'looks the ref head up once for all of them' do
        expect(project).to receive(:commit).with('main').once.and_call_original

        expect(execute.payload[:canceled_count]).to eq(3)
      end
    end

    context 'when an older pipeline is for the commit the ref points at' do
      let_it_be_with_reload(:project) { create(:project, :repository) }

      let!(:previous) do
        create(:ci_pipeline, :running, project: project, ref: 'master', sha: project.commit('master').id)
      end

      let!(:pipeline) { create(:ci_pipeline, :running, project: project, ref: 'master', sha: 'newer-sha') }

      before do
        register(previous)
      end

      it 'does not cancel it' do
        expect(execute.payload[:canceled_count]).to eq(0)

        expect(job.reload).to be_running
      end
    end

    context 'when the newer pipeline does not affect the ref status' do
      let!(:pipeline) do
        create(:ci_pipeline, :webide, :running, project: project, ref: 'main', sha: 'newer-sha')
      end

      before do
        register(previous)
      end

      it 'still cancels the older pipeline' do
        expect(execute.payload[:canceled_count]).to eq(1)

        expect(job.reload).to be_canceled
      end
    end

    context 'when an older pipeline is protected from being canceled' do
      before do
        register(previous)
        previous.create_pipeline_processing_data!(project_id: project.id, interruptible_protected: true)
      end

      it 'does not count it' do
        expect(execute.payload[:canceled_count]).to eq(0)

        expect(job.reload).to be_running
      end
    end

    context 'when no pipeline was registered' do
      it 'cancels nothing' do
        expect(execute.payload[:canceled_count]).to eq(0)

        expect(job.reload).to be_running
      end
    end

    context 'when auto-cancellation does not apply to the pipeline' do
      before do
        register(previous)
        project.update!(auto_cancel_pending_pipelines: 'disabled')
      end

      it 'cancels nothing' do
        expect(execute).to be_error
        expect(execute.reason).to eq(:auto_cancel_does_not_apply)

        expect(job.reload).to be_running
      end
    end

    context 'when the cache is gone' do
      before do
        register(previous)
        Gitlab::Redis::SharedState.with(&:flushdb)
      end

      it 'cancels nothing' do
        expect(execute.payload[:canceled_count]).to eq(0)

        expect(job.reload).to be_running
      end
    end

    context 'with many registered pipelines' do
      let!(:others) do
        Array.new(4) do
          create(:ci_pipeline, :running, project: project, ref: 'main').tap do |other|
            create(:ci_build, :interruptible, :running, pipeline: other)
          end
        end
      end

      before do
        ([previous] + others).each { |pipeline| register(pipeline) }
      end

      it 'cancels all of them' do
        expect(execute.payload[:canceled_count]).to eq(5)
      end

      # Each taken pipeline then asks the cache whether it is protected.
      it 'takes them in one redis call' do
        recorder = RedisCommands::Recorder.new(pattern: 'ci:redundant_pipelines') { execute }

        expect(recorder.by_command('evalsha').count).to eq(1)
        expect(recorder.by_command('zscore').count).to eq(5)
      end
    end
  end
end
