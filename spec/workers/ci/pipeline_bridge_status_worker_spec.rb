# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineBridgeStatusWorker, feature_category: :continuous_integration do
  describe '#perform' do
    subject { described_class.new.perform(pipeline_id) }

    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline) }
      let(:pipeline_id) { pipeline.id }

      it 'calls the service' do
        service = double('bridge status service')

        expect(Ci::PipelineBridgeStatusService)
          .to receive(:new)
          .with(pipeline.project, pipeline.user)
          .and_return(service)

        expect(service).to receive(:execute).with(pipeline)

        subject
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not call the service' do
        expect(Ci::PipelineBridgeStatusService)
          .not_to receive(:new)

        subject
      end
    end
  end
end
