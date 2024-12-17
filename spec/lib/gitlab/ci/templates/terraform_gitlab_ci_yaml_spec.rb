# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform.gitlab-ci.yml' do
  before do
    allow(Gitlab::Template::GitlabCiYmlTemplate).to receive(:excluded_patterns).and_return([])
  end

  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Terraform') }

  describe 'the created pipeline' do
    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }
    let_it_be(:project) { create(:project, :repository, create_branch: 'patch-1') }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |instance|
        allow(instance).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'on master branch' do
      it 'creates deprecation warning job' do
        expect(build_names).to include('deprecated-and-will-be-removed-in-18.0')
      end

      it 'creates init, validate,build terraform jobs as well as kics-iac-sast job', :aggregate_failures do
        expect(pipeline.errors).to be_empty
        expect(build_names).to include('kics-iac-sast', 'validate', 'build', 'deploy')
      end
    end

    context 'outside the master branch' do
      let(:pipeline_branch) { 'patch-1' }

      it 'creates deprecation warning job' do
        expect(build_names).to include('deprecated-and-will-be-removed-in-18.0')
      end

      it 'does not creates a deploy and a test job', :aggregate_failures do
        expect(pipeline.errors).to be_empty
        expect(build_names).not_to include('deploy')
      end
    end

    context 'on merge request' do
      let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
      let(:merge_request) { create(:merge_request, :simple, source_project: project) }
      let(:pipeline) { service.execute(merge_request).payload }

      it 'creates a pipeline with no jobs' do
        expect(pipeline).to be_merge_request_event
        expect(pipeline.builds.count).to be_zero
      end
    end
  end
end
