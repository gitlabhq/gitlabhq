# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pages/Zola.gitlab-ci.yml', feature_category: :pages do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Pages/Zola') }

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :repository) }

    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: project.default_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
    end

    it 'creates "pages" job' do
      expect(build_names).to include('pages')
    end
  end
end
