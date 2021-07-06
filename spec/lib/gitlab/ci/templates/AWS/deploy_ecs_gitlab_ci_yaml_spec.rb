# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deploy-ECS.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('AWS/Deploy-ECS') }

  describe 'the created pipeline' do
    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }
    let(:project) { create(:project, :auto_devops, :custom_repo, files: { 'README.md' => '' }) }
    let(:user) { project.owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch ) }
    let(:pipeline) { service.execute!(:push) }
    let(:build_names) { pipeline.builds.pluck(:name) }
    let(:platform_target) { 'ECS' }

    before do
      create(:ci_variable, project: project, key: 'AUTO_DEVOPS_PLATFORM_TARGET', value: platform_target)
      stub_ci_pipeline_yaml_file(template.content)
      allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    shared_examples 'no pipeline yaml error' do
      it 'does not have any error' do
        expect(pipeline.has_yaml_errors?).to be_falsey
      end
    end

    it_behaves_like 'no pipeline yaml error'

    it 'creates the expected jobs' do
      expect(build_names).to include('production_ecs')
    end

    context 'when running a pipeline for a branch' do
      let(:pipeline_branch) { 'test_branch' }

      before do
        project.repository.create_branch(pipeline_branch, default_branch)
      end

      it_behaves_like 'no pipeline yaml error'

      it 'creates the expected jobs' do
        expect(build_names).to include('review_ecs', 'stop_review_ecs')
      end

      context 'when deploying to ECS Fargate' do
        let(:platform_target) { 'FARGATE' }

        it 'creates the expected jobs' do
          expect(build_names).to include('review_fargate', 'stop_review_fargate')
        end
      end
    end
  end
end
