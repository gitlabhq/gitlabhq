# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BuildArtifactsController, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:ci_build) { create(:ci_build, :artifacts, project: project) }

  describe '#download' do
    it 'redirects' do
      get download_project_build_artifacts_path(project, ci_build, query_parameter: 1)

      expect(response).to redirect_to download_project_job_artifacts_path(project, ci_build, query_parameter: 1)
    end
  end

  describe '#browse' do
    it 'redirects' do
      get browse_project_build_artifacts_path(project, ci_build, path: 'test')

      expect(response).to redirect_to browse_project_job_artifacts_path(project, ci_build, path: 'test')
    end
  end

  describe '#file' do
    it 'redirects' do
      get file_project_build_artifacts_path(project, ci_build, path: 'test')

      expect(response).to redirect_to file_project_job_artifacts_path(project, ci_build, path: 'test')
    end
  end

  describe '#raw' do
    it 'redirects' do
      get raw_project_build_artifacts_path(project, ci_build, path: 'test')

      expect(response).to redirect_to raw_project_job_artifacts_path(project, ci_build, path: 'test')
    end
  end
end
