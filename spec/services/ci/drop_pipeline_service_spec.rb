# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DropPipelineService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }

  let(:failure_reason) { :user_blocked }

  let!(:cancelable_pipeline) { create(:ci_pipeline, :running, user: user) }
  let!(:running_build) { create(:ci_build, :running, pipeline: cancelable_pipeline) }
  let!(:commit_status_running) { create(:commit_status, :running, pipeline: cancelable_pipeline) }
  let!(:success_pipeline) { create(:ci_pipeline, :success, user: user) }
  let!(:success_build) { create(:ci_build, :success, pipeline: success_pipeline) }
  let!(:commit_status_success) { create(:commit_status, :success, pipeline: cancelable_pipeline) }

  describe '#execute_async_for_all' do
    subject { described_class.new.execute_async_for_all(user.pipelines, failure_reason, user) }

    it 'drops only cancelable pipelines asynchronously', :sidekiq_inline do
      subject

      expect(cancelable_pipeline.reload).to be_failed
      expect(running_build.reload).to be_failed

      expect(success_pipeline.reload).to be_success
      expect(success_build.reload).to be_success
    end

    context 'when a custom worker_class is provided' do
      it 'uses the given worker class instead of Ci::DropPipelineWorker' do
        expect(Ci::DropPipelineForBlockedUserWorker).to receive(:bulk_perform_async_with_contexts)
        expect(Ci::DropPipelineWorker).not_to receive(:bulk_perform_async_with_contexts)

        described_class.new.execute_async_for_all(
          user.pipelines, failure_reason, user,
          worker_class: Ci::DropPipelineForBlockedUserWorker
        )
      end
    end
  end

  describe '#execute' do
    subject { described_class.new.execute(cancelable_pipeline.id, failure_reason) }

    def drop_pipeline!(pipeline)
      described_class.new.execute(pipeline, failure_reason)
    end

    it 'drops each cancelable build in the pipeline', :aggregate_failures do
      drop_pipeline!(cancelable_pipeline)

      expect(running_build.reload).to be_failed
      expect(running_build.failure_reason).to eq(failure_reason.to_s)

      expect(success_build.reload).to be_success
    end

    it 'avoids N+1 queries when reading data' do
      control_count = ActiveRecord::QueryRecorder.new do
        drop_pipeline!(cancelable_pipeline)
      end.count

      writes_per_build = 2
      load_balancer_queries = 3
      expected_reads_count = control_count - writes_per_build
      savepoints = 1

      create_list(:ci_build, 5, :running, pipeline: cancelable_pipeline)

      expect do
        drop_pipeline!(cancelable_pipeline)
      end.not_to exceed_query_limit(
        expected_reads_count + (5 * writes_per_build) + load_balancer_queries + (5 * savepoints)
      )
    end
  end
end
