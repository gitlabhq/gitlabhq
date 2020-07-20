# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildCoverageWorker do
  describe '#perform' do
    context 'when build exists' do
      let!(:build) { create(:ci_build) }

      it 'updates code coverage' do
        expect_any_instance_of(Ci::Build)
          .to receive(:update_coverage)

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
