# frozen_string_literal: true

require 'spec_helper'

describe Ci::ExpirePipelineCacheService do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }
  subject { described_class.new }

  describe '#execute' do
    it 'invalidates Etag caching for project pipelines path' do
      pipelines_path = "/#{project.full_path}/pipelines.json"
      new_mr_pipelines_path = "/#{project.full_path}/merge_requests/new.json"
      pipeline_path = "/#{project.full_path}/pipelines/#{pipeline.id}.json"

      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(pipelines_path)
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(new_mr_pipelines_path)
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(pipeline_path)

      subject.execute(pipeline)
    end

    it 'invalidates Etag caching for merge request pipelines if pipeline runs on any commit of that source branch' do
      pipeline = create(:ci_empty_pipeline, status: 'created', project: project, ref: 'master')
      merge_request = create(:merge_request, source_project: project, source_branch: pipeline.ref)
      merge_request_pipelines_path = "/#{project.full_path}/merge_requests/#{merge_request.iid}/pipelines.json"

      allow_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch)
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(merge_request_pipelines_path)

      subject.execute(pipeline)
    end

    it 'updates the cached status for a project' do
      expect(Gitlab::Cache::Ci::ProjectPipelineStatus).to receive(:update_for_pipeline)
                                                            .with(pipeline)

      subject.execute(pipeline)
    end

    context 'destroyed pipeline' do
      let(:project_with_repo) { create(:project, :repository) }
      let!(:pipeline_with_commit) { create(:ci_pipeline, :success, project: project_with_repo, sha: project_with_repo.commit.id) }

      it 'clears the cache', :use_clean_rails_memory_store_caching do
        create(:commit_status, :success, pipeline: pipeline_with_commit, ref: pipeline_with_commit.ref)

        # Sanity check
        expect(project_with_repo.pipeline_status.has_status?).to be_truthy

        subject.execute(pipeline_with_commit, delete: true)

        pipeline_with_commit.destroy!

        # Need to use find to avoid memoization
        expect(Project.find(project_with_repo.id).pipeline_status.has_status?).to be_falsey
      end
    end
  end
end
