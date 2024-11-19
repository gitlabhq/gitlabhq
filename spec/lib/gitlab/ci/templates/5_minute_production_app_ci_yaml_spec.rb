# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '5-Minute-Production-App.gitlab-ci.yml', feature_category: :not_owned do # rubocop:disable RSpec/FeatureCategory -- removing code in https://gitlab.com/gitlab-org/gitlab/-/issues/478491
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('5-Minute-Production-App') }

  describe 'the created pipeline' do
    let_it_be_with_refind(:project) { create(:project, :auto_devops, :custom_repo, files: { 'README.md' => '' }) }

    let(:user) { project.first_owner }
    let(:default_branch) { 'master' }
    let(:pipeline_branch) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
    end

    it 'creates only build job' do
      expect(build_names).to match_array('build')
    end

    context 'when AWS variables are set' do
      def create_ci_variable(key, value)
        create(:ci_variable, project: project, key: key, value: value)
      end

      before do
        create_ci_variable('AWS_ACCESS_KEY_ID', 'AKIAIOSFODNN7EXAMPLE')
        create_ci_variable('AWS_SECRET_ACCESS_KEY', 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY')
        create_ci_variable('AWS_DEFAULT_REGION', 'us-west-2')
      end

      it 'creates all jobs' do
        expect(build_names).to match_array(%w[build terraform_apply deploy terraform_destroy])
      end

      context 'when pipeline branch is protected' do
        before do
          create(:protected_branch, project: project, name: pipeline_branch)
        end

        it 'does not create a destroy job' do
          expect(build_names).to match_array(%w[build terraform_apply deploy])
        end
      end
    end
  end
end
