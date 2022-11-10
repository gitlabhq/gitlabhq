# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Verify/Load-Performance-Testing.gitlab-ci.yml' do
  subject(:template) do
    <<~YAML
      stages:
        - test
        - performance

      include:
        - template: 'Verify/Load-Performance-Testing.gitlab-ci.yml'

      placeholder:
        script:
          - keep pipeline validator happy by having a job when stages are intentionally empty
    YAML
  end

  describe 'the created pipeline' do
    let(:project) { create(:project, :repository) }
    let(:user) { project.first_owner }

    let(:default_branch) { 'master' }
    let(:pipeline_ref) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template)

      allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    it 'has no errors' do
      expect(pipeline.errors).to be_empty
    end

    shared_examples_for 'load_performance job on tag or branch' do
      it 'by default' do
        expect(build_names).to include('load_performance')
      end
    end

    context 'on master' do
      it_behaves_like 'load_performance job on tag or branch'
    end

    context 'on another branch' do
      let(:pipeline_ref) { 'feature' }

      it_behaves_like 'load_performance job on tag or branch'
    end

    context 'on tag' do
      let(:pipeline_ref) { 'v1.0.0' }

      it_behaves_like 'load_performance job on tag or branch'
    end

    context 'on merge request' do
      let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
      let(:merge_request) { create(:merge_request, :simple, source_project: project) }
      let(:pipeline) { service.execute(merge_request).payload }

      it 'has no jobs' do
        expect(pipeline).to be_merge_request_event
        expect(build_names).to be_empty
      end
    end
  end
end
