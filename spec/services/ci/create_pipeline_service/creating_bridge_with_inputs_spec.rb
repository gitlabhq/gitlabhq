# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating bridge with inputs', feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let_it_be(:spec_inputs_config) do
    <<~YAML
      spec:
        inputs:
          stage:
            default: deploy
          suffix:
            default: job
      ---
      test-$[[ inputs.suffix ]]:
        stage: $[[ inputs.stage ]]
        script: run tests
    YAML
  end

  let_it_be(:trigger_config) do
    <<~YAML
      microservice:
        trigger:
          include:
            - local: 'child.yml'
              inputs:
                stage: 'deploy'
                suffix: 'build'
    YAML
  end

  before_all do
    project.repository.create_file(user, '.gitlab-ci.yml', trigger_config, message: 'spec inputs',
      branch_name: 'master')
    project.repository.create_file(user, 'child.yml', spec_inputs_config, message: 'spec inputs',
      branch_name: 'master')
    project.add_maintainer(user)
  end

  context 'when a trigger job contains inputs', :sidekiq_inline do
    it 'creates a pipeline with a trigger job containing the inputs' do
      response = ::Ci::CreatePipelineService.new(project, user, { ref: project.default_branch }).execute(:push)
      pipeline = response.payload
      bridge = pipeline.bridges.first

      expect(response).to be_success
      expect(bridge.status).to eq('success')
      expect(bridge.name).to eq('microservice')
      expect(bridge.options.dig(:trigger, :include).first[:inputs]).to eq({ stage: 'deploy', suffix: 'build' })
    end
  end
end
