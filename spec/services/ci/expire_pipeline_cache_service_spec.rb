require 'spec_helper'

describe Ci::ExpirePipelineCacheService, services: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  subject { described_class.new(project, user) }

  describe '#execute' do
    it 'invalidate Etag caching for project pipelines path' do
      path = "/#{project.full_path}/pipelines.json"

      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(path)

      subject.execute(pipeline)
    end
  end
end
