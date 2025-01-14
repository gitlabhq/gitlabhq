# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MATLAB.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('MATLAB') }

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :auto_devops, :custom_repo, files: { 'README.md' => '' }) }

    let(:user) { project.first_owner }
    let(:default_branch) { 'master' }
    let(:pipeline_branch) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
    end

    it 'creates all jobs' do
      expect(build_names).to include('command', 'test', 'test_artifacts', 'build')
    end
  end
end
