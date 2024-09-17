# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineChatData, type: :model, feature_category: :continuous_integration do
  it { is_expected.to belong_to(:chat_name) }
  it { is_expected.to belong_to(:pipeline) }

  it { is_expected.to validate_presence_of(:pipeline_id) }
  it { is_expected.to validate_presence_of(:chat_name_id) }
  it { is_expected.to validate_presence_of(:response_url) }

  describe 'partitioning', :ci_partitionable do
    include Ci::PartitioningHelpers

    let(:pipeline) { create(:ci_pipeline) }
    let(:pipeline_chat_data) { create(:ci_pipeline_chat_data, pipeline: pipeline) }

    before do
      stub_current_partition_id(ci_testing_partition_id_for_check_constraints)
    end

    it 'assigns the same partition id as the one that pipeline has' do
      expect(pipeline_chat_data.partition_id).to eq(ci_testing_partition_id_for_check_constraints)
    end
  end
end
