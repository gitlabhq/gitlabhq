# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Build::Associations, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project, :small_repo) }
  let_it_be(:user) { create(:user, developer_of: project) }

  # Assigning partition_id here to validate it is being propagated correctly
  let(:pipeline) { Ci::Pipeline.new(partition_id: ci_testing_partition_id) }
  let(:bridge) { nil }

  let(:variables_attributes) do
    [
      { key: 'first', value: 'world' },
      { key: 'second', value: 'second_world' }
    ]
  end

  let(:source) { :push }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      source: source,
      origin_ref: 'master',
      checkout_sha: project.commit.id,
      after_sha: nil,
      before_sha: nil,
      schedule: nil,
      merge_request: nil,
      project: project,
      current_user: user,
      bridge: bridge,
      variables_attributes: variables_attributes)
  end

  let(:step) { described_class.new(pipeline, command) }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :developer)
  end

  shared_examples 'breaks the chain' do
    it 'returns true' do
      step.perform!

      expect(step.break?).to be true
    end
  end

  shared_examples 'does not break the chain' do
    it 'returns false' do
      step.perform!

      expect(step.break?).to be false
    end
  end

  shared_examples 'assigns pipeline variables' do
    specify do
      step.perform!

      expect(pipeline.variables.map { |var| var.slice(:key, :value) })
        .to eq variables_attributes.map(&:with_indifferent_access)
    end

    it 'builds a pipeline_variables artifact' do
      step.perform!

      expect(pipeline.pipeline_artifacts_pipeline_variables).to be_present
      expect(pipeline.pipeline_artifacts_pipeline_variables.file_type).to eq('pipeline_variables')
    end

    it 'calls PipelineVariablesArtifactBuilder' do
      expect(Gitlab::Ci::Pipeline::Build::PipelineVariablesArtifactBuilder)
        .to receive(:new).with(pipeline, variables_attributes).and_call_original

      step.perform!
    end
  end

  it_behaves_like 'assigns pipeline variables'

  context 'when a bridge is passed in to the pipeline creation' do
    let(:bridge) { create(:ci_bridge) }

    it 'links the pipeline to the upstream bridge job' do
      step.perform!

      expect(pipeline.source_pipeline).to be_present
      expect(pipeline.source_pipeline).to be_valid
      expect(pipeline.source_pipeline).to have_attributes(
        source_pipeline: bridge.pipeline, source_project: bridge.project,
        source_bridge: bridge, project: project
      )
    end

    it_behaves_like 'does not break the chain'
  end

  context 'when a bridge is not passed in to the pipeline creation' do
    it 'leaves the source pipeline empty' do
      step.perform!

      expect(pipeline.source_pipeline).to be_nil
    end

    it_behaves_like 'does not break the chain'
  end

  context 'when project setting restrict_user_defined_variables is enabled' do
    before do
      project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
    end

    context 'when user is developer' do
      it_behaves_like 'breaks the chain'

      it 'returns an error on variables_attributes', :aggregate_failures do
        step.perform!

        expect(pipeline.errors.full_messages).to eq(['Insufficient permissions to set pipeline variables'])
        expect(pipeline.variables).to be_empty
      end

      context 'when variables_attributes is not specified' do
        let(:variables_attributes) { nil }

        it_behaves_like 'does not break the chain'

        it 'assigns empty variables' do
          step.perform!

          expect(pipeline.variables).to be_empty
        end
      end

      context 'when source is :ondemand_dast_validation' do
        let(:source) { :ondemand_dast_validation }

        it_behaves_like 'does not break the chain'

        it_behaves_like 'assigns pipeline variables'
      end

      context 'when source is :trigger with variables other then TRIGGER_PAYLOAD' do
        let(:source) { :trigger }

        let(:variables_attributes) do
          [{ key: 'first', value: 'world' }]
        end

        it 'returns an insufficient permissions error' do
          step.perform!

          expect(pipeline.errors.full_messages).to eq(['Insufficient permissions to set pipeline variables'])
        end
      end

      context 'when source is :trigger with no variables' do
        let(:source) { :trigger }
        let(:variables_attributes) { nil }

        it_behaves_like 'does not break the chain'
      end

      context 'when source is :trigger with only TRIGGER_PAYLOAD' do
        let(:source) { :trigger }

        let(:variables_attributes) do
          [{ key: 'TRIGGER_PAYLOAD', value: 'some payload' }]
        end

        it_behaves_like 'does not break the chain'
      end

      context 'when source is :trigger with TRIGGER_PAYLOAD and trigger_api_request is false' do
        let(:command) do
          Gitlab::Ci::Pipeline::Chain::Command.new(
            source: :trigger,
            origin_ref: 'master',
            checkout_sha: project.commit.id,
            after_sha: nil,
            before_sha: nil,
            schedule: nil,
            merge_request: nil,
            project: project,
            current_user: user,
            bridge: bridge,
            trigger_api_request: false,
            variables_attributes: variables_attributes)
        end

        let(:variables_attributes) do
          [{ key: 'TRIGGER_PAYLOAD', value: 'some payload' }]
        end

        it 'still allows TRIGGER_PAYLOAD since source is :trigger' do
          step.perform!

          expect(step.break?).to be false
          expect(pipeline.variables.map(&:key)).to include('TRIGGER_PAYLOAD')
        end
      end

      context 'when trigger_api_request is true with only TRIGGER_PAYLOAD (CI_JOB_TOKEN path)' do
        let(:command) do
          Gitlab::Ci::Pipeline::Chain::Command.new(
            source: :pipeline,
            origin_ref: 'master',
            checkout_sha: project.commit.id,
            after_sha: nil,
            before_sha: nil,
            schedule: nil,
            merge_request: nil,
            project: project,
            current_user: user,
            bridge: bridge,
            trigger_api_request: true,
            variables_attributes: variables_attributes)
        end

        let(:variables_attributes) do
          [{ key: 'TRIGGER_PAYLOAD', value: 'some payload' }]
        end

        it_behaves_like 'does not break the chain'

        it 'allows TRIGGER_PAYLOAD variable' do
          step.perform!

          expect(pipeline.variables.map(&:key)).to include('TRIGGER_PAYLOAD')
        end
      end

      context 'when trigger_api_request is true with variables other than TRIGGER_PAYLOAD (CI_JOB_TOKEN path)' do
        let(:command) do
          Gitlab::Ci::Pipeline::Chain::Command.new(
            source: :pipeline,
            origin_ref: 'master',
            checkout_sha: project.commit.id,
            after_sha: nil,
            before_sha: nil,
            schedule: nil,
            merge_request: nil,
            project: project,
            current_user: user,
            bridge: bridge,
            trigger_api_request: true,
            variables_attributes: variables_attributes)
        end

        let(:variables_attributes) do
          [{ key: 'CUSTOM_VAR', value: 'value' }]
        end

        it 'returns an insufficient permissions error' do
          step.perform!

          expect(pipeline.errors.full_messages).to eq(['Insufficient permissions to set pipeline variables'])
        end
      end

      context 'when trigger_api_request is false (bridge-triggered pipeline)' do
        let(:source) { :pipeline }
        let(:bridge) { build(:ci_bridge) }

        let(:variables_attributes) do
          [{ key: 'TRIGGER_PAYLOAD', value: 'user-controlled' }]
        end

        it 'returns an insufficient permissions error' do
          step.perform!

          expect(pipeline.errors.full_messages).to eq(['Insufficient permissions to set pipeline variables'])
        end
      end

      context 'when trigger_api_request is nil with variables' do
        let(:source) { :pipeline }

        let(:variables_attributes) do
          [{ key: 'first', value: 'world' }]
        end

        it 'returns an insufficient permissions error' do
          step.perform!

          expect(pipeline.errors.full_messages).to eq(['Insufficient permissions to set pipeline variables'])
        end
      end
    end
  end

  context 'when user is maintainer' do
    before_all { project.add_maintainer(user) }

    it_behaves_like 'does not break the chain'

    it_behaves_like 'assigns pipeline variables'

    context "when source is :trigger and user has permissions to set pipeline variables" do
      let(:source) { :trigger }

      let(:variables_attributes) do
        [{ key: 'first', value: 'world' }]
      end

      it_behaves_like 'does not break the chain'
    end
  end

  context 'with duplicate pipeline variables' do
    let(:variables_attributes) do
      [
        { key: 'first', value: 'world' },
        { key: 'first', value: 'second_world' }
      ]
    end

    it_behaves_like 'breaks the chain'

    it 'returns an error for variables_attributes' do
      step.perform!

      expect(pipeline.errors.full_messages).to eq(['Duplicate variable name: first'])
      expect(pipeline.variables).to be_empty
    end
  end

  context 'when variables_attributes is empty' do
    let(:variables_attributes) { [] }

    it 'does not assign pipeline variables' do
      step.perform!

      expect(pipeline.variables).to be_empty
    end

    it 'does not build a pipeline_variables artifact' do
      step.perform!

      expect(pipeline.pipeline_artifacts_pipeline_variables).to be_nil
    end
  end

  describe 'observability' do
    subject(:observations) do
      step.perform!
      command.logger.observations_hash
    end

    it 'observes the variables count, the largest value bytesize, and the total bytesize' do
      expect(observations).to include(
        'pipeline_variables_count' => 2,
        'pipeline_variables_max_value_bytesize' => 12,
        'pipeline_variables_total_bytesize' => 28
      )
    end

    it 'observes the largest value bytesize per variable type, counting an untyped variable as env_var' do
      expect(observations).to include('pipeline_variables_max_env_var_value_bytesize' => 12)
      expect(observations).not_to have_key('pipeline_variables_max_file_value_bytesize')
    end

    context 'with both variable types' do
      let(:variables_attributes) do
        [
          { key: 'env', value: 'a' * 3 },
          { key: 'env_bigger', value: 'a' * 7 },
          { key: 'a_file', value: 'a' * 9, variable_type: 'file' }
        ]
      end

      it 'observes each type separately and the overall maximum' do
        expect(observations).to include(
          'pipeline_variables_max_value_bytesize' => 9,
          'pipeline_variables_max_env_var_value_bytesize' => 7,
          'pipeline_variables_max_file_value_bytesize' => 9
        )
      end
    end

    describe 'variable_type forms' do
      where(:variable_type, :observed_as) do
        'env_var' | 'env_var'
        :env_var  | 'env_var'
        1         | 'env_var'
        'file'    | 'file'
        :file     | 'file'
        2         | 'file'
        nil       | 'env_var'
        ''        | 'env_var'
        3         | 'env_var'
        'bogus'   | 'env_var'
      end

      with_them do
        let(:variables_attributes) { [{ key: 'first', value: 'ab', variable_type: variable_type }] }

        it 'observes the value under the limit it falls under' do
          expect(observations).to include("pipeline_variables_max_#{observed_as}_value_bytesize" => 2)
        end
      end
    end

    context 'with a multibyte value' do
      let(:variables_attributes) { [{ key: 'first', value: 'áé' }] }

      it 'observes the bytesize rather than the character length' do
        expect(observations).to include(
          'pipeline_variables_max_value_bytesize' => 4,
          'pipeline_variables_total_bytesize' => 9
        )
      end
    end

    context 'when variables_attributes is nil' do
      let(:variables_attributes) { nil }

      it 'observes zeroes and no per-type sizes' do
        expect(observations).to include(
          'pipeline_variables_count' => 0,
          'pipeline_variables_max_value_bytesize' => 0,
          'pipeline_variables_total_bytesize' => 0
        )
        expect(observations.keys).not_to include(
          'pipeline_variables_max_env_var_value_bytesize', 'pipeline_variables_max_file_value_bytesize'
        )
      end
    end

    context 'when the user cannot set pipeline variables' do
      before do
        project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
      end

      it 'observes the rejected variables' do
        expect(observations).to include(
          'pipeline_variables_count' => 2,
          'pipeline_variables_max_value_bytesize' => 12
        )
      end
    end

    context 'with duplicate keys' do
      let(:variables_attributes) do
        [
          { key: 'first', value: 'world' },
          { key: 'first', value: 'second_world' }
        ]
      end

      it 'observes the submitted variables' do
        expect(observations).to include(
          'pipeline_variables_count' => 2,
          'pipeline_variables_max_value_bytesize' => 12
        )
      end
    end
  end

  context 'when PipelineVariablesArtifactBuilder raises ActiveModel::ValidationError' do
    let(:variables_attributes) { [{ key: 'invalid-key!', value: 'some-value' }] }

    it_behaves_like 'breaks the chain'

    it 'returns an error' do
      step.perform!

      expect(pipeline.errors.full_messages)
        .to contain_exactly(a_string_including('Failed to build pipeline variables'))
    end
  end

  context 'when the pipeline variables exceed the artifact size limit' do
    let(:variables_attributes) { [{ key: 'BIG', value: 'a' * 1.kilobyte }] }

    before do
      stub_const('Ci::PipelineArtifact::FILE_SIZE_LIMIT', 1.kilobyte)
    end

    it_behaves_like 'breaks the chain'

    it 'returns an error' do
      step.perform!

      expect(pipeline.errors.full_messages).to contain_exactly(
        'Failed to build pipeline variables: total size exceeds the limit of 1 KiB'
      )
      expect(pipeline.failure_reason).to eq('config_error')
    end

    context 'when the ci_enforce_pipeline_variables_total_size_limit feature flag is disabled' do
      before do
        stub_feature_flags(ci_enforce_pipeline_variables_total_size_limit: false)
      end

      it_behaves_like 'does not break the chain'
    end
  end
end
