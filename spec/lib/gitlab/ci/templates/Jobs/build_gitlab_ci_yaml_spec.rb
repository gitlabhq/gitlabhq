# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs/Build.gitlab-ci.yml' do
  include Ci::TemplateHelpers

  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Jobs/Build') }

  describe 'AUTO_BUILD_IMAGE_VERSION' do
    it 'corresponds to a published image in the registry',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448357' do
      registry = "https://#{template_registry_host}"
      repository = auto_build_image_repository
      reference = YAML.safe_load(template.content).dig('variables', 'AUTO_BUILD_IMAGE_VERSION')

      expect(public_image_exist?(registry, repository, reference)).to be true
    end
  end

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }

    let(:default_branch) { 'master' }
    let(:pipeline_ref) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'on master' do
      it 'creates the build job' do
        expect(build_names).to contain_exactly('build')
      end
    end

    context 'on another branch' do
      let(:pipeline_ref) { 'feature' }

      it 'creates the build job' do
        expect(build_names).to contain_exactly('build')
      end
    end

    context 'on tag' do
      let(:pipeline_ref) { 'v1.0.0' }

      it 'creates the build job' do
        expect(pipeline).to be_tag
        expect(build_names).to contain_exactly('build')
      end
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
