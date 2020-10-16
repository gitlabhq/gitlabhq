# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ListConfigVariablesService do
  let_it_be(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project) }
  let(:result) { YAML.dump(ci_config) }

  subject { service.execute(sha) }

  before do
    stub_gitlab_ci_yml_for_sha(sha, result)
  end

  context 'when sending a valid sha' do
    let(:sha) { 'master' }
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

    it 'returns variable list' do
      expect(subject['KEY1']).to eq({ value: 'val 1', description: 'description 1' })
      expect(subject['KEY2']).to eq({ value: 'val 2', description: '' })
      expect(subject['KEY3']).to eq({ value: 'val 3', description: nil })
      expect(subject['KEY4']).to eq({ value: 'val 4', description: nil })
    end
  end

  context 'when sending an invalid sha' do
    let(:sha) { 'invalid-sha' }
    let(:ci_config) { nil }

    it 'returns empty json' do
      expect(subject).to eq({})
    end
  end

  context 'when sending an invalid config' do
    let(:sha) { 'master' }
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

    it 'returns empty result' do
      expect(subject).to eq({})
    end
  end

  private

  def stub_gitlab_ci_yml_for_sha(sha, result)
    allow_any_instance_of(Repository)
        .to receive(:gitlab_ci_yml_for)
        .with(sha, '.gitlab-ci.yml')
        .and_return(result)
  end
end
