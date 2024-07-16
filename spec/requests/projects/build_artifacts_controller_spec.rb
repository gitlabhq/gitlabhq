# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BuildArtifactsController, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:ci_build) { create(:ci_build, :artifacts, project: project) }

  describe '#browse' do
    it 'redirects' do
      get browse_project_build_artifacts_path(project, ci_build, ref_name_and_path: 'test')

      expect(response).to redirect_to browse_project_job_artifacts_path(project, ci_build)
    end
  end
end
