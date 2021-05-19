# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExpirePipelineCacheService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  subject { described_class.new }

  describe '#execute' do
    it 'invalidates Etag caching for project pipelines path' do
      pipelines_path = "/#{project.full_path}/-/pipelines.json"
      new_mr_pipelines_path = "/#{project.full_path}/-/merge_requests/new.json"
      pipeline_path = "/#{project.full_path}/-/pipelines/#{pipeline.id}.json"
      graphql_pipeline_path = "/api/graphql:pipelines/id/#{pipeline.id}"
      graphql_pipeline_sha_path = "/api/graphql:pipelines/sha/#{pipeline.sha}"

      expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
        expect(store).to receive(:touch).with(pipelines_path)
        expect(store).to receive(:touch).with(new_mr_pipelines_path)
        expect(store).to receive(:touch).with(pipeline_path)
        expect(store).to receive(:touch).with(graphql_pipeline_path)
        expect(store).to receive(:touch).with(graphql_pipeline_sha_path)
      end

      subject.execute(pipeline)
    end

    it 'invalidates Etag caching for merge request pipelines if pipeline runs on any commit of that source branch' do
      merge_request = create(:merge_request, :with_detached_merge_request_pipeline)
      project = merge_request.target_project

      merge_request_pipelines_path = "/#{project.full_path}/-/merge_requests/#{merge_request.iid}/pipelines.json"
      merge_request_widget_path = "/#{project.full_path}/-/merge_requests/#{merge_request.iid}/cached_widget.json"

      allow_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch)
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(merge_request_pipelines_path)
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(merge_request_widget_path)

      subject.execute(merge_request.all_pipelines.last)
    end

    it 'updates the cached status for a project' do
      expect(Gitlab::Cache::Ci::ProjectPipelineStatus).to receive(:update_for_pipeline).with(pipeline)

      subject.execute(pipeline)
    end

    context 'destroyed pipeline' do
      let(:project_with_repo) { create(:project, :repository) }
      let!(:pipeline_with_commit) { create(:ci_pipeline, :success, project: project_with_repo, sha: project_with_repo.commit.id) }

      it 'clears the cache', :use_clean_rails_redis_caching do
        create(:commit_status, :success, pipeline: pipeline_with_commit, ref: pipeline_with_commit.ref)

        # Sanity check
        expect(project_with_repo.pipeline_status.has_status?).to be_truthy

        subject.execute(pipeline_with_commit, delete: true)

        pipeline_with_commit.destroy!

        # We need to reset lazy_latest_pipeline cache to simulate a new request
        BatchLoader::Executor.clear_current

        # Need to use find to avoid memoization
        expect(Project.find(project_with_repo.id).pipeline_status.has_status?).to be_falsey
      end
    end

    context 'when the pipeline is triggered by another pipeline' do
      let(:source) { create(:ci_sources_pipeline, pipeline: pipeline) }

      it 'updates the cache of dependent pipeline' do
        dependent_pipeline_path = "/#{source.source_project.full_path}/-/pipelines/#{source.source_pipeline.id}.json"

        expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
          allow(store).to receive(:touch)
          expect(store).to receive(:touch).with(dependent_pipeline_path)
        end

        subject.execute(pipeline)
      end
    end

    context 'when the pipeline triggered another pipeline' do
      let(:build) { create(:ci_build, pipeline: pipeline) }
      let(:source) { create(:ci_sources_pipeline, source_job: build) }

      it 'updates the cache of dependent pipeline' do
        dependent_pipeline_path = "/#{source.project.full_path}/-/pipelines/#{source.pipeline.id}.json"

        expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
          allow(store).to receive(:touch)
          expect(store).to receive(:touch).with(dependent_pipeline_path)
        end

        subject.execute(pipeline)
      end
    end
  end
end
