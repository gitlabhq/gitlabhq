# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineProcessingData, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  it { is_expected.to belong_to(:pipeline) }
  it { is_expected.to belong_to(:project) }

  it { is_expected.to validate_presence_of(:pipeline) }
  it { is_expected.to validate_presence_of(:project_id) }

  it 'is keyed by the pipeline it belongs to' do
    processing_data = described_class.create!(pipeline: pipeline, project_id: pipeline.project_id)

    expect(processing_data.id).to eq(pipeline.id)
    expect(pipeline.reload.pipeline_processing_data).to eq(processing_data)
  end

  it 'takes the partition of its pipeline' do
    processing_data = described_class.create!(pipeline: pipeline, project_id: pipeline.project_id)

    expect(processing_data.partition_id).to eq(pipeline.partition_id)
  end

  it 'leaves a pipeline within reach of auto-cancellation until a job protects it' do
    processing_data = described_class.create!(pipeline: pipeline, project_id: pipeline.project_id)

    expect(processing_data.interruptible_protected).to be(false)
  end

  describe 'partitioning' do
    it_behaves_like 'a CI model that detaches archived partitions'
  end
end
