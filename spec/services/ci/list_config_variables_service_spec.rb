# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ListConfigVariablesService,
  :use_clean_rails_memory_store_caching, feature_category: :secrets_management do
  include ReactiveCachingHelpers

  let(:ci_config) { {} }
  let(:files) { { '.gitlab-ci.yml' => YAML.dump(ci_config) } }
  let(:project) { create(:project, :custom_repo, :auto_devops_disabled, files: files) }
  let(:user) { project.creator }
  let(:ref) { project.default_branch }
  let(:sha) { project.commit(ref).sha }
  let(:service) { described_class.new(project, user) }

  subject(:result) { service.execute(ref) }

  context 'when sending a valid ref' do
    let(:ci_config) do
      {
        variables: {
          KEY1: { value: 'val 1', description: 'description 1' },
          KEY2: { value: 'val 2', description: '' },
          KEY3: { value: 'val 3' },
          KEY4: 'val 4'
        },
        test: {
          stage: 'test',
          script: 'echo'
        }
      }
    end

    let(:expected_result) do
      {
        'KEY1' => { value: 'val 1', description: 'description 1' },
        'KEY2' => { value: 'val 2', description: '' },
        'KEY3' => { value: 'val 3' },
        'KEY4' => { value: 'val 4' }
      }
    end

    before do
      synchronous_reactive_cache(service)
    end

    it 'returns variables list' do
      expect(result).to eq(expected_result)
    end

    context 'when the ref is a sha from a fork' do
      include_context 'when a project repository contains a forked commit'

      before do
        allow_next_instance_of(Gitlab::Ci::ProjectConfig) do |instance|
          allow(instance).to receive(:exists?).and_return(true)
          allow(instance).to receive(:content).and_return(YAML.dump(ci_config))
        end
      end

      let(:ref) { forked_commit_sha }

      context 'when a project ref contains the sha' do
        before do
          mock_branch_contains_forked_commit_sha
        end

        it 'returns variables list' do
          expect(result).to eq(expected_result)
        end
      end

      context 'when a project ref does not contain the sha' do
        it 'returns empty response' do
          expect(result).to eq({})
        end
      end
    end
  end

  context 'when config has includes' do
    let(:ci_config) do
      {
        include: [{ local: 'other_file.yml' }],
        variables: {
          KEY1: { value: 'val 1', description: 'description 1' }
        },
        test: {
          stage: 'test',
          script: 'echo'
        }
      }
    end

    let(:other_file) do
      {
        variables: {
          KEY2: { value: 'val 2', description: 'description 2' }
        }
      }
    end

    let(:files) { { '.gitlab-ci.yml' => YAML.dump(ci_config), 'other_file.yml' => YAML.dump(other_file) } }

    before do
      synchronous_reactive_cache(service)
    end

    it 'returns variable list' do
      expect(result['KEY1']).to eq({ value: 'val 1', description: 'description 1' })
      expect(result['KEY2']).to eq({ value: 'val 2', description: 'description 2' })
    end
  end

  context 'when project CI config is external' do
    let(:other_project_ci_config) do
      {
        variables: { KEY1: { value: 'val 1', description: 'description 1' } },
        test: { script: 'echo' }
      }
    end

    let(:other_project_files) { { '.gitlab-ci.yml' => YAML.dump(other_project_ci_config) } }
    let(:other_project) { create(:project, :custom_repo, files: other_project_files) }

    before do
      project.update!(ci_config_path: ".gitlab-ci.yml@#{other_project.full_path}:master")
      synchronous_reactive_cache(service)
    end

    context 'when the user has access to the external project' do
      before do
        other_project.add_developer(user)
      end

      it 'returns variable list' do
        expect(result['KEY1']).to eq({ value: 'val 1', description: 'description 1' })
      end
    end

    context 'when the user has no access to the external project' do
      it 'returns empty json' do
        expect(result).to eq({})
      end
    end
  end

  context 'when sending an invalid ref' do
    let(:ref) { 'invalid-ref' }
    let(:ci_config) { nil }

    before do
      synchronous_reactive_cache(service)
    end

    it 'returns empty json' do
      expect(result).to eq({})
    end
  end

  context 'when sending an invalid config' do
    let(:ci_config) do
      {
        variables: {
          KEY1: { value: 'val 1', description: 'description 1' }
        },
        test: {
          stage: 'invalid',
          script: 'echo'
        }
      }
    end

    before do
      synchronous_reactive_cache(service)
    end

    it 'returns empty result' do
      expect(result).to eq({})
    end
  end

  context 'when reading from cache' do
    let(:reactive_cache_params) { [sha] }
    let(:return_value) { { 'KEY1' => { value: 'val 1', description: 'description 1' } } }

    before do
      stub_reactive_cache(service, return_value, reactive_cache_params)
    end

    it 'returns variable list' do
      expect(result).to eq(return_value)
    end
  end

  context 'when the cache is empty' do
    let(:reactive_cache_params) { [sha] }

    it 'returns nil and enquques the worker to fill cache' do
      expect(ExternalServiceReactiveCachingWorker)
        .to receive(:perform_async)
        .with(service.class, service.id, *reactive_cache_params)

      expect(result).to be_nil
    end
  end
end
