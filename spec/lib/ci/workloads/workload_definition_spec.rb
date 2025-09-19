# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Workloads::WorkloadDefinition, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let(:image) { 'test_docker_image' }
  let(:source) { :duo_workflow }
  let(:commands) { ['echo hello world'] }
  let(:variables) { { 'MY_ENV_VAR' => 'my env var value' } }

  subject(:definition) do
    described_class.new
  end

  before do
    definition.image = image
    definition.commands = commands
    definition.variables = variables
  end

  describe '#to_job_hash' do
    it 'builds a workload_definition' do
      expect(definition.to_job_hash).to eq({
        image: image,
        stage: "build",
        variables: {
          "MY_ENV_VAR" => {
            value: "my env var value",
            expand: false
          }
        },
        script: commands,
        timeout: "7200 seconds"
      })
    end

    it 'builds a workload_definition that can be run by RunWorkloadService' do
      run_service = Ci::Workloads::RunWorkloadService
        .new(project: project, current_user: user, source: source, workload_definition: definition)

      result = run_service.execute
      expect(result).to be_success
      expect(result.payload).to be_a(Ci::Workloads::Workload)
      expect(result.payload.id).to be_present
    end

    it 'allows setting artifacts_paths' do
      definition.artifacts_paths = ['my-artifact-path']
      expect(definition.to_job_hash[:artifacts]).to eq({
        paths: ['my-artifact-path']
      })
    end

    it 'allows setting cache' do
      cache_config = { key: 'my-cache-key', paths: ['node_modules'] }
      definition.cache = cache_config
      expect(definition.to_job_hash[:cache]).to eq(cache_config)
    end

    it 'does not include cache when cache is nil' do
      definition.cache = nil
      expect(definition.to_job_hash).not_to have_key(:cache)
    end

    it 'does not include cache when cache is empty hash' do
      definition.cache = {}
      expect(definition.to_job_hash).not_to have_key(:cache)
    end

    it 'raises ArgumentError if image is not present' do
      definition.image = ''
      expect { definition.to_job_hash }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError if commands is empty' do
      definition.image = []
      expect { definition.to_job_hash }.to raise_error(ArgumentError)
    end
  end

  describe '#add_variable' do
    it 'adds a variable to the workload_definition' do
      definition.add_variable('NEW_VAR', 'new_var_value')
      expect(definition.to_job_hash[:variables]).to include({
        "NEW_VAR" => { value: "new_var_value", expand: false }
      })
    end
  end
end
