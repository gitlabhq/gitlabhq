# frozen_string_literal: true

require 'spec_helper'

describe BuildProcessWorker do
  describe '#perform' do
    context 'when build exists' do
      let(:pipeline) { create(:ci_pipeline) }
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it 'processes build' do
        expect_any_instance_of(Ci::Pipeline).to receive(:process!)
          .with(build.name)

        described_class.new.perform(build.id)
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
