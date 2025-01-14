# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Flutter.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Flutter') }

  describe 'the created pipeline' do
    let(:pipeline_branch) { 'master' }
    let(:project) { create(:project, :custom_repo, files: { 'README.md' => '' }) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
    end

    it 'creates test and code_quality jobs' do
      expect(build_names).to include('test', 'code_quality')
    end
  end
end
