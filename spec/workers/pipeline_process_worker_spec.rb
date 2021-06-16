# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineProcessWorker do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  include_examples 'an idempotent worker' do
    let(:pipeline) { create(:ci_pipeline, :created) }
    let(:job_args) { [pipeline.id] }

    before do
      create(:ci_build, :created, pipeline: pipeline)
    end

    it 'processes the pipeline' do
      expect(pipeline.status).to eq('created')
      expect(pipeline.processables.pluck(:status)).to contain_exactly('created')

      subject

      expect(pipeline.reload.status).to eq('pending')
      expect(pipeline.processables.pluck(:status)).to contain_exactly('pending')

      subject

      expect(pipeline.reload.status).to eq('pending')
      expect(pipeline.processables.pluck(:status)).to contain_exactly('pending')
    end
  end

  context 'when the FF ci_idempotent_pipeline_process_worker is disabled' do
    before do
      stub_feature_flags(ci_idempotent_pipeline_process_worker: false)
    end

    it 'is not deduplicated' do
      expect(described_class).not_to be_deduplication_enabled
    end
  end

  describe '#perform' do
    context 'when pipeline exists' do
      it 'processes pipeline' do
        expect_any_instance_of(Ci::ProcessPipelineService).to receive(:execute)

        described_class.new.perform(pipeline.id)
      end
    end

    context 'when pipeline does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(non_existing_record_id) }
          .not_to raise_error
      end
    end
  end
end
