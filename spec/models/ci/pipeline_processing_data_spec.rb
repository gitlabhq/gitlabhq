# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineProcessingData, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  it { is_expected.to belong_to(:pipeline) }
  it { is_expected.to belong_to(:project) }

  it { is_expected.to validate_presence_of(:pipeline) }
  it { is_expected.to validate_presence_of(:project_id) }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_pipeline_processing_data, pipeline: create(:ci_pipeline)) }
    let!(:parent) { model.project }
  end

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

  describe '.protect' do
    it 'protects a pipeline that has no row yet' do
      described_class.protect(pipeline)

      expect(pipeline.reload).to be_interruptible_protected
    end

    it 'writes the project and partition of the pipeline' do
      described_class.protect(pipeline)

      processing_data = pipeline.reload.pipeline_processing_data

      expect(processing_data.project_id).to eq(pipeline.project_id)
      expect(processing_data.partition_id).to eq(pipeline.partition_id)
    end

    it 'protects a pipeline that already has a row' do
      create(:ci_pipeline_processing_data, pipeline: pipeline)

      described_class.protect(pipeline)

      expect(pipeline.reload).to be_interruptible_protected
    end

    it 'leaves a protected pipeline as it is' do
      described_class.protect(pipeline)

      expect { described_class.protect(pipeline) }.not_to change { described_class.count }
      expect(pipeline.reload).to be_interruptible_protected
    end

    it 'protects one pipeline without touching another' do
      other_pipeline = create(:ci_pipeline)

      described_class.protect(pipeline)

      expect(other_pipeline.reload).not_to be_interruptible_protected
    end
  end

  describe 'partitioning' do
    it_behaves_like 'a CI model that detaches archived partitions'
  end
end
