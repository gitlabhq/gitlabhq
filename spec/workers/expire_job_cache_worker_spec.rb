# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExpireJobCacheWorker do
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }

  let(:project) { pipeline.project }

  describe '#perform' do
    context 'with a job in the pipeline' do
      let_it_be(:job) { create(:ci_build, pipeline: pipeline) }

      let(:job_args) { job.id }

      include_examples 'an idempotent worker' do
        it 'invalidates Etag caching for the job path' do
          job_path = "/#{project.full_path}/builds/#{job.id}.json"

          spy_store = Gitlab::EtagCaching::Store.new

          allow(Gitlab::EtagCaching::Store).to receive(:new) { spy_store }

          expect(spy_store).to receive(:touch)
            .exactly(worker_exec_times).times
            .with(job_path)
            .and_call_original

          expect(ExpirePipelineCacheWorker).to receive(:perform_async)
            .with(pipeline.id)
            .exactly(worker_exec_times).times

          subject
        end
      end

      it 'does not perform extra queries', :aggregate_failures do
        worker = described_class.new
        recorder = ActiveRecord::QueryRecorder.new { worker.perform(job.id) }

        occurences = recorder.data.values.flat_map {|v| v[:occurrences]}
        project_queries = occurences.select {|s| s.include?('FROM "projects"')}
        namespace_queries = occurences.select {|s| s.include?('FROM "namespaces"')}
        route_queries = occurences.select {|s| s.include?('FROM "routes"')}

        # This worker is run 1 million times an hour, so we need to save as much
        # queries as possible.
        expect(recorder.count).to be <= 1

        expect(project_queries.size).to eq(0)
        expect(namespace_queries.size).to eq(0)
        expect(route_queries.size).to eq(0)
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
