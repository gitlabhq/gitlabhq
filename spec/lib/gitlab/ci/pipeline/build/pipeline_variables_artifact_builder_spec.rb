# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Build::PipelineVariablesArtifactBuilder, feature_category: :continuous_integration do
  include Ci::PartitioningHelpers

  let_it_be(:project) { create(:project) }
  let(:pipeline) { build(:ci_pipeline, project: project, partition_id: ci_testing_partition_id) }

  let(:variables_attributes) do
    [
      { key: 'ENV_VAR', value: 'env_value' },
      { key: 'FILE_VAR', value: 'file_value', variable_type: :file, raw: true }
    ]
  end

  let(:expected_variables_attributes) do
    [
      { key: 'ENV_VAR', value: 'env_value', variable_type: 'env_var', raw: false },
      { key: 'FILE_VAR', value: 'file_value', variable_type: 'file', raw: true }
    ].map(&:stringify_keys)
  end

  subject(:run_builder) { described_class.new(pipeline, variables_attributes).run }

  before do
    stub_current_partition_id(ci_testing_partition_id)
  end

  describe '#run' do
    it 'builds a pipeline variables artifact with the correct attributes and file content' do
      run_builder
      artifact = pipeline.pipeline_artifacts_pipeline_variables

      expect(artifact).to be_a(Ci::PipelineArtifact)
      expect(artifact.project_id).to eq(pipeline.project_id)
      expect(artifact.partition_id).to eq(pipeline.partition_id)
      expect(artifact.file_type).to eq('pipeline_variables')
      expect(artifact.size).to eq(Gitlab::Json.dump(expected_variables_attributes).bytesize)
      expect(artifact.file_format).to eq('raw')
      expect(artifact.locked).to eq(pipeline.locked)
      expect(Gitlab::Json.safe_parse(artifact.file.read)).to match_array(expected_variables_attributes)
    end

    context 'when variables_attributes is empty' do
      let(:variables_attributes) { [] }

      it 'does not build a pipeline variables artifact' do
        run_builder

        expect(pipeline.pipeline_artifacts_pipeline_variables).to be_nil
      end
    end

    context 'when a variable is invalid' do
      let(:variables_attributes) { [{ key: 'INVALID KEY', value: 'value' }] }

      it 'raises an error' do
        expect { run_builder }.to raise_error(ActiveModel::ValidationError, /Validation failed/)
      end
    end

    context 'when the variables exceed the artifact size limit' do
      let(:variables_attributes) { [{ key: 'BIG', value: 'a' * 1.kilobyte }] }

      before do
        stub_const('Ci::PipelineArtifact::FILE_SIZE_LIMIT', 1.kilobyte)
      end

      it 'raises an error' do
        expect { run_builder }.to raise_error(
          described_class::SizeLimitExceededError,
          'total size exceeds the limit of 1 KiB'
        )
        expect(pipeline.pipeline_artifacts_pipeline_variables).to be_nil
      end

      context 'when the ci_enforce_pipeline_variables_total_size_limit feature flag is disabled' do
        before do
          stub_feature_flags(ci_enforce_pipeline_variables_total_size_limit: false)
        end

        it 'builds the pipeline variables artifact' do
          expect { run_builder }.not_to raise_error
          expect(pipeline.pipeline_artifacts_pipeline_variables).to be_a(Ci::PipelineArtifact)
        end
      end
    end
  end
end
