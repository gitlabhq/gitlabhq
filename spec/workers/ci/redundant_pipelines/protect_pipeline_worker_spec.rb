# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RedundantPipelines::ProtectPipelineWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, :running, project: project) }

  subject(:perform) { described_class.new.perform(pipeline.id, pipeline.partition_id) }

  it 'protects the pipeline' do
    perform

    expect(pipeline.reload).to be_interruptible_protected
  end

  it 'does nothing for a pipeline that is gone' do
    expect { described_class.new.perform(non_existing_record_id, pipeline.partition_id) }
      .not_to change { Ci::PipelineProcessingData.count }
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [pipeline.id, pipeline.partition_id] }
  end
end
