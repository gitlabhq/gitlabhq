# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Kaniko.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Kaniko') }

  describe 'the created pipeline' do
    let(:pipeline_branch) { 'master' }
    let(:project) { create(:project, :custom_repo, files: { 'Dockerfile' => 'FROM alpine:latest' }) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
    end

    it 'creates "kaniko-build" job' do
      expect(build_names).to include('kaniko-build')
    end
  end
end
