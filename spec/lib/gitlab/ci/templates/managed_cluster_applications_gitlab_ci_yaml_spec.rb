# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Managed-Cluster-Applications.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Managed-Cluster-Applications') }

  describe 'the created pipeline' do
    let_it_be(:user) { create(:user) }

    let(:project) { create(:project, :custom_repo, namespace: user.namespace, files: { 'README.md' => '' }) }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch ) }
    let(:pipeline) { service.execute!(:push) }
    let(:build_names) { pipeline.builds.pluck(:name) }
    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }

    before do
      stub_ci_pipeline_yaml_file(template.content)
    end

    context 'for a default branch' do
      it 'creates a apply job' do
        expect(build_names).to match_array('apply')
      end
    end

    context 'outside of default branch' do
      let(:pipeline_branch) { 'a_branch' }

      before do
        project.repository.create_branch(pipeline_branch, default_branch)
      end

      it 'has no jobs' do
        expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError, 'No stages / jobs for this pipeline.')
      end
    end
  end
end
