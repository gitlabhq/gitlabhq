require 'spec_helper'

describe Ci::CreatePipelineBuildsService, services: true do
  let(:project) { create(:ci_project) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit.id) }
  # let(:)
end
