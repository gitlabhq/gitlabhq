# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Diffblue-Cover.gitlab-ci.yml', feature_category: :continuous_integration do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Diffblue-Cover') }

  describe 'the created pipeline' do
    let(:pipeline_branch) { 'patch-1' }
    let_it_be(:project) { create(:project, :repository, create_branch: 'patch-1') }
    let(:user) { project.first_owner }

    let(:mr_service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
    let(:merge_request) { create(:merge_request, :simple, source_project: project, source_branch: pipeline_branch) }
    let(:mr_pipeline) { mr_service.execute(merge_request).payload }
    let(:mr_build_names) { mr_pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
    end

    it 'creates diffblue-cover jobs' do
      expect(mr_build_names).to include('diffblue-cover')
    end
  end
end
