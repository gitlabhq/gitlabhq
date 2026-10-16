# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CancelRedundantPipelinesWorker, :clean_gitlab_redis_shared_state,
  feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  let(:prev_pipeline) { create(:ci_pipeline, project: project) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: 'new-sha') }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline.id) }

    context 'when the redundant pipelines are taken from redis' do
      let(:service) { instance_double(Ci::RedundantPipelines::CancelOlderPipelinesService) }

      it 'cancels the older pipelines taken from the cache' do
        expect(Ci::RedundantPipelines::CancelOlderPipelinesService)
          .to receive(:for)
          .with(pipeline)
          .and_return(service)

        expect(service).to receive(:execute)

        perform
      end
    end

    context 'when the redundant pipelines are searched for' do
      let(:service) { instance_double('Ci::PipelineCreation::CancelRedundantPipelinesService') }

      before do
        stub_feature_flags(ci_redundant_pipeline_cancel_from_cache: false)
      end

      it 'calls cancel redundant pipeline service' do
        expect(Ci::PipelineCreation::CancelRedundantPipelinesService)
          .to receive(:new)
          .with(pipeline)
          .and_return(service)

        expect(service).to receive(:execute)

        perform
      end

      context 'with a passed partition_id' do
        subject(:perform) { described_class.new.perform(pipeline.id, { 'partition_id' => pipeline.partition_id }) }

        it 'finds the passed pipeline in the correct partition and passes it to the service' do
          expect(Ci::PipelineCreation::CancelRedundantPipelinesService)
            .to receive(:new)
            .with(pipeline)
            .and_return(service)

          expect(service).to receive(:execute)

          recorder = ActiveRecord::QueryRecorder.new { perform }
          pipeline_queries = recorder.log.grep(/^SELECT "p_ci_pipelines"/)

          expect(pipeline_queries.size).to eq(1)
          expect(pipeline_queries.first).to match(/"partition_id" = #{pipeline.partition_id}/)
        end
      end

      describe 'interacting with previous pending pipelines', :sidekiq_inline do
        before do
          create(:ci_build, :interruptible, :running, pipeline: prev_pipeline)
        end

        it_behaves_like 'an idempotent worker', :sidekiq_inline do
          let(:job_args) { pipeline }

          it 'cancels the previous pending pipeline' do
            perform

            expect(prev_pipeline.builds.pluck(:status)).to contain_exactly('canceled')
          end
        end
      end
    end

    context 'if pipeline is deleted' do
      subject(:perform) { described_class.new.perform(non_existing_record_id) }

      it 'does not cancel anything' do
        expect(Ci::RedundantPipelines::CancelOlderPipelinesService).not_to receive(:for)
        expect(Ci::PipelineCreation::CancelRedundantPipelinesService).not_to receive(:new)

        perform
      end
    end
  end
end
