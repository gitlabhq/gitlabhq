# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform.latest.gitlab-ci.yml' do
  before do
    allow(Gitlab::Template::GitlabCiYmlTemplate).to receive(:excluded_patterns).and_return([])
  end

  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Terraform.latest') }

  describe 'the created pipeline' do
    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }
    let(:project) { create(:project, :custom_repo, files: { 'README.md' => '' }) }
    let(:user) { project.owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch ) }
    let(:pipeline) { service.execute!(:push) }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'on master branch' do
      it 'creates init, validate and build jobs' do
        expect(build_names).to include('init', 'validate', 'build', 'deploy')
      end
    end

    context 'outside the master branch' do
      let(:pipeline_branch) { 'patch-1' }

      before do
        project.repository.create_branch(pipeline_branch, default_branch)
      end

      it 'does not creates a deploy and a test job' do
        expect(build_names).not_to include('deploy')
      end
    end
  end
end
