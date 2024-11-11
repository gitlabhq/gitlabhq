# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExpirePipelineCacheService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:merge_pipeline) { create(:ci_pipeline, :detached_merge_request_pipeline, project: project) }

  subject { described_class.new }

  describe '#execute' do
    it 'invalidates Etag caching for project pipelines path' do
      pipelines_path = "/#{project.full_path}/-/pipelines.json"
      new_mr_pipelines_path = "/#{project.full_path}/-/merge_requests/new.json"
      pipeline_path = "/#{project.full_path}/-/pipelines/#{pipeline.id}.json"
      graphql_pipeline_path = "/api/graphql:pipelines/id/#{pipeline.id}"
      graphql_pipeline_sha_path = "/api/graphql:pipelines/sha/#{pipeline.sha}"
      graphql_project_on_demand_scan_counts_path = "/api/graphql:on_demand_scan/counts/#{project.full_path}"

      expect_touched_etag_caching_paths(
        pipelines_path,
        new_mr_pipelines_path,
        pipeline_path,
        graphql_pipeline_path,
        graphql_pipeline_sha_path,
        graphql_project_on_demand_scan_counts_path
      )

      subject.execute(pipeline)
    end

    it 'invalidates Etag caching for merge request pipelines if pipeline runs on any commit of that source branch' do
      merge_request = create(:merge_request, :with_detached_merge_request_pipeline)
      project = merge_request.target_project

      merge_request_pipelines_path = "/#{project.full_path}/-/merge_requests/#{merge_request.iid}/pipelines.json"
      merge_request_widget_path = "/#{project.full_path}/-/merge_requests/#{merge_request.iid}/cached_widget.json"

      expect_touched_etag_caching_paths(
        merge_request_pipelines_path,
        merge_request_widget_path
      )

      subject.execute(merge_request.all_pipelines.last)
    end

    it 'invalidates Etag caching for merge request that pipeline runs on its merged commit' do
      merge_request = create(:merge_request, merge_commit_sha: pipeline.sha, source_project: pipeline.project)
      project = merge_request.target_project

      merge_request_widget_path = "/#{project.full_path}/-/merge_requests/#{merge_request.iid}/cached_widget.json"

      expect_touched_etag_caching_paths(merge_request_widget_path)

      subject.execute(pipeline)
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

        expect_touched_etag_caching_paths(dependent_pipeline_path)

        subject.execute(pipeline)
      end
    end

    context 'when the pipeline triggered another pipeline' do
      let(:build) { create(:ci_build, pipeline: pipeline) }
      let(:source) { create(:ci_sources_pipeline, source_job: build) }

      it 'updates the cache of dependent pipeline' do
        dependent_pipeline_path = "/#{source.project.full_path}/-/pipelines/#{source.pipeline.id}.json"

        expect_touched_etag_caching_paths(dependent_pipeline_path)

        subject.execute(pipeline)
      end
    end

    it 'does not do N+1 queries' do
      subject.execute(pipeline)

      control = ActiveRecord::QueryRecorder.new { subject.execute(pipeline) }

      create(:ci_sources_pipeline, pipeline: pipeline)
      create(:ci_sources_pipeline, source_job: create(:ci_build, pipeline: pipeline, ci_stage: create(:ci_stage)))

      expect { subject.execute(pipeline) }.not_to exceed_query_limit(control)
    end
  end

  context 'when pipeline does not have sha' do
    let(:pipeline_without_sha) { create(:ci_pipeline, project: project) }

    before do
      pipeline_without_sha.update_column(:sha, nil)
    end

    it 'does not raise an error' do
      expect { subject.execute(pipeline_without_sha) }.not_to raise_error
    end
  end

  context 'when pipeline does not have commit' do
    let(:pipeline_without_commit) { create(:ci_pipeline, project: project) }

    before do
      allow(pipeline_without_commit).to receive(:commit).and_return(nil)
    end

    it 'does not raise an error' do
      expect { subject.execute(pipeline_without_commit) }.not_to raise_error
    end
  end

  def expect_touched_etag_caching_paths(*paths)
    expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
      expect(store).to receive(:touch).and_wrap_original do |m, *args|
        expect(args).to include(*paths)

        m.call(*args)
      end
    end
  end
end
