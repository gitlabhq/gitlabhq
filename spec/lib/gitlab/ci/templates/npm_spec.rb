# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'npm.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('npm') }

  describe 'the created pipeline' do
    let(:repo_files) { { 'package.json' => '{}', 'README.md' => '' } }
    let(:modified_files) { %w[package.json] }
    let(:project) { create(:project, :custom_repo, files: repo_files) }
    let(:user) { project.owner }
    let(:pipeline_branch) { project.default_branch }
    let(:pipeline_tag) { 'v1.2.1' }
    let(:pipeline_ref) { pipeline_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref ) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    def create_branch(name:)
      ::Branches::CreateService.new(project, user).execute(name, project.default_branch)
    end

    def create_tag(name:)
      ::Tags::CreateService.new(project, user).execute(name, project.default_branch, nil)
    end

    before do
      stub_ci_pipeline_yaml_file(template.content)

      create_branch(name: pipeline_branch)
      create_tag(name: pipeline_tag)

      allow_any_instance_of(Ci::Pipeline).to receive(:modified_paths).and_return(modified_files)
    end

    shared_examples 'publish job created' do
      it 'creates a pipeline with a single job: publish' do
        expect(build_names).to eq(%w[publish])
      end
    end

    shared_examples 'no pipeline created' do
      it 'does not create a pipeline because the only job (publish) is not created' do
        expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError, 'No stages / jobs for this pipeline.')
      end
    end

    context 'on default branch' do
      context 'when package.json has been changed' do
        it_behaves_like 'publish job created'
      end

      context 'when package.json does not exist or has not been changed' do
        let(:modified_files) { %w[README.md] }

        it_behaves_like 'no pipeline created'
      end
    end

    %w[v1.0.0 v2.1.0-alpha].each do |valid_version|
      context "when the branch name is #{valid_version}" do
        let(:pipeline_branch) { valid_version }

        it_behaves_like 'publish job created'
      end

      context "when the tag name is #{valid_version}" do
        let(:pipeline_tag) { valid_version }
        let(:pipeline_ref) { pipeline_tag }

        it_behaves_like 'publish job created'
      end
    end

    %w[patch-1 my-feature-branch v1 v1.0 2.1.0].each do |invalid_version|
      context "when the branch name is #{invalid_version}" do
        let(:pipeline_branch) { invalid_version }

        it_behaves_like 'no pipeline created'
      end

      context "when the tag name is #{invalid_version}" do
        let(:pipeline_tag) { invalid_version }
        let(:pipeline_ref) { pipeline_tag }

        it_behaves_like 'no pipeline created'
      end
    end
  end
end
