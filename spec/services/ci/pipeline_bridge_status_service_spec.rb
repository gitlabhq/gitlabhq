# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineBridgeStatusService do
  let(:user) { build(:user) }
  let_it_be(:project) { create(:project) }

  let(:pipeline) { build(:ci_pipeline, project: project) }

  describe '#execute' do
    subject { described_class.new(project, user).execute(pipeline) }

    context 'when pipeline has upstream bridge' do
      let(:bridge) { build(:ci_bridge) }

      before do
        pipeline.source_bridge = bridge
      end

      it 'calls inherit_status_from_downstream on upstream bridge' do
        expect(bridge).to receive(:inherit_status_from_downstream!).with(pipeline)

        subject
      end

      context 'when bridge job status raises state machine errors' do
        before do
          pipeline.drop!
          bridge.drop!
        end

        it 'tracks the exception' do
          expect(Gitlab::ErrorTracking)
            .to receive(:track_exception)
            .with(
              instance_of(Ci::Bridge::InvalidTransitionError),
              bridge_id: bridge.id,
              downstream_pipeline_id: pipeline.id)

          subject
        end
      end
    end
  end
end
