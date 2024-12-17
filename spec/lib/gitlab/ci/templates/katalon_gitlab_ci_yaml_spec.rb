# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Katalon.gitlab-ci.yml' do
  subject(:template) do
    <<~YAML
      include:
        - template: 'Katalon.gitlab-ci.yml'

      katalon_tests_placeholder:
        extends: .katalon_tests
        stage: test
        script:
          - echo "katalon tests"

      katalon_tests_with_artifacts_placeholder:
        extends: .katalon_tests_with_artifacts
        stage: test
        script:
          - echo "katalon tests with artifacts"
    YAML
  end

  describe 'the created pipeline' do
    let(:project) { create(:project, :custom_repo, files: { 'README.md' => '' }) }
    let(:user) { project.first_owner }

    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master') }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template)
    end

    it 'create katalon tests jobs' do
      expect(build_names).to match_array(%w[katalon_tests_placeholder katalon_tests_with_artifacts_placeholder])

      expect(pipeline.builds.find_by(name: 'katalon_tests_placeholder').options).to include(
        image: { name: 'katalonstudio/katalon' },
        services: [{ name: 'docker:dind' }]
      )

      expect(pipeline.builds.find_by(name: 'katalon_tests_with_artifacts_placeholder').options).to include(
        image: { name: 'katalonstudio/katalon' },
        services: [{ name: 'docker:dind' }],
        artifacts: { when: 'always', paths: ['Reports/'], reports: { junit: ['Reports/*/*/*/*.xml'] } }
      )
    end
  end
end
