# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineProcessWorker, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  # The two examples below are to be added when FF `ci_pipeline_process_worker_dedup_until_executed` is removed
  # it 'has the `until_executed` deduplicate strategy' do
  #   expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  # end

  # it 'has the option to reschedule once if deduplicated and a TTL of 1 minute' do
  #   expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once, ttl: 1.minute })
  # end

  # This context is to be removed when FF `ci_pipeline_process_worker_dedup_until_executed` is removed
  describe '#perform_async', :sidekiq_inline  do
    around do |example|
      Sidekiq::Testing.fake! { example.run }
    end

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project) }

    subject { described_class.perform_async(pipeline.id) }

    it 'sets the deduplication settings in the job options' do
      subject

      job = described_class.jobs.last
      expect(job['deduplicate']).to eq({ 'strategy' => 'until_executed',
                                         'options' => { 'if_deduplicated' => 'reschedule_once', 'ttl' => '60' } })
    end

    context 'when FF `ci_pipeline_process_worker_dedup_until_executed` is disabled' do
      before do
        stub_feature_flags(ci_pipeline_process_worker_dedup_until_executed: false)
      end

      it 'does not set the deduplication settings in the job options' do
        subject

        job = described_class.jobs.last
        expect(job['deduplicate']).to be_nil
      end
    end
  end

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
