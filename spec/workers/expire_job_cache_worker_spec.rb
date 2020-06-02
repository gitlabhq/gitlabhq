# frozen_string_literal: true

require 'spec_helper'

describe ExpireJobCacheWorker do
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }
  let(:project) { pipeline.project }

  describe '#perform' do
    context 'with a job in the pipeline' do
      let(:job) { create(:ci_build, pipeline: pipeline) }
      let(:job_args) { job.id }

      include_examples 'an idempotent worker' do
        it 'invalidates Etag caching for the job path' do
          pipeline_path = "/#{project.full_path}/-/pipelines/#{pipeline.id}.json"
          job_path = "/#{project.full_path}/builds/#{job.id}.json"

          spy_store = Gitlab::EtagCaching::Store.new

          allow(Gitlab::EtagCaching::Store).to receive(:new) { spy_store }

          expect(spy_store).to receive(:touch)
            .exactly(worker_exec_times).times
            .with(pipeline_path)
            .and_call_original

          expect(spy_store).to receive(:touch)
            .exactly(worker_exec_times).times
            .with(job_path)
            .and_call_original

          subject
        end
      end
    end

    context 'when there is no job in the pipeline' do
      it 'does not change the etag store' do
        expect(Gitlab::EtagCaching::Store).not_to receive(:new)

        perform_multiple(non_existing_record_id)
      end
    end
  end
end
