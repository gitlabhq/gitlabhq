# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Build::Associations, feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }

  # Assigning partition_id here to validate it is being propagated correctly
  let(:pipeline) { Ci::Pipeline.new(partition_id: ci_testing_partition_id) }
  let(:bridge) { nil }

  let(:variables_attributes) do
    [
      { key: 'first', secret_value: 'world' },
      { key: 'second', secret_value: 'second_world' }
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

      expect(pipeline.variables.map { |var| var.slice(:key, :secret_value) })
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

    context 'when FF `ci_write_pipeline_variables_artifact` is disabled' do
      before do
        stub_feature_flags(ci_write_pipeline_variables_artifact: false)
      end

      it 'assigns variables to the pipeline' do
        step.perform!

        expect(pipeline.variables.map { |var| var.slice(:key, :secret_value) })
          .to eq variables_attributes.map(&:with_indifferent_access)
      end

      it 'does not call PipelineVariablesArtifactBuilder' do
        expect(Gitlab::Ci::Pipeline::Build::PipelineVariablesArtifactBuilder).not_to receive(:new)

        step.perform!
      end

      it 'does not build a pipeline_variables artifact' do
        step.perform!

        expect(pipeline.pipeline_artifacts_pipeline_variables).to be_nil
      end
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
    end
  end

  context 'when user is maintainer' do
    before do
      project.add_maintainer(user)
    end

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
        { key: 'first', secret_value: 'world' },
        { key: 'first', secret_value: 'second_world' }
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

  context 'when PipelineVariablesArtifactBuilder raises ActiveModel::ValidationError' do
    let(:variables_attributes) { [{ key: 'invalid-key!', value: 'some-value' }] }

    it_behaves_like 'breaks the chain'

    it 'returns an error' do
      step.perform!

      expect(pipeline.errors.full_messages)
        .to contain_exactly(a_string_including('Failed to build pipeline variables'))
    end
  end
end
