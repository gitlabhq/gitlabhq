# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CancelPipelineWorker, :aggregate_failures, feature_category: :continuous_integration do
  let!(:pipeline) { create(:ci_pipeline, :running) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline.id, pipeline.id) }

    let(:cancel_service) { instance_double(::Ci::CancelPipelineService) }

    it 'cancels the pipeline' do
      allow(::Ci::Pipeline).to receive(:find_by_id).twice.and_return(pipeline)
      expect(::Ci::CancelPipelineService)
        .to receive(:new)
        .with(
          pipeline: pipeline,
          current_user: nil,
          auto_canceled_by_pipeline: pipeline,
          cascade_to_children: false)
        .and_return(cancel_service)

      expect(cancel_service).to receive(:force_execute)

      perform
    end

    context 'if pipeline is deleted' do
      subject(:perform) { described_class.new.perform(non_existing_record_id, pipeline.id) }

      it 'does not error' do
        expect(::Ci::CancelPipelineService).not_to receive(:new)

        perform
      end
    end

    context 'when auto_canceled_by_pipeline is deleted' do
      subject(:perform) { described_class.new.perform(pipeline.id, non_existing_record_id) }

      it 'does not error' do
        expect(::Ci::CancelPipelineService)
          .to receive(:new)
          .with(
            pipeline: an_instance_of(::Ci::Pipeline),
            current_user: nil,
            auto_canceled_by_pipeline: nil,
            cascade_to_children: false)
          .and_call_original

        perform
      end
    end

    describe 'with builds and state transition side effects', :sidekiq_inline do
      let!(:job) { create(:ci_build, :running, pipeline: pipeline) }

      include_context 'when canceling support'

      it_behaves_like 'an idempotent worker', :sidekiq_inline do
        let(:job_args) { [pipeline.id, pipeline.id] }

        it 'cancels the pipeline' do
          perform

          pipeline.reload

          expect(pipeline).to be_canceling
          expect(pipeline.builds.first).to be_canceling
          expect(pipeline.builds.first.auto_canceled_by_id).to eq pipeline.id
          expect(pipeline.auto_canceled_by_id).to eq pipeline.id
        end
      end
    end
  end
end
