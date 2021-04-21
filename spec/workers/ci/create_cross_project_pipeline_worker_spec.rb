# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreateCrossProjectPipelineWorker do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) { create(:ci_bridge, user: user, pipeline: pipeline) }

  let(:service) { double('pipeline creation service') }

  describe '#perform' do
    context 'when bridge exists' do
      it 'calls cross project pipeline creation service' do
        expect(Ci::CreateDownstreamPipelineService)
          .to receive(:new)
          .with(project, user)
          .and_return(service)

        expect(service).to receive(:execute).with(bridge)

        described_class.new.perform(bridge.id)
      end
    end

    context 'when bridge does not exist' do
      it 'does nothing' do
        expect(Ci::CreateDownstreamPipelineService)
          .not_to receive(:new)

        described_class.new.perform(non_existing_record_id)
      end
    end
  end
end
