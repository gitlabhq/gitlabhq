# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform-Module.gitlab-ci.yml', feature_category: :continuous_integration do
  before do
    allow(Gitlab::Template::GitlabCiYmlTemplate).to receive(:excluded_patterns).and_return([])
  end

  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Terraform-Module') }

  shared_examples 'on any branch' do
    it 'creates kics job', :aggregate_failures do
      expect(pipeline.errors).to be_empty
      expect(build_names).to include('kics-iac-sast')
    end

    it 'does not create a deploy job', :aggregate_failures do
      expect(pipeline.errors).to be_empty
      expect(build_names).not_to include('deploy')
    end
  end

  let_it_be(:project) { create(:project, :repository, create_branch: 'patch-1', create_tag: '1.0.0') }
  let_it_be(:user) { project.first_owner }

  describe 'the created pipeline' do
    let(:default_branch) { project.default_branch_or_main }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |instance|
        allow(instance).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when on default branch' do
      let(:pipeline_ref) { default_branch }

      it_behaves_like 'on any branch'
    end

    context 'when outside the default branch' do
      let(:pipeline_ref) { 'patch-1' }

      it_behaves_like 'on any branch'
    end

    context 'when on tag' do
      let(:pipeline_ref) { '1.0.0' }

      it 'creates deploy job', :aggregate_failures do
        expect(pipeline.errors).to be_empty
        expect(build_names).to include('deploy')
      end
    end
  end
end
