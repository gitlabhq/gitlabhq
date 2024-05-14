# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateBuildNamesWorker, feature_category: :continuous_integration do
  describe '#perform' do
    subject(:worker) { described_class.new }

    context 'when pipeline exists' do
      let_it_be(:pipeline) { create(:ci_pipeline) }
      let_it_be(:pipeline_id) { pipeline.id }

      it 'calls the service' do
        service = instance_double(Ci::UpdateBuildNamesService)

        expect(Ci::UpdateBuildNamesService)
          .to receive(:new)
          .with(pipeline)
          .and_return(service)

        expect(service).to receive(:execute)

        worker.perform(pipeline_id)
      end
    end

    context 'when pipeline does not exist' do
      let_it_be(:pipeline_id) { non_existing_record_id }

      it 'does not call the service' do
        expect(Ci::UpdateBuildNamesService)
          .not_to receive(:new)

        worker.perform(pipeline_id)
      end
    end
  end
end
