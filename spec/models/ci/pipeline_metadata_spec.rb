# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineMetadata, feature_category: :pipeline_composition do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:pipeline) }

  describe 'validations' do
    it { is_expected.to validate_length_of(:name).is_at_least(1).is_at_most(255) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:pipeline) }

    it do
      is_expected.to define_enum_for(
        :auto_cancel_on_new_commit
      ).with_values(
        conservative: 0, interruptible: 1, none: 2
      ).with_prefix
    end

    it do
      is_expected.to define_enum_for(
        :auto_cancel_on_job_failure
      ).with_values(
        none: 0, all: 1
      ).with_prefix
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    let(:pipeline) { create(:ci_pipeline) }
    let(:pipeline_metadata) { create(:ci_pipeline_metadata, pipeline: pipeline) }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'assigns the same partition id as the one that pipeline has' do
      expect(pipeline_metadata.partition_id).to eq(ci_testing_partition_id)
    end
  end
end
