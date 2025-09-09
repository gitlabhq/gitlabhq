# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobDefinition, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:job_definition) { create(:ci_job_definition, project: project) }

  subject { job_definition }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_job_definition, project: project) }
    let!(:parent) { model.project }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    describe 'config validation' do
      subject(:job_definition) { build(:ci_job_definition, project: project, config: config) }

      context 'with valid config' do
        let(:config) { { options: { script: ['echo test'] } } }

        it { is_expected.to be_valid }
      end

      context 'with invalid config structure' do
        let(:config) { 'invalid' }

        it 'is invalid' do
          expect(job_definition).not_to be_valid
          expect(job_definition.errors[:config]).to include('must be a valid json schema')
        end
      end
    end
  end

  describe 'constants' do
    describe 'CONFIG_ATTRIBUTES' do
      it 'defines the correct attributes in order' do
        expect(described_class::CONFIG_ATTRIBUTES).to eq([
          :options,
          :yaml_variables,
          :id_tokens,
          :secrets,
          :interruptible,
          :tag_list,
          :run_steps
        ])
      end
    end
  end

  describe '.fabricate' do
    let(:config) do
      {
        options: { script: ['echo test'] },
        yaml_variables: [{ key: 'VAR', value: 'value' }],
        interruptible: true,
        extra_field: 'should be ignored'
      }
    end

    let(:project_id) { project.id }
    let(:partition_id) { 100 }

    subject(:fabricate) do
      described_class.fabricate(config: config, project_id: project_id, partition_id: partition_id)
    end

    it 'sets the correct attributes' do
      expect(fabricate).to have_attributes(
        project_id: project_id,
        partition_id: partition_id,
        interruptible: true
      )
    end

    it 'sanitizes the config' do
      expect(fabricate.config).to eq(
        options: { script: ['echo test'] },
        yaml_variables: [{ key: 'VAR', value: 'value' }],
        interruptible: true
      )
    end

    it 'generates a checksum' do
      expect(fabricate.checksum).to be_present
      expect(fabricate.checksum).to match(/\A[a-f0-9]{64}\z/)
    end

    it 'sets timestamps', :freeze_time do
      expect(fabricate.created_at).to eq(Time.current)
      expect(fabricate.updated_at).to eq(Time.current)
    end

    context 'with interruptible not specified' do
      let(:config) { { options: { script: ['echo test'] } } }

      it 'uses column default for interruptible' do
        expect(fabricate.interruptible).to eq(described_class.column_defaults['interruptible'])
      end
    end

    context 'with all CONFIG_ATTRIBUTES specified' do
      let(:config) do
        {
          options: { script: ['echo test'] },
          yaml_variables: [{ key: 'VAR', value: 'value' }],
          id_tokens: { TEST_TOKEN: { aud: 'https://gitlab.com' } },
          secrets: { TEST_SECRET: { gitlab_secrets_manager: { name: 'foo' } } },
          interruptible: true, tag_list: %w[ruby postgresql],
          run_steps: [{ 'name' => 'step1', 'step' => 'echo', 'inputs' => { 'message' => 'Hello, World!' } }]
        }
      end

      it 'includes all specified CONFIG_ATTRIBUTES' do
        expect(fabricate.config.keys).to match_array(described_class::CONFIG_ATTRIBUTES)
      end
    end
  end

  describe '.sanitize_and_checksum' do
    let(:config) do
      {
        options: { script: ['echo test'] },
        yaml_variables: [{ key: 'VAR', value: 'value' }],
        id_tokens: { TEST_TOKEN: { aud: 'https://gitlab.com' } },
        secrets: { TEST_SECRET: { gitlab_secrets_manager: { name: 'foo' } } },
        interruptible: true,
        extra_field: 'should be ignored'
      }
    end

    subject(:result) { described_class.sanitize_and_checksum(config) }

    it 'returns an array with sanitized config and checksum' do
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)

      sanitized_config, checksum = result
      expect(sanitized_config).to be_a(Hash)
      expect(checksum).to be_a(String)
    end

    it 'includes only CONFIG_ATTRIBUTES that were present in input' do
      sanitized_config, _ = result
      expect(sanitized_config.keys).to contain_exactly(:options, :yaml_variables, :id_tokens, :secrets, :interruptible)
      expect(sanitized_config).not_to have_key(:extra_field)
    end

    it 'generates consistent checksum for same data' do
      _, checksum1 = described_class.sanitize_and_checksum(config)
      _, checksum2 = described_class.sanitize_and_checksum(config)

      expect(checksum1).to eq(checksum2)
    end

    it 'generates different checksums for different data' do
      config2 = config.merge(options: { script: ['echo different'] })

      _, checksum1 = described_class.sanitize_and_checksum(config)
      _, checksum2 = described_class.sanitize_and_checksum(config2)

      expect(checksum1).not_to eq(checksum2)
    end

    it 'symbolizes keys in the result' do
      string_key_config = { 'options' => { 'script' => ['echo test'] } }
      sanitized_config, _ = described_class.sanitize_and_checksum(string_key_config)

      expect(sanitized_config).to have_key(:options)
      expect(sanitized_config).not_to have_key('options')
    end

    describe 'checksum calculation' do
      it 'uses SHA256 for checksum' do
        _, checksum = result
        expect(checksum).to match(/\A[a-f0-9]{64}\z/)
      end

      it 'preserves attribute order for consistent checksum' do
        # Create two configs with same data but different key order
        config1 = {
          interruptible: true,
          options: { script: ['test'] },
          yaml_variables: [{ key: 'VAR', value: 'val' }]
        }

        config2 = {
          yaml_variables: [{ key: 'VAR', value: 'val' }],
          options: { script: ['test'] },
          interruptible: true
        }

        _, checksum1 = described_class.sanitize_and_checksum(config1)
        _, checksum2 = described_class.sanitize_and_checksum(config2)

        expect(checksum1).to eq(checksum2)
      end
    end
  end
end
