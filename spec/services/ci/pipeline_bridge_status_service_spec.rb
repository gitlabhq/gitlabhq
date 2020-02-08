# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineBridgeStatusService do
  let(:user) { build(:user) }
  let(:project) { build(:project) }
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
    end
  end
end
