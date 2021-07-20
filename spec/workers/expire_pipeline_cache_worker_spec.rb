# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExpirePipelineCacheWorker do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  subject { described_class.new }

  describe '#perform' do
    it 'executes the service' do
      expect_next_instance_of(Ci::ExpirePipelineCacheService) do |instance|
        expect(instance).to receive(:execute).with(pipeline).and_call_original
      end

      subject.perform(pipeline.id)
    end

    it 'does not perform extra queries', :aggregate_failures do
      recorder = ActiveRecord::QueryRecorder.new { subject.perform(pipeline.id) }

      project_queries = recorder.data.values.flat_map {|v| v[:occurrences]}.select {|s| s.include?('FROM "projects"')}
      namespace_queries = recorder.data.values.flat_map {|v| v[:occurrences]}.select {|s| s.include?('FROM "namespaces"')}
      route_queries = recorder.data.values.flat_map {|v| v[:occurrences]}.select {|s| s.include?('FROM "routes"')}

      # This worker is run 1 million times an hour, so we need to save as much
      # queries as possible.
      expect(recorder.count).to be <= 6

      # These arises from #update_etag_cache
      expect(project_queries.size).to eq(1)
      expect(namespace_queries.size).to eq(1)
      expect(route_queries.size).to eq(1)
    end

    it "doesn't do anything if the pipeline not exist" do
      expect_any_instance_of(Ci::ExpirePipelineCacheService).not_to receive(:execute)
      expect_any_instance_of(Gitlab::EtagCaching::Store).not_to receive(:touch)

      subject.perform(617748)
    end

    skip "with https://gitlab.com/gitlab-org/gitlab/-/issues/325291 resolved" do
      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [pipeline.id] }
      end
    end

    it_behaves_like 'worker with data consistency',
                  described_class,
                  data_consistency: :delayed
  end
end
