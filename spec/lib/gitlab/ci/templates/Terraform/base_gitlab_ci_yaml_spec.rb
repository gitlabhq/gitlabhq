# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform/Base.gitlab-ci.yml' do
  subject(:template) do
    <<~YAML
      stages: [test]

      include:
        - template: 'Terraform/Base.gitlab-ci.yml'

      placeholder:
        script:
          - keep pipeline validator happy by having a job when stages are intentionally empty
    YAML
  end

  describe 'the created pipeline' do
    let(:default_branch) { 'master' }
    let(:pipeline_branch) { default_branch }
    let(:project) { create(:project, :custom_repo, files: { 'README.md' => '' }) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    it 'creates deprecation warning job' do
      expect(build_names).to include('deprecated-and-will-be-removed-in-18.0')
    end
  end
end
