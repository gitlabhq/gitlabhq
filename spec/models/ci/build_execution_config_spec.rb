# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildExecutionConfig, type: :model, feature_category: :pipeline_composition do
  let_it_be(:execution_config) { create(:ci_builds_execution_configs) }

  it { is_expected.to belong_to(:pipeline).class_name('Ci::Pipeline').inverse_of(:build_execution_configs) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:builds).class_name('Ci::Build').inverse_of(:execution_config) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:run_steps) }
  end

  describe 'run_steps' do
    it { is_expected.not_to allow_value("string").for(:run_steps) }
    it { is_expected.not_to allow_value(1.0).for(:run_steps) }

    it { is_expected.not_to allow_value(nil).for(:run_steps) }

    it do
      is_expected.to allow_value(
        [
          {
            'name' => 'step1',
            'step' => 'echo',
            'inputs' => { 'message' => 'Hello, World!' }
          }
        ]
      ).for(:run_steps)
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    let(:pipeline) { create(:ci_pipeline) }
    let(:execution_config) { FactoryBot.build(:ci_builds_execution_configs, pipeline: pipeline) }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'assigns partition id to execution config' do
      execution_config.save!

      expect(execution_config.partition_id).to eq(ci_testing_partition_id)
    end
  end
end
