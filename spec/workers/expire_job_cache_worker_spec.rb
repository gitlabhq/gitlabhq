# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExpireJobCacheWorker do
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }

  let(:project) { pipeline.project }

  describe '#perform' do
    context 'with a job in the pipeline' do
      let_it_be(:job) { create(:ci_build, pipeline: pipeline) }

      let(:job_args) { job.id }

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

      it_behaves_like 'worker with data consistency',
        described_class,
        feature_flag: :load_balancing_for_expire_job_cache_worker,
        data_consistency: :delayed
    end

    context 'when there is no job in the pipeline' do
      it 'does not change the etag store' do
        expect(Gitlab::EtagCaching::Store).not_to receive(:new)

        perform_multiple(non_existing_record_id)
      end
    end
  end
end
