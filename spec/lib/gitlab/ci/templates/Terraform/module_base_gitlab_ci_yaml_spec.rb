# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform/Module-Base.gitlab-ci.yml', feature_category: :continuous_integration do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Terraform/Module-Base') }

  describe 'the created pipeline' do
    let(:default_branch) { 'main' }
    let(:pipeline_branch) { default_branch }
    let_it_be(:project) { create(:project, :custom_repo, files: { 'README.md' => '' }) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    it 'does not create any jobs' do
      expect(build_names).to be_empty
    end
  end
end
