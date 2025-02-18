# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Build::Associations, feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }

  # Assigning partition_id here to validate it is being propagated correctly
  let(:pipeline) { Ci::Pipeline.new(partition_id: ci_testing_partition_id) }
  let(:bridge) { nil }

  let(:variables_attributes) do
    [{ key: 'first', secret_value: 'world' },
     { key: 'second', secret_value: 'second_world' }]
  end

  let(:source) { :push }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      source: source,
      origin_ref: 'master',
      checkout_sha: project.commit.id,
      after_sha: nil,
      before_sha: nil,
      trigger_request: nil,
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

  shared_examples 'assigns variables_attributes' do
    specify do
      step.perform!

      expect(pipeline.variables.map { |var| var.slice(:key, :secret_value) })
        .to eq variables_attributes.map(&:with_indifferent_access)
    end
  end

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

  it 'sets pipeline variables' do
    step.perform!

    expect(pipeline.variables.map { |var| var.slice(:key, :secret_value) })
      .to eq variables_attributes.map(&:with_indifferent_access)
  end

  context 'when project setting restrict_user_defined_variables is enabled' do
    before do
      project.update!(restrict_user_defined_variables: true, ci_pipeline_variables_minimum_override_role: :maintainer)
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

        it_behaves_like 'assigns variables_attributes'
      end
    end
  end

  context 'when user is maintainer' do
    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'does not break the chain'

    it_behaves_like 'assigns variables_attributes'
  end

  context 'with duplicate pipeline variables' do
    let(:variables_attributes) do
      [{ key: 'first', secret_value: 'world' },
       { key: 'first', secret_value: 'second_world' }]
    end

    it_behaves_like 'breaks the chain'

    it 'returns an error for variables_attributes' do
      step.perform!

      expect(pipeline.errors.full_messages).to eq(['Duplicate variable name: first'])
      expect(pipeline.variables).to be_empty
    end
  end
end
