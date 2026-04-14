# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineProcessWorker, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has the option to reschedule once if deduplicated and a TTL of 1 minute' do
    expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once, ttl: 1.minute })
  end

  it_behaves_like 'an idempotent worker' do
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
