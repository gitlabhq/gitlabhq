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

    it 'allows setting tags' do
      definition.tags = %w[special-runner-1 special-runner-2]
      expect(definition.to_job_hash[:tags]).to eq(%w[special-runner-1 special-runner-2])
    end

    it 'does not include tags when tags is nil' do
      definition.tags = nil
      expect(definition.to_job_hash).not_to have_key(:tags)
    end

    it 'raises ArgumentError if image is not present' do
      definition.image = ''
      expect { definition.to_job_hash }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError if commands is empty' do
      definition.image = []
      expect { definition.to_job_hash }.to raise_error(ArgumentError)
    end

    describe '#add_variable' do
      it 'adds a variable to the workload_definition' do
        definition.add_variable('NEW_VAR', 'new_var_value')
        expect(definition.to_job_hash[:variables]).to include({
          "NEW_VAR" => { value: "new_var_value", expand: false }
        })
      end
    end

    describe '#add_service' do
      it 'adds a service to the workload_definition' do
        definition.add_service('docker:dind')
        expect(definition.to_job_hash[:services]).to eq(['docker:dind'])
      end

      it 'allows adding multiple services' do
        definition.add_service('docker:dind')
        definition.add_service('postgres:13')
        expect(definition.to_job_hash[:services]).to match_array(['docker:dind', 'postgres:13'])
      end
    end
  end

  describe '#services' do
    context 'with valid service inputs' do
      using RSpec::Parameterized::TableSyntax

      where(:service_input, :expected_output) do
        'docker:dind' | 'docker:dind'
        'postgres:13' | 'postgres:13'
        'redis:latest' | 'redis:latest'
        { name: 'postgres:13', alias: 'db' } | { name: 'postgres:13', alias: 'db' }
        { name: 'docker:dind',
          variables: { DOCKER_TLS_CERTDIR: '' } } | { name: 'docker:dind', variables: { DOCKER_TLS_CERTDIR: '' } }
      end

      with_them do
        it 'includes the service in to_job_hash' do
          definition.services = [service_input]
          expect(definition.to_job_hash[:services]).to eq([expected_output])
        end
      end
    end

    it 'does not include services when services is nil' do
      definition.services = nil
      expect(definition.to_job_hash).not_to have_key(:services)
    end

    it 'does not include services when services is empty array' do
      definition.services = []
      expect(definition.to_job_hash).not_to have_key(:services)
    end

    it 'handles mixed service formats' do
      definition.services = [
        'docker:dind',
        { name: 'postgres:13', alias: 'db' }
      ]
      expect(definition.to_job_hash[:services]).to eq([
        'docker:dind',
        { name: 'postgres:13', alias: 'db' }
      ])
    end

    it 'preserves service order' do
      services = %w[service-1 service-2 service-3]
      definition.services = services
      expect(definition.to_job_hash[:services]).to eq(services)
    end

    context 'with invalid service inputs' do
      using RSpec::Parameterized::TableSyntax

      where(:invalid_service) do
        [
          123,
          true,
          false,
          [],
          { invalid_key: 'value' }
        ]
      end

      with_them do
        it 'still includes the service (no validation at definition level)' do
          definition.services = [invalid_service]
          expect(definition.to_job_hash[:services]).to eq([invalid_service])
        end
      end
    end
  end

  describe 'suspend options' do
    it 'allows setting suspend_on_success' do
      definition.suspend_on_success = true
      expect(definition.suspend_on_success).to be true
    end

    it 'allows setting suspend_on_failure' do
      definition.suspend_on_failure = true
      expect(definition.suspend_on_failure).to be true
    end

    it 'allows setting environment_key' do
      definition.environment_key = 'runner-1/executor-specific-data'
      expect(definition.environment_key).to eq('runner-1/executor-specific-data')
    end

    it 'does not include suspend options in job hash' do
      definition.suspend_on_success = true
      definition.suspend_on_failure = true
      definition.environment_key = 'runner-1/executor-specific-data'
      expect(definition.to_job_hash).not_to have_key(:suspend_on_success)
      expect(definition.to_job_hash).not_to have_key(:suspend_on_failure)
      expect(definition.to_job_hash).not_to have_key(:environment_key)
    end
  end
end
