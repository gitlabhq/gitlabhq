require 'spec_helper'

describe Ci::ExpirePipelineCacheService, services: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  subject { described_class.new(project, user) }

  describe '#execute' do
    it 'invalidate Etag caching for project pipelines path' do
      pipelines_path = "/#{project.full_path}/pipelines.json"
      new_mr_pipelines_path = "/#{project.full_path}/merge_requests/new.json"

      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(pipelines_path)
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(new_mr_pipelines_path)

      subject.execute(pipeline)
    end

    it 'updates the cached status for a project' do
      expect(Gitlab::Cache::Ci::ProjectPipelineStatus).to receive(:update_for_pipeline).
                                                            with(pipeline)

      subject.execute(pipeline)
    end
  end
end
