# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform.latest.gitlab-ci.yml', feature_category: :continuous_integration do
  include Ci::PipelineMessageHelpers

  before do
    allow(Gitlab::Template::GitlabCiYmlTemplate).to receive(:excluded_patterns).and_return([])
  end

  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Terraform.latest') }

  describe 'the created pipeline' do
    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }
    let_it_be(:project) { create(:project, :repository, create_branch: 'patch-1') }
    let_it_be(:user) { project.first_owner }
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

      it 'creates init, validate and build jobs', :aggregate_failures do
        expect(pipeline.errors).to be_empty
        expect(build_names).to include('validate', 'build', 'deploy')
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
      let(:pipeline_branch) { 'patch-1' }
      let(:mr_service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
      let(:merge_request) { create(:merge_request, :simple, source_project: project, source_branch: pipeline_branch) }
      let(:mr_pipeline) { mr_service.execute(merge_request).payload }
      let(:mr_build_names) { mr_pipeline.builds.pluck(:name) }
      let(:branch_service) { Ci::CreatePipelineService.new(project, user, ref: merge_request.source_branch) }
      let(:branch_pipeline) { branch_service.execute(:push).payload }
      let(:branch_build_names) { branch_pipeline.builds.pluck(:name) }

      it 'creates deprecation warning job' do
        expect(build_names).to include('deprecated-and-will-be-removed-in-18.0')
      end

      # This is needed so that the terraform artifacts and sast_iac artifacts
      # are both available in the MR
      it 'creates a pipeline with the terraform and sast_iac jobs' do
        expect(mr_pipeline).to be_merge_request_event
        expect(mr_pipeline.errors.full_messages).to be_empty
        expect(mr_build_names).to include('kics-iac-sast', 'validate', 'build')
      end

      it 'does not creates a deploy', :aggregate_failures do
        expect(mr_build_names).not_to include('deploy')
      end

      it 'does not create a branch pipeline', :aggregate_failures do
        expect(branch_build_names).to be_empty
        expect(branch_pipeline.errors.full_messages).to match_array(
          [sanitize_message(Ci::Pipeline.rules_failure_message)]
        )
      end
    end
  end
end
